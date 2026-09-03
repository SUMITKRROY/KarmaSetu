import 'package:flutter_test/flutter_test.dart';
import 'package:karmasetu/features/attendance/data/models/attendance_model.dart';
import 'package:karmasetu/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:karmasetu/features/auth/domain/entities/user.dart';
import 'package:karmasetu/features/auth/domain/repositories/auth_repository.dart';
import 'package:karmasetu/features/leave/data/models/leave_model.dart';
import 'package:karmasetu/features/leave/domain/repositories/leave_repository.dart';
import 'package:karmasetu/main.dart';

class _MockAuthRepository implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async {
    return const User(
      uid: 'test_uid',
      name: 'Test Employee',
      email: 'employee@test.com',
      employeeId: 'EMP001',
      role: 'employee',
      site: 'Bangalore',
      department: 'Engineering',
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    required String role,
    required String site,
    required String department,
  }) async {
    return User(
      uid: 'test_uid',
      name: name,
      email: email,
      employeeId: employeeId,
      role: role,
      site: site,
      department: department,
    );
  }

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User?> getLocalUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> seedDefaultUsers() async {}
}

class _MockAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceModel?> getTodayAttendance({required String uid, required String date}) async => null;

  @override
  Stream<AttendanceModel?> streamTodayAttendance({required String uid, required String date}) =>
      const Stream.empty();

  @override
  Future<AttendanceModel> checkIn(AttendanceModel model) async => model;

  @override
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
    required double latitude,
    required double longitude,
    required String location,
    String? selfiePath,
    required int workingMinutes,
  }) async {
    return AttendanceModel(
      attendanceId: attendanceId,
      uid: 'test_uid',
      employeeId: 'EMP001',
      date: '2026-09-03',
      checkIn: DateTime.now(),
      checkOut: checkOutTime,
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      checkInLocation: location,
      status: 'PRESENT',
      workingMinutes: workingMinutes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory(String uid) async => [];

  @override
  Future<List<AttendanceModel>> getAttendanceForMonth({
    required String uid,
    required String startDate,
    required String endDate,
  }) async => [];

  @override
  Future<void> saveLocalAttendance(AttendanceModel model) async {}

  @override
  Future<int> syncUnsyncedRecords() async => 0;
}

class _MockLeaveRepository implements LeaveRepository {
  @override
  Future<LeaveModel> applyLeave(LeaveModel model) async => model;

  @override
  Future<List<LeaveModel>> getUserLeaves(String uid) async => [];

  @override
  Future<List<LeaveModel>> getAllLeaves() async => [];

  @override
  Stream<List<LeaveModel>> streamUserLeaves(String uid) => const Stream.empty();

  @override
  Stream<List<LeaveModel>> streamAllLeaves() => const Stream.empty();

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  }) async {}

  @override
  Future<int> syncUnsyncedLeaves() async => 0;
}

void main() {
  testWidgets('KarmaSetu App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      KarmaSetuApp(
        authRepository: _MockAuthRepository(),
        attendanceRepository: _MockAttendanceRepository(),
        leaveRepository: _MockLeaveRepository(),
      ),
    );
    expect(find.text('KarmaSetu'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

