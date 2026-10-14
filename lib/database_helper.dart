import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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

  // Opens the same database used in Activity 08.
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final databasePath = join(documentsDirectory.path, 'MyDatabase.db');

    _db = await openDatabase(
      databasePath,
      version: 2,

      // Enable foreign keys for folder/card relationships.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // For a completely new installation.
      onCreate: (db, version) async {
        await _createGuestTable(db);
        await _createCatalogueTables(db);
      },

      // For users upgrading from Activity 08.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCatalogueTables(db);
        }
      },
    );
  }

  // Original Activity 08 table structure.
  Future<void> _createGuestTable(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  // New Activity 09 folder/card tables.
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

  // Original Activity 08 methods remain unchanged.

  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table, orderBy: '$columnId ASC');
  }

  Future<int> queryRowCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final id = row[columnId] as int;

    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Read-only checks for Activity 09 migration testing.
  Future<Map<String, dynamic>> getDatabaseDiagnostics() async {
    final version = await _db.rawQuery('PRAGMA user_version');
    final foreignKeys = await _db.rawQuery('PRAGMA foreign_keys');
    final tableRows = await _db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
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
}
