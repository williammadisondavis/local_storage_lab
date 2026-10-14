class Folder {
  final int? id;
  final String name;
  final String createdAt;
  final int cardCount;

  Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.cardCount = 0,
  });

  // Convert a database row into a Folder object.
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
      cardCount: (map['card_count'] as int?) ?? 0,
    );
  }

  // Convert a Folder object into a database row.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name, 'created_at': createdAt};

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
