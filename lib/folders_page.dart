import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models/folder.dart';

class FoldersPage extends StatefulWidget {
  final DatabaseHelper helper;

  const FoldersPage({super.key, required this.helper});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  List<Folder> _folders = [];

  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // Reloads folders and their card counts from SQLite.
  Future<void> _loadFolders() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final folders = await widget.helper.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        _folders = folders;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load folders: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Displays messages at the bottom of the screen.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Opens the dialog used to create a folder.
  Future<void> _addFolder() async {
    if (_busy) return;

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              hintText: 'Example: Atlas',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || name == null) return;

    if (name.isEmpty) {
      _showMessage('Folder name cannot be blank.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final folder = Folder(
        name: name,
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await widget.helper.insertFolder(folder);

      if (!mounted) return;

      _showMessage('Created folder "$name" with ID $id.');

      await _loadFolders();
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not create folder. The name may already exist.');

      debugPrint('Insert folder error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // Confirms deletion before changing SQLite.
  Future<void> _deleteFolder(Folder folder) async {
    if (_busy || folder.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder?'),
          content: Text(
            'Delete "${folder.name}" (ID ${folder.id})?\n\n'
            'This will also delete its ${folder.cardCount} cards.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _busy = true;
    });

    try {
      final affected = await widget.helper.deleteFolder(folder.id!);

      if (!mounted) return;

      if (affected == 1) {
        _showMessage('Deleted "${folder.name}".');
      } else {
        _showMessage('Folder was not found. Rows deleted: $affected.');
      }

      await _loadFolders();
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not delete folder.');
      debugPrint('Delete folder error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // Card navigation will be added in the next step.
  void _openFolder(Folder folder) {
    _showMessage(
      'Opened "${folder.name}" (ID ${folder.id}). '
      'Card screen coming next.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Catalogue'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : _loadFolders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addFolder,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('Add Folder'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _folders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 70),
                  SizedBox(height: 12),
                  Text('No folders yet.'),
                  Text('Tap Add Folder to create one.'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: 90,
              ),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder, size: 36),
                    title: Text(folder.name),
                    subtitle: Text(
                      'ID: ${folder.id} | '
                      'Cards: ${folder.cardCount}',
                    ),
                    onTap: _busy ? null : () => _openFolder(folder),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete ${folder.name}',
                      onPressed: _busy ? null : () => _deleteFolder(folder),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
