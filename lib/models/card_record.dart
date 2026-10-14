class CardRecord {
  final int? id;
  final String title;
  final String suit;
  final String notes;
  final String? imageRef;
  final int folderId;

  CardRecord({
    this.id,
    required this.title,
    required this.suit,
    this.notes = '',
    this.imageRef,
    required this.folderId,
  });

  // Convert a database row into a CardRecord object.
  factory CardRecord.fromMap(Map<String, dynamic> map) {
    return CardRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      suit: map['suit'] as String,
      notes: map['notes'] as String,
      imageRef: map['image_ref'] as String?,
      folderId: map['folder_id'] as int,
    );
  }

  // Convert a CardRecord object into a database row.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'suit': suit,
      'notes': notes,
      'image_ref': imageRef,
      'folder_id': folderId,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
