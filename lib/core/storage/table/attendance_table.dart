import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';

class AttendanceTable {
  static const String tableName = "Attendance";

  // Identification
  static const String attendanceId = "attendanceId";
  static const String uid = "uid";
  static const String employeeId = "employeeId";
  static const String date = "date";

  // Check In
  static const String checkIn = "checkIn";
  static const String checkInLatitude = "checkInLatitude";
  static const String checkInLongitude = "checkInLongitude";
  static const String checkInLocation = "checkInLocation";
  static const String checkInSelfie = "checkInSelfie";

  // Check Out
  static const String checkOut = "checkOut";
  static const String checkOutLatitude = "checkOutLatitude";
  static const String checkOutLongitude = "checkOutLongitude";
  static const String checkOutLocation = "checkOutLocation";
  static const String checkOutSelfie = "checkOutSelfie";

  // Attendance status
  static const String status = "status";
  static const String workingMinutes = "workingMinutes";

  // Local sync information
  static const String isSynced = "isSynced";
  static const String syncError = "syncError";
  static const String createdAt = "createdAt";
  static const String updatedAt = "updatedAt";

  static const String create = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $attendanceId TEXT NOT NULL,
      $uid TEXT NOT NULL,
      $employeeId TEXT DEFAULT '',
      $date TEXT NOT NULL,

      $checkIn TEXT DEFAULT '',
      $checkInLatitude REAL,
      $checkInLongitude REAL,
      $checkInLocation TEXT DEFAULT '',
      $checkInSelfie TEXT DEFAULT '',

      $checkOut TEXT DEFAULT '',
      $checkOutLatitude REAL,
      $checkOutLongitude REAL,
      $checkOutLocation TEXT DEFAULT '',
      $checkOutSelfie TEXT DEFAULT '',

      $status TEXT DEFAULT 'checked_in',
      $workingMinutes INTEGER DEFAULT 0,

      $isSynced INTEGER DEFAULT 0,
      $syncError TEXT DEFAULT '',

      $createdAt TEXT DEFAULT '',
      $updatedAt TEXT DEFAULT '',

      PRIMARY KEY ($attendanceId)
    )
  ''';

  Future<void> insert(Map<String, dynamic> map) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getById(String targetAttendanceId) async {
    final db = await DatabaseHelper().database;

    final result = await db.query(
      tableName,
      where: '$attendanceId = ?',
      whereArgs: [targetAttendanceId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<Map<String, dynamic>?> getTodayAttendance(
    String userUid,
    String targetDate,
  ) async {
    final db = await DatabaseHelper().database;

    final result = await db.query(
      tableName,
      where: '$uid = ? AND $date = ?',
      whereArgs: [userUid, targetDate],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<int> update(
    String targetAttendanceId,
    Map<String, dynamic> map,
  ) async {
    final db = await DatabaseHelper().database;

    return await db.update(
      tableName,
      map,
      where: '$attendanceId = ?',
      whereArgs: [targetAttendanceId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsynced() async {
    final db = await DatabaseHelper().database;

    return await db.query(
      tableName,
      where: '$isSynced = ?',
      whereArgs: [0],
    );
  }

  Future<int> markSynced(String targetAttendanceId) async {
    final db = await DatabaseHelper().database;

    return await db.update(
      tableName,
      {
        isSynced: 1,
        syncError: '',
      },
      where: '$attendanceId = ?',
      whereArgs: [targetAttendanceId],
    );
  }

  Future<List<Map<String, dynamic>>> getAll({bool ascending = false}) async {
    final db = await DatabaseHelper().database;

    return await db.query(
      tableName,
      orderBy: '$date ${ascending ? "ASC" : "DESC"}',
    );
  }

  Future<List<Map<String, dynamic>>> getAllForUser(
    String userUid, {
    bool ascending = false,
  }) async {
    final db = await DatabaseHelper().database;

    return await db.query(
      tableName,
      where: '$uid = ?',
      whereArgs: [userUid],
      orderBy: '$date ${ascending ? "ASC" : "DESC"}',
    );
  }

  Future<bool> hasAttendance(String userUid, String targetDate) async {
    final db = await DatabaseHelper().database;

    final result = await db.rawQuery(
      'SELECT 1 FROM $tableName WHERE $uid = ? AND $date = ? LIMIT 1',
      [userUid, targetDate],
    );

    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAttendanceForMonth({
    required String userUid,
    required String startDate,
    required String endDate,
    bool ascending = false,
  }) async {
    final db = await DatabaseHelper().database;

    return await db.query(
      tableName,
      where: '$uid = ? AND $date >= ? AND $date <= ?',
      whereArgs: [
        userUid,
        startDate,
        endDate,
      ],
      orderBy: '$date ${ascending ? "ASC" : "DESC"}',
    );
  }

  Future<void> insertOrUpdate(Map<String, dynamic> map) async {
    final db = await DatabaseHelper().database;

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBatch(List<Map<String, dynamic>> records) async {
    final db = await DatabaseHelper().database;
    final batch = db.batch();

    for (final map in records) {
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}