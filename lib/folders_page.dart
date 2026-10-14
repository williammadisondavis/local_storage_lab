import 'package:flutter/material.dart';

import 'cards_page.dart';
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
    } catch (error, stackTrace) {
      debugPrint('Load folders failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = 'Could not load folders. Tap Refresh to try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addFolder() async {
    if (_busy) return;

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddFolderDialog(),
    );

    if (!mounted || name == null) return;

    if (name.isEmpty) {
      _showMessage('Folder name cannot be blank.');
      return;
    }

    setState(() => _busy = true);

    try {
      final folder = Folder(
        name: name,
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await widget.helper.insertFolder(folder);

      if (!mounted) return;

      _showMessage('Created folder "$name" with ID $id.');
      await _loadFolders();
    } catch (error, stackTrace) {
      debugPrint('Insert folder failed: $error\n$stackTrace');

      if (!mounted) return;

      _showMessage('Could not create folder. The name may already exist.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    if (_busy || folder.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Delete "${folder.name}" (ID ${folder.id})?\n\n'
          'This also deletes its ${folder.cardCount} cards.',
        ),
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

    setState(() => _busy = true);

    try {
      final affected = await widget.helper.deleteFolder(folder.id!);

      if (!mounted) return;

      _showMessage(
        affected == 1
            ? 'Deleted "${folder.name}". Affected parent rows: 1.'
            : 'Folder not found. Affected rows: $affected.',
      );

      await _loadFolders();
    } catch (error, stackTrace) {
      debugPrint('Delete folder failed: $error\n$stackTrace');

      if (!mounted) return;
      _showMessage('Could not delete the folder.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openFolder(Folder folder) async {
    if (_busy || folder.id == null) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CardsPage(helper: widget.helper, folder: folder),
      ),
    );

    if (!mounted) return;
    await _loadFolders();
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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder, size: 36),
                    title: Text(folder.name),
                    subtitle: Text(
                      'ID: ${folder.id} | Cards: ${folder.cardCount}',
                    ),
                    onTap: _busy ? null : () => _openFolder(folder),
                    trailing: IconButton(
                      tooltip: 'Delete ${folder.name}',
                      onPressed: _busy ? null : () => _deleteFolder(folder),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AddFolderDialog extends StatefulWidget {
  const _AddFolderDialog();

  @override
  State<_AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<_AddFolderDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Folder'),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim());
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
