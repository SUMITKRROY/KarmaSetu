import 'package:karmasetu/core/storage/table/attendance_table.dart';
import 'package:karmasetu/core/storage/table/leave_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'table/profile_table.dart';

class DatabaseHelper {
  // database name
  static const _databaseName = "karmaSetuDB.db";
  // database version
  static const _databaseVersion = 2;

  // Singleton pattern
  static final DatabaseHelper _databaseHelper = DatabaseHelper._internal();
  factory DatabaseHelper() => _databaseHelper;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database.
    final path = join(databasePath, _databaseName);

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(
      path,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      version: _databaseVersion,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  // When the database is first created, create profile, attendance and leave table.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(ProfileTable.create);
    await db.execute(AttendanceTable.create);
    await db.execute(LeaveTable.create);
  }

  // UPGRADE DATABASE TABLES
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(LeaveTable.create);
    }
  }

  Future<void> deleteAllTableData() async {
    final db = await database;

    await db.execute('PRAGMA foreign_keys = OFF');

    final tables = [
      ProfileTable.tableName,
      AttendanceTable.tableName,
      LeaveTable.tableName,
    ];

    for (final table in tables) {
      await db.delete(table);
    }

    await db.execute('PRAGMA foreign_keys = ON');
  }
}