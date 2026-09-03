import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class LeaveTable {
  static const String tableName = "Leaves";

  // Identification & User
  static const String leaveId = "leaveId";
  static const String uid = "uid";
  static const String employeeId = "employeeId";
  static const String employeeName = "employeeName";

  // Leave Details
  static const String leaveType = "leaveType";
  static const String fromDate = "fromDate"; // YYYY-MM-DD
  static const String toDate = "toDate"; // YYYY-MM-DD
  static const String durationInDays = "durationInDays";
  static const String reason = "reason";
  static const String documentUrl = "documentUrl";

  // Status & Approval
  static const String status = "status"; // 'Pending', 'Approved', 'Rejected'
  static const String approverRemarks = "approverRemarks";

  // Local sync information
  static const String isSynced = "isSynced";
  static const String syncError = "syncError";
  static const String createdAt = "createdAt";
  static const String updatedAt = "updatedAt";

  static const String create = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $leaveId TEXT NOT NULL,
      $uid TEXT NOT NULL,
      $employeeId TEXT DEFAULT '',
      $employeeName TEXT DEFAULT '',
      $leaveType TEXT NOT NULL,
      $fromDate TEXT NOT NULL,
      $toDate TEXT NOT NULL,
      $durationInDays INTEGER DEFAULT 1,
      $reason TEXT NOT NULL,
      $documentUrl TEXT DEFAULT '',
      $status TEXT DEFAULT 'Pending',
      $approverRemarks TEXT DEFAULT '',
      $isSynced INTEGER DEFAULT 0,
      $syncError TEXT DEFAULT '',
      $createdAt TEXT DEFAULT '',
      $updatedAt TEXT DEFAULT '',
      PRIMARY KEY ($leaveId)
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

  Future<Map<String, dynamic>?> getById(String targetLeaveId) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      tableName,
      where: '$leaveId = ?',
      whereArgs: [targetLeaveId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
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
      orderBy: '$createdAt ${ascending ? "ASC" : "DESC"}',
    );
  }

  Future<List<Map<String, dynamic>>> getAll({bool ascending = false}) async {
    final db = await DatabaseHelper().database;
    return await db.query(
      tableName,
      orderBy: '$createdAt ${ascending ? "ASC" : "DESC"}',
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

  Future<int> markSynced(String targetLeaveId) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      tableName,
      {
        isSynced: 1,
        syncError: '',
      },
      where: '$leaveId = ?',
      whereArgs: [targetLeaveId],
    );
  }

  Future<int> updateStatus(
    String targetLeaveId,
    String newStatus, {
    String? remarks,
  }) async {
    final db = await DatabaseHelper().database;
    final updateData = <String, dynamic>{
      status: newStatus,
      updatedAt: DateTime.now().toIso8601String(),
    };
    if (remarks != null) {
      updateData[approverRemarks] = remarks;
    }
    return await db.update(
      tableName,
      updateData,
      where: '$leaveId = ?',
      whereArgs: [targetLeaveId],
    );
  }

  Future<int> delete(String targetLeaveId) async {
    final db = await DatabaseHelper().database;
    return await db.delete(
      tableName,
      where: '$leaveId = ?',
      whereArgs: [targetLeaveId],
    );
  }
}
