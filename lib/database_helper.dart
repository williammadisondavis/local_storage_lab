
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String table = 'my_table';
  static const String columnId = '_id';
  static const String columnName = 'name';
  static const String columnAge = 'age';

  late Database _db;

  // Opens the database when the app starts.
  Future<void> init() async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final databasePath =
        join(documentsDirectory.path, 'MyDatabase.db');

    _db = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnAge INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Adds a guest and returns their generated ID.
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // Gets all guests, sorted by their IDs.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(
      table,
      orderBy: '$columnId ASC',
    );
  }

  // Returns the number of guests in the database.
  Future<int> queryRowCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) FROM $table',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Updates a guest using their unique ID.
  Future<int> update(Map<String, dynamic> row) async {
    final id = row[columnId] as int;

    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes a guest using their unique ID.
  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
