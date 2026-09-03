import '../../../../core/storage/table/attendance_table.dart';
import '../models/attendance_model.dart';

abstract interface class AttendanceLocalDataSource {
  Future<List<AttendanceModel>> getAttendanceForMonth({
    required String uid,
    required String startDate,
    required String endDate,
    bool ascending = false,
  });

  Future<void> saveAttendance(AttendanceModel model);

  Future<void> saveAttendanceBatch(List<AttendanceModel> models);

  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  });

  Future<bool> hasAttendance({
    required String uid,
    required String date,
  });

  Future<List<AttendanceModel>> getUnsyncedRecords();

  Future<void> markSynced(String attendanceId);
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final AttendanceTable _attendanceTable;

  AttendanceLocalDataSourceImpl({AttendanceTable? attendanceTable})
      : _attendanceTable = attendanceTable ?? AttendanceTable();

  @override
  Future<List<AttendanceModel>> getAttendanceForMonth({
    required String uid,
    required String startDate,
    required String endDate,
    bool ascending = false,
  }) async {
    final maps = await _attendanceTable.getAttendanceForMonth(
      userUid: uid,
      startDate: startDate,
      endDate: endDate,
      ascending: ascending,
    );

    return maps.map((map) => AttendanceModel.fromSqfliteMap(map)).toList();
  }

  @override
  Future<void> saveAttendance(AttendanceModel model) async {
    await _attendanceTable.insertOrUpdate(model.toSqfliteMap());
  }

  @override
  Future<void> saveAttendanceBatch(List<AttendanceModel> models) async {
    final maps = models.map((m) => m.toSqfliteMap()).toList();
    await _attendanceTable.insertBatch(maps);
  }

  @override
  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  }) async {
    final map = await _attendanceTable.getTodayAttendance(uid, date);
    if (map != null) {
      return AttendanceModel.fromSqfliteMap(map);
    }
    return null;
  }

  @override
  Future<bool> hasAttendance({
    required String uid,
    required String date,
  }) async {
    return await _attendanceTable.hasAttendance(uid, date);
  }

  @override
  Future<List<AttendanceModel>> getUnsyncedRecords() async {
    final maps = await _attendanceTable.getUnsynced();
    return maps.map((map) => AttendanceModel.fromSqfliteMap(map)).toList();
  }

  @override
  Future<void> markSynced(String attendanceId) async {
    await _attendanceTable.markSynced(attendanceId);
  }
}
