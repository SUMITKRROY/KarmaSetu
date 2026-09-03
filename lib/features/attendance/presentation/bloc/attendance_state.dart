import 'package:flutter/foundation.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/attendance_model.dart';

enum AttendanceSubmissionStatus {
  idle,
  submitting,
  success,
  failure,
}

@immutable
class AttendanceState {
  final AttendanceModel? todayAttendance;
  final String? activeDate;
  final bool isLoadingToday;
  final LocationResult? currentLocation;
  final bool isFetchingLocation;
  final String? selfiePath;
  final AttendanceSubmissionStatus submissionStatus;
  final String? successMessage;
  final String? errorMessage;
  final List<AttendanceModel> history;
  final bool isLoadingHistory;
  final DateTime lastRefreshed;
  final bool isOffline;
  final bool isSyncing;
  final int unsyncedCount;

  AttendanceState({
    this.todayAttendance,
    this.activeDate,
    this.isLoadingToday = false,
    this.currentLocation,
    this.isFetchingLocation = false,
    this.selfiePath,
    this.submissionStatus = AttendanceSubmissionStatus.idle,
    this.successMessage,
    this.errorMessage,
    this.history = const [],
    this.isLoadingHistory = false,
    DateTime? lastRefreshed,
    this.isOffline = false,
    this.isSyncing = false,
    this.unsyncedCount = 0,
  }) : lastRefreshed = lastRefreshed ?? DateTime.now();

  /// Strictly verifies that [todayAttendance] matches the current local date.
  /// If it belongs to a past date or is null, returns null.
  AttendanceModel? get verifiedTodayAttendance {
    if (todayAttendance == null) return null;
    final currentToday = AppDateUtils.getCurrentLocalDate();
    if (todayAttendance!.date == currentToday) {
      return todayAttendance;
    }
    return null;
  }

  bool get isCheckedIn => verifiedTodayAttendance != null && verifiedTodayAttendance!.checkOut == null;
  bool get isCheckedOut => verifiedTodayAttendance != null && verifiedTodayAttendance!.checkOut != null;
  bool get isNotCheckedIn => verifiedTodayAttendance == null;

  AttendanceState copyWith({
    AttendanceModel? todayAttendance,
    bool clearTodayAttendance = false,
    String? activeDate,
    bool? isLoadingToday,
    LocationResult? currentLocation,
    bool? isFetchingLocation,
    String? selfiePath,
    bool clearSelfie = false,
    AttendanceSubmissionStatus? submissionStatus,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
    List<AttendanceModel>? history,
    bool? isLoadingHistory,
    DateTime? lastRefreshed,
    bool? isOffline,
    bool? isSyncing,
    int? unsyncedCount,
  }) {
    return AttendanceState(
      todayAttendance: clearTodayAttendance ? null : (todayAttendance ?? this.todayAttendance),
      activeDate: clearTodayAttendance ? null : (activeDate ?? this.activeDate),
      isLoadingToday: isLoadingToday ?? this.isLoadingToday,
      currentLocation: currentLocation ?? this.currentLocation,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      selfiePath: clearSelfie ? null : (selfiePath ?? this.selfiePath),
      submissionStatus: submissionStatus ?? this.submissionStatus,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      isOffline: isOffline ?? this.isOffline,
      isSyncing: isSyncing ?? this.isSyncing,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    );
  }
}

