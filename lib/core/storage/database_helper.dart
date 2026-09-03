import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:karmasetu/core/storage/table/attendance_table.dart';
import 'package:karmasetu/core/storage/table/leave_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'table/profile_table.dart';

class DatabaseHelper {
  // Single database name for the entire application
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

  /// Explicit initializer that ensures the single DB is ready and other DBs are removed.
  Future<Database> init() async {
    return await database;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Clean up and delete any other local databases to prevent conflicts
    await deleteOtherDatabases();

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

  /// Deletes all other local databases found in the databases directory
  /// to ensure only [karmaSetuDB.db] is used across the whole application.
  Future<void> deleteOtherDatabases() async {
    try {
      final databasePath = await getDatabasesPath();
      final dir = Directory(databasePath);
      if (await dir.exists()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          final fileName = basename(entry.path);
          // Keep only karmaSetuDB.db and its SQLite auxiliary files (wal, shm, journal)
          if (fileName == _databaseName ||
              fileName == '$_databaseName-wal' ||
              fileName == '$_databaseName-shm' ||
              fileName == '$_databaseName-journal') {
            continue;
          }

          // If it is not karmaSetuDB.db, delete it unconditionally to prevent any conflict
          try {
            await deleteDatabase(entry.path);
            debugPrint('[DatabaseHelper] Deleted conflicting database: ${entry.path}');
          } catch (_) {}

          try {
            if (entry is File) {
              await entry.delete();
              debugPrint('[DatabaseHelper] Deleted file: ${entry.path}');
            } else if (entry is Directory) {
              await entry.delete(recursive: true);
              debugPrint('[DatabaseHelper] Deleted directory: ${entry.path}');
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error checking for conflicting databases: $e');
    }
  }

  // When the database is first created, create profile, attendance and leave table.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(ProfileTable.create);
    await db.execute(AttendanceTable.create);
    await db.execute(LeaveTable.create);
  }

  // UPGRADE DATABASE TABLES
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ensure all required tables exist across versions
    await db.execute(ProfileTable.create);
    await db.execute(AttendanceTable.create);
    await db.execute(LeaveTable.create);
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