import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class ProfileTable {
  static const String tableName = "Profile";

  // Profile fields
  static const String uid = "uid";
  static const String employeeId = "employeeId";
  static const String name = "name";
  static const String email = "email";
  static const String role = "role";
  static const String department = "department";
  static const String site = "site";

  // Create table
  static const String create = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $uid TEXT NOT NULL,
      $employeeId TEXT DEFAULT '',
      $name TEXT DEFAULT '',
      $email TEXT DEFAULT '',
      $role TEXT DEFAULT '',
      $department TEXT DEFAULT '',
      $site TEXT DEFAULT '',
      PRIMARY KEY ($uid)
    )
  ''';

  // Insert profile
  Future<void> insert(Map<String, dynamic> map) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all profiles
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseHelper().database;

    return await db.query(tableName);
  }

  // Get profile by UID
  Future<Map<String, dynamic>?> getByUid(String userUid) async {
    final db = await DatabaseHelper().database;

    final result = await db.query(
      tableName,
      where: '$uid = ?',
      whereArgs: [userUid],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  // Update profile
  Future<int> update(
    String userUid,
    Map<String, dynamic> map,
  ) async {
    final db = await DatabaseHelper().database;

    return await db.update(
      tableName,
      map,
      where: '$uid = ?',
      whereArgs: [userUid],
    );
  }

  // Delete profile
  Future<int> delete(String userUid) async {
    final db = await DatabaseHelper().database;

    return await db.delete(
      tableName,
      where: '$uid = ?',
      whereArgs: [userUid],
    );
  }

  // Delete all profiles
  Future<int> deleteAll() async {
    final db = await DatabaseHelper().database;

    return await db.delete(tableName);
  }
}