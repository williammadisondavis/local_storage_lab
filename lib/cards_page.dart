import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models/card_record.dart';
import 'models/folder.dart';

class CardsPage extends StatefulWidget {
  final DatabaseHelper helper;
  final Folder folder;

  const CardsPage({super.key, required this.helper, required this.folder});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<CardRecord> _cards = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cards = await widget.helper.getCards(widget.folder.id!);

      if (!mounted) return;

      setState(() {
        _cards = cards;
      });
    } catch (error, stackTrace) {
      debugPrint('Load cards failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = 'Could not load cards. Tap Refresh to try again.';
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

  String _suitSymbol(String suit) {
    switch (suit) {
      case 'Hearts':
        return '♥';
      case 'Diamonds':
        return '♦';
      case 'Clubs':
        return '♣';
      case 'Spades':
        return '♠';
      default:
        return '?';
    }
  }

  // Shows an image when valid, otherwise uses a suit symbol.
  Widget _cardImage(CardRecord card) {
    final reference = card.imageRef?.trim();

    Widget placeholder() {
      return Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _suitSymbol(card.suit),
          style: TextStyle(
            fontSize: 30,
            color: card.suit == 'Hearts' || card.suit == 'Diamonds'
                ? Colors.red
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    if (reference == null || reference.isEmpty) {
      return placeholder();
    }

    final uri = Uri.tryParse(reference);

    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return SizedBox(
        width: 54,
        height: 54,
        child: Image.network(
          reference,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder();
          },
        ),
      );
    }

    if (reference.startsWith('assets/')) {
      return SizedBox(
        width: 54,
        height: 54,
        child: Image.asset(
          reference,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        ),
      );
    }

    return placeholder();
  }

  Future<void> _openCardForm({CardRecord? existing}) async {
    if (_busy) return;

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CardFormDialog(
        helper: widget.helper,
        originalFolderId: widget.folder.id!,
        existing: existing,
      ),
    );

    if (!mounted || changed != true) return;

    await _loadCards();

    if (!mounted) return;
    _showMessage('Card list refreshed.');
  }

  Future<void> _deleteCard(CardRecord card) async {
    if (_busy || card.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Card?'),
        content: Text('Delete "${card.title}" (ID ${card.id})?'),
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
      final affected = await widget.helper.deleteCard(card.id!);

      if (!mounted) return;

      _showMessage(
        affected == 1
            ? 'Deleted card ID ${card.id}. Affected rows: 1.'
            : 'Card not found. Affected rows: $affected.',
      );

      await _loadCards();
    } catch (error, stackTrace) {
      debugPrint('Delete card failed: $error\n$stackTrace');

      if (!mounted) return;
      _showMessage('Could not delete the card.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : _loadCards,
            tooltip: 'Refresh cards',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openCardForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _cards.isEmpty
          ? const Center(child: Text('No cards yet. Tap Add Card to begin.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];

                return Card(
                  child: ListTile(
                    leading: _cardImage(card),
                    title: Text(card.title),
                    subtitle: Text(
                      'ID: ${card.id} | ${card.suit}'
                      '${card.notes.isEmpty ? '' : '\n${card.notes}'}',
                    ),
                    isThreeLine: card.notes.isNotEmpty,
                    onTap: _busy ? null : () => _openCardForm(existing: card),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: 'Edit ${card.title}',
                          onPressed: _busy
                              ? null
                              : () => _openCardForm(existing: card),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete ${card.title}',
                          onPressed: _busy ? null : () => _deleteCard(card),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CardFormDialog extends StatefulWidget {
  final DatabaseHelper helper;
  final int originalFolderId;
  final CardRecord? existing;

  const CardFormDialog({
    super.key,
    required this.helper,
    required this.originalFolderId,
    this.existing,
  });

  @override
  State<CardFormDialog> createState() => _CardFormDialogState();
}

class _CardFormDialogState extends State<CardFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _imageController;

  List<Folder> _folders = [];
  int? _selectedFolderId;
  String _selectedSuit = 'Hearts';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const List<String> suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

  @override
  void initState() {
    super.initState();

    final card = widget.existing;

    _titleController = TextEditingController(text: card?.title ?? '');
    _notesController = TextEditingController(text: card?.notes ?? '');
    _imageController = TextEditingController(text: card?.imageRef ?? '');

    _selectedSuit = card?.suit ?? 'Hearts';
    _selectedFolderId = card?.folderId ?? widget.originalFolderId;

    _loadFolders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await widget.helper.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        _folders = folders;
        _loading = false;

        if (!folders.any((folder) => folder.id == _selectedFolderId)) {
          _selectedFolderId = null;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Load folders for form failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the available folders.';
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _loading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFolderId == null) {
      setState(() => _error = 'Please select a valid folder.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final imageText = _imageController.text.trim();

    final card = CardRecord(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      suit: _selectedSuit,
      notes: _notesController.text.trim(),
      imageRef: imageText.isEmpty ? null : imageText,
      folderId: _selectedFolderId!,
    );

    try {
      if (widget.existing == null) {
        final id = await widget.helper.insertCard(card);
        debugPrint('Activity 09: inserted card ID $id');
      } else {
        final affected = await widget.helper.updateCard(card);
        debugPrint('Activity 09: updated card rows $affected');

        if (affected != 1) {
          throw StateError('Card was not found. Affected rows: $affected');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Save card failed: $error\n$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = 'Could not save the card: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Card' : 'Edit Card'),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Card Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a card title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSuit,
                        decoration: const InputDecoration(
                          labelText: 'Suit',
                          border: OutlineInputBorder(),
                        ),
                        items: suits
                            .map(
                              (suit) => DropdownMenuItem(
                                value: suit,
                                child: Text(suit),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _selectedSuit = value);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedFolderId,
                        decoration: const InputDecoration(
                          labelText: 'Folder',
                          border: OutlineInputBorder(),
                        ),
                        items: _folders
                            .map(
                              (folder) => DropdownMenuItem(
                                value: folder.id,
                                child: Text(folder.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() => _selectedFolderId = value);
                              },
                        validator: (value) =>
                            value == null ? 'Select a folder.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        enabled: !_saving,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageController,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Image reference (optional)',
                          hintText: 'https://... or assets/...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving || _loading ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
