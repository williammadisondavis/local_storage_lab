import 'package:flutter/material.dart';

import 'database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();

    final diagnostics = await helper.getDatabaseDiagnostics();
    debugPrint('ACTIVITY 09 DATABASE CHECK: $diagnostics');

    runApp(FestivalApp(helper: helper));
  } catch (error, stackTrace) {
    debugPrint('Database initialization error: $error\n$stackTrace');

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Could not open local storage. Restart the app '
                'and check the logs.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FestivalApp extends StatelessWidget {
  final DatabaseHelper helper;

  const FestivalApp({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Festival Roster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: RosterPage(helper: helper),
    );
  }
}

class RosterPage extends StatefulWidget {
  final DatabaseHelper helper;

  const RosterPage({super.key, required this.helper});

  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  List<Map<String, dynamic>> _guests = [];
  int _guestCount = 0;
  int? _editingId;

  bool _busy = false;
  bool _loading = true;
  String? _readError;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _refreshGuests();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // Reads the actual saved rows from SQLite.
  Future<bool> _loadGuests() async {
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return false;

      setState(() {
        _guests = rows;
        _guestCount = count;
        _readError = null;
      });

      return true;
    } catch (error, stackTrace) {
      debugPrint('Database read error: $error\n$stackTrace');

      if (!mounted) return false;

      setState(() {
        _readError = 'Could not load guests. Tap Refresh to try again.';
      });

      return false;
    }
  }

  // Refresh is also used after every database change.
  Future<void> _refreshGuests() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _loading = true;
    });

    await _loadGuests();

    if (!mounted) return;

    setState(() {
      _busy = false;
      _loading = false;
    });
  }

  // Checks the name field before allowing a save.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a guest name.';
    }
    return null;
  }

  // Only whole-number ages between 0 and 130 are allowed.
  String? _validateAge(String? value) {
    final age = int.tryParse(value?.trim() ?? '');

    if (age == null) {
      return 'Enter a whole-number age.';
    }

    if (age < 0 || age > 130) {
      return 'Age must be between 0 and 130.';
    }

    return null;
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _formKey.currentState?.reset();

    setState(() {
      _editingId = null;
    });
  }

  void _startEditing(Map<String, dynamic> guest) {
    if (_busy) return;

    _nameController.text = guest[DatabaseHelper.columnName] as String;
    _ageController.text = guest[DatabaseHelper.columnAge].toString();

    setState(() {
      _editingId = guest[DatabaseHelper.columnId] as int;
      _feedback = null;
    });

    _formKey.currentState?.reset();
  }

  // Inserts a guest or updates the selected guest by ID.
  Future<void> _saveGuest() async {
    if (_busy) return;

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _feedback = 'Invalid input. No guest was saved.';
      });
      return;
    }

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final selectedId = _editingId;

    setState(() {
      _busy = true;
      _feedback = null;
    });

    bool writeSucceeded = false;
    String? message;

    try {
      if (selectedId == null) {
        final insertedId = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        writeSucceeded = true;
        message = 'Guest saved with ID $insertedId.';
      } else {
        final affectedRows = await widget.helper.update({
          DatabaseHelper.columnId: selectedId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (affectedRows == 1) {
          writeSucceeded = true;
          message =
              'Guest ID $selectedId updated. '
              'Affected rows: $affectedRows.';
        } else {
          message =
              'Guest ID $selectedId was not found. '
              'Affected rows: $affectedRows.';
        }
      }

      if (!mounted) return;

      // Clear only after a successful database write.
      if (writeSucceeded) {
        _clearForm();
      }

      final refreshed = await _loadGuests();

      if (!mounted) return;

      setState(() {
        _feedback = refreshed
            ? message
            : writeSucceeded
            ? 'Saved, but refresh failed. Tap Refresh.'
            : '$message Refresh failed. Try Refresh again.';
      });
    } catch (error, stackTrace) {
      debugPrint('Database write error: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _feedback =
            'Could not save the guest. '
            'Check the logs and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _loading = false;
        });
      }
    }
  }

  // Asks before deleting so Cancel never changes the database.
  Future<void> _confirmDelete(Map<String, dynamic> guest) async {
    if (_busy) return;

    final id = guest[DatabaseHelper.columnId] as int;
    final name = guest[DatabaseHelper.columnName] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Guest?'),
        content: Text('Delete guest $name (ID $id)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true || _busy) return;

    setState(() {
      _busy = true;
      _feedback = null;
    });

    bool deleted = false;

    try {
      final affectedRows = await widget.helper.delete(id);
      deleted = affectedRows == 1;

      if (!mounted) return;

      if (deleted && _editingId == id) {
        _clearForm();
      }

      final refreshed = await _loadGuests();

      if (!mounted) return;

      setState(() {
        if (!refreshed && deleted) {
          _feedback = 'Deleted, but refresh failed. Tap Refresh.';
        } else if (!refreshed) {
          _feedback =
              'Delete affected $affectedRows rows, '
              'but refresh failed.';
        } else if (deleted) {
          _feedback = 'Guest ID $id deleted. Affected rows: 1.';
        } else {
          _feedback =
              'Guest ID $id was not found. '
              'Affected rows: $affectedRows.';
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Database delete error: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _feedback =
            'Could not delete guest ID $id. '
            'Check the logs and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editingId == null
                  ? 'Register a Guest'
                  : 'Editing Guest ID $_editingId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Guest Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateAge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _busy ? null : _saveGuest,
              child: Text(_editingId == null ? 'Add Guest' : 'Save Changes'),
            ),

            if (_editingId != null)
              OutlinedButton(
                onPressed: _busy ? null : _clearForm,
                child: const Text('Cancel Edit'),
              ),

            const Divider(height: 32),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Guest Count: $_guestCount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _refreshGuests,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),

            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Text(_feedback!),
            ],

            const SizedBox(height: 12),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_readError != null)
              Text(_readError!, style: const TextStyle(color: Colors.red))
            else if (_guests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No festival guests yet.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _guests.length,
                itemBuilder: (context, index) {
                  final guest = _guests[index];
                  final id = guest[DatabaseHelper.columnId] as int;
                  final name = guest[DatabaseHelper.columnName] as String;
                  final age = guest[DatabaseHelper.columnAge] as int;

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('ID: $id | Age: $age'),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            tooltip: 'Edit guest $id',
                            icon: const Icon(Icons.edit),
                            onPressed: _busy
                                ? null
                                : () => _startEditing(guest),
                          ),
                          IconButton(
                            tooltip: 'Delete guest $id',
                            icon: const Icon(Icons.delete),
                            onPressed: _busy
                                ? null
                                : () => _confirmDelete(guest),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
