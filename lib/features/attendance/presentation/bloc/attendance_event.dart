import 'package:flutter/foundation.dart';
import '../../data/models/attendance_model.dart';

@immutable
sealed class AttendanceEvent {
  const AttendanceEvent();
}

final class CheckTodayAttendanceRequested extends AttendanceEvent {
  final String uid;
  final String employeeId;

  const CheckTodayAttendanceRequested({
    required this.uid,
    required this.employeeId,
  });
}

final class RefreshAttendanceLocationRequested extends AttendanceEvent {
  const RefreshAttendanceLocationRequested();
}

final class SelfieCaptured extends AttendanceEvent {
  final String selfiePath;

  const SelfieCaptured(this.selfiePath);
}

final class ClearSelfieRequested extends AttendanceEvent {
  const ClearSelfieRequested();
}

final class PerformCheckInRequested extends AttendanceEvent {
  final String uid;
  final String employeeId;
  final String? selfiePath;

  const PerformCheckInRequested({
    required this.uid,
    required this.employeeId,
    this.selfiePath,
  });
}

final class PerformCheckOutRequested extends AttendanceEvent {
  final String attendanceId;
  final String? selfiePath;

  const PerformCheckOutRequested({
    required this.attendanceId,
    this.selfiePath,
  });
}

final class AttendanceStreamUpdated extends AttendanceEvent {
  final AttendanceModel? attendance;

  const AttendanceStreamUpdated(this.attendance);
}

final class LoadAttendanceHistoryRequested extends AttendanceEvent {
  final String uid;

  const LoadAttendanceHistoryRequested(this.uid);
}

final class LoadMonthAttendanceRequested extends AttendanceEvent {
  final String uid;
  final DateTime month;

  const LoadMonthAttendanceRequested({
    required this.uid,
    required this.month,
  });
}
