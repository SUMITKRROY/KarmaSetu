import '../../data/models/attendance_model.dart';

abstract interface class AttendanceRepository {
  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  });

  Stream<AttendanceModel?> streamTodayAttendance({
    required String uid,
    required String date,
  });

  Future<AttendanceModel> checkIn(AttendanceModel model);

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
    required double latitude,
    required double longitude,
    required String location,
    String? selfiePath,
    required int workingMinutes,
  });

  Future<List<AttendanceModel>> getAttendanceHistory(String uid);

  Future<List<AttendanceModel>> getAttendanceForMonth({
    required String uid,
    required String startDate,
    required String endDate,
  });

  Future<void> saveLocalAttendance(AttendanceModel model);

  Future<int> syncUnsyncedRecords();
}
