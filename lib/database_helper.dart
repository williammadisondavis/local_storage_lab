import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models/folder.dart';
import 'models/card_record.dart';

class DatabaseHelper {
  // Original Activity 08 guest table.
  static const String table = 'my_table';
  static const String columnId = '_id';
  static const String columnName = 'name';
  static const String columnAge = 'age';

  // New Activity 09 tables.
  static const String foldersTable = 'folders';
  static const String cardsTable = 'cards';

  late Database _db;

  // Opens the same database from Activity 08.
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = join(documentsDirectory.path, 'MyDatabase.db');

    _db = await openDatabase(
      databasePath,
      version: 2,

      // Enables foreign keys for folder/card relationships.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // Runs when the app has no existing database.
      onCreate: (db, version) async {
        await _createGuestTable(db);
        await _createCatalogueTables(db);
      },

      // Upgrades the original Activity 08 database.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCatalogueTables(db);
        }
      },
    );
  }

  // Creates the original Activity 08 table.
  Future<void> _createGuestTable(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  // Creates the new Activity 09 tables and index.
  Future<void> _createCatalogueTables(Database db) async {
    await db.execute('''
      CREATE TABLE $foldersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES $foldersTable(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cards_folder_id
      ON $cardsTable(folder_id)
    ''');
  }

  // ACTIVITY 08: GUEST DATABASE METHODS

  // Adds a guest and returns their generated ID.
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // Gets all guests sorted by ID.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table, orderBy: '$columnId ASC');
  }

  // Returns the number of saved guests.
  Future<int> queryRowCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Updates a guest using their ID.
  Future<int> update(Map<String, dynamic> row) async {
    final id = row[columnId] as int;

    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes a guest using their ID.
  Future<int> delete(int id) async {
    return await _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // ACTIVITY 09: DATABASE DIAGNOSTICS

  // Read-only checks for migration testing.
  Future<Map<String, dynamic>> getDatabaseDiagnostics() async {
    final version = await _db.rawQuery('PRAGMA user_version');
    final foreignKeys = await _db.rawQuery('PRAGMA foreign_keys');

    final tableRows = await _db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' ORDER BY name",
    );

    final cardForeignKeys = await _db.rawQuery(
      'PRAGMA foreign_key_list(cards)',
    );

    final cardIndexes = await _db.rawQuery('PRAGMA index_list(cards)');

    return {
      'version': version,
      'foreignKeys': foreignKeys,
      'tables': tableRows,
      'cardForeignKeys': cardForeignKeys,
      'cardIndexes': cardIndexes,
      'guests': await queryAllRows(),
    };
  }

  // ACTIVITY 09: FOLDER DATABASE METHODS

  // Creates a folder and returns its generated ID.
  Future<int> insertFolder(Folder folder) async {
    return await _db.insert(foldersTable, folder.toMap());
  }

  // Gets all folders and the number of cards in each.
  Future<List<Folder>> getFoldersWithCounts() async {
    final rows = await _db.rawQuery('''
      SELECT folders.id, folders.name, folders.created_at,
             COUNT(cards.id) AS card_count
      FROM $foldersTable AS folders
      LEFT JOIN $cardsTable AS cards
        ON cards.folder_id = folders.id
      GROUP BY folders.id, folders.name, folders.created_at
      ORDER BY folders.name COLLATE NOCASE ASC
    ''');

    return rows.map((row) => Folder.fromMap(row)).toList();
  }

  // Deletes a folder using its ID.
  // Related cards are deleted automatically by CASCADE.
  Future<int> deleteFolder(int id) async {
    return await _db.delete(foldersTable, where: 'id = ?', whereArgs: [id]);
  }

  // ACTIVITY 09: CARD DATABASE METHODS

  // Gets cards belonging to one folder.
  Future<List<CardRecord>> getCards(int folderId) async {
    final rows = await _db.query(
      cardsTable,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC, id ASC',
    );

    return rows.map((row) => CardRecord.fromMap(row)).toList();
  }

  // Creates a new card and returns its generated ID.
  Future<int> insertCard(CardRecord card) async {
    return await _db.insert(cardsTable, card.toMap());
  }

  // Updates a card using its unique ID.
  Future<int> updateCard(CardRecord card) async {
    if (card.id == null) {
      throw ArgumentError('Cannot update a card without an ID.');
    }

    return await _db.update(
      cardsTable,
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // Deletes a card using its unique ID.
  Future<int> deleteCard(int id) async {
    return await _db.delete(cardsTable, where: 'id = ?', whereArgs: [id]);
  }
}
