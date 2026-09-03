import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final LocationService _locationService;
  StreamSubscription<AttendanceModel?>? _todayStreamSubscription;

  AttendanceBloc({
    required AttendanceRepository attendanceRepository,
    LocationService? locationService,
  })  : _attendanceRepository = attendanceRepository,
        _locationService = locationService ?? LocationService.instance,
        super(AttendanceState()) {
    on<CheckTodayAttendanceRequested>(_onCheckTodayAttendanceRequested);
    on<RefreshAttendanceLocationRequested>(_onRefreshAttendanceLocationRequested);
    on<SelfieCaptured>(_onSelfieCaptured);
    on<ClearSelfieRequested>(_onClearSelfieRequested);
    on<PerformCheckInRequested>(_onPerformCheckInRequested);
    on<PerformCheckOutRequested>(_onPerformCheckOutRequested);
    on<AttendanceStreamUpdated>(_onAttendanceStreamUpdated);
    on<LoadAttendanceHistoryRequested>(_onLoadAttendanceHistoryRequested);
    on<LoadMonthAttendanceRequested>(_onLoadMonthAttendanceRequested);
  }

  Future<void> _onCheckTodayAttendanceRequested(
    CheckTodayAttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    final todayDate = AppDateUtils.getCurrentLocalDate();
    debugPrint('[KarmaSetu] Current attendance date: $todayDate');
    debugPrint('[KarmaSetu] Current user UID: ${event.uid}');

    // Immediately clear any existing today attendance so stale data is never shown while loading
    emit(state.copyWith(
      clearTodayAttendance: true,
      activeDate: todayDate,
      isLoadingToday: true,
      clearMessages: true,
    ));

    // Cancel existing stream before subscribing
    await _todayStreamSubscription?.cancel();
    _todayStreamSubscription = _attendanceRepository
        .streamTodayAttendance(uid: event.uid, date: todayDate)
        .listen((attendance) {
      add(AttendanceStreamUpdated(attendance));
    });

    try {
      final attendance = await _attendanceRepository.getTodayAttendance(
        uid: event.uid,
        date: todayDate,
      );

      final isFound = attendance != null && attendance.date == todayDate;
      debugPrint('[KarmaSetu] Today\'s attendance found: $isFound');
      if (isFound) {
        debugPrint('[KarmaSetu] Today\'s attendance ID: ${attendance.attendanceId}');
      }

      // Strictly ensure record belongs to todayDate
      final validAttendance = isFound ? attendance : null;

      // Also proactively fetch current month's attendance history for live dashboard stats
      final now = DateTime.now();
      final startDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final endDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      List<AttendanceModel> historyList = state.history;
      try {
        historyList = await _attendanceRepository.getAttendanceForMonth(
          uid: event.uid,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (_) {}

      emit(state.copyWith(
        todayAttendance: validAttendance,
        clearTodayAttendance: validAttendance == null,
        activeDate: todayDate,
        history: historyList,
        isLoadingToday: false,
        lastRefreshed: DateTime.now(),
        clearSelfie: validAttendance != null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingToday: false,
        activeDate: todayDate,
        errorMessage: 'Failed to load today\'s attendance: $e',
      ));
    }

    // Proactively refresh location in the background
    add(const RefreshAttendanceLocationRequested());
  }

  void _onAttendanceStreamUpdated(
    AttendanceStreamUpdated event,
    Emitter<AttendanceState> emit,
  ) {
    final currentToday = AppDateUtils.getCurrentLocalDate();
    // Only accept streamed attendance if it matches today's date
    final validAttendance = (event.attendance != null && event.attendance!.date == currentToday)
        ? event.attendance
        : null;

    final updatedHistory = validAttendance != null
        ? _updateHistoryList(state.history, validAttendance)
        : state.history;

    emit(state.copyWith(
      todayAttendance: validAttendance,
      clearTodayAttendance: validAttendance == null,
      activeDate: currentToday,
      history: updatedHistory,
      isLoadingToday: false,
      lastRefreshed: DateTime.now(),
      clearSelfie: validAttendance != null,
    ));
  }

  Future<void> _onRefreshAttendanceLocationRequested(
    RefreshAttendanceLocationRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isFetchingLocation: true));

    try {
      final locationResult = await _locationService.getCurrentLocationWithAddress();
      emit(state.copyWith(
        currentLocation: locationResult,
        isFetchingLocation: false,
      ));
    } catch (_) {
      emit(state.copyWith(isFetchingLocation: false));
    }
  }

  void _onSelfieCaptured(
    SelfieCaptured event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(selfiePath: event.selfiePath));
  }

  void _onClearSelfieRequested(
    ClearSelfieRequested event,
    Emitter<AttendanceState> emit,
  ) {
    emit(state.copyWith(clearSelfie: true));
  }

  Future<void> _onPerformCheckInRequested(
    PerformCheckInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      submissionStatus: AttendanceSubmissionStatus.submitting,
      clearMessages: true,
    ));

    try {
      final now = DateTime.now();
      final todayDate = AppDateUtils.formatBusinessDate(now);

      // Verify if record for uid + todayDate already exists
      final existing = await _attendanceRepository.getTodayAttendance(
        uid: event.uid,
        date: todayDate,
      );

      if (existing != null && existing.date == todayDate) {
        emit(state.copyWith(
          todayAttendance: existing,
          activeDate: todayDate,
          submissionStatus: AttendanceSubmissionStatus.success,
          successMessage: 'Already punched in for today!',
          clearSelfie: true,
        ));
        return;
      }

      // Ensure we have current location
      LocationResult? location = state.currentLocation;
      location ??= await _locationService.getCurrentLocationWithAddress();

      final docId = '${event.uid}_$todayDate';

      final model = AttendanceModel(
        attendanceId: docId,
        uid: event.uid,
        employeeId: event.employeeId,
        date: todayDate,
        checkIn: now,
        checkInLatitude: location?.latitude ?? 12.9716,
        checkInLongitude: location?.longitude ?? 77.5946,
        checkInLocation: location?.formattedAddress ?? 'Bangalore Office Campus',
        checkInSelfie: event.selfiePath ?? state.selfiePath,
        status: 'CHECKED_IN',
        workingMinutes: 0,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _attendanceRepository.checkIn(model);
      final updatedHistory = _updateHistoryList(state.history, saved);

      emit(state.copyWith(
        todayAttendance: saved,
        activeDate: todayDate,
        history: updatedHistory,
        submissionStatus: AttendanceSubmissionStatus.success,
        successMessage: 'Punched in successfully!',
        currentLocation: location,
        clearSelfie: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        submissionStatus: AttendanceSubmissionStatus.failure,
        errorMessage: 'Check In failed: $e',
      ));
    }
  }

  Future<void> _onPerformCheckOutRequested(
    PerformCheckOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      submissionStatus: AttendanceSubmissionStatus.submitting,
      clearMessages: true,
    ));

    try {
      final now = DateTime.now();
      final todayDate = AppDateUtils.formatBusinessDate(now);

      // Ensure we only checkout today's attendance record
      final currentTodayRecord = state.verifiedTodayAttendance;
      if (currentTodayRecord == null) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'No active check-in found for today ($todayDate). Please check in first.',
        ));
        return;
      }

      LocationResult? location = state.currentLocation;
      location ??= await _locationService.getCurrentLocationWithAddress();

      final checkInTime = currentTodayRecord.checkIn;
      final workingMinutes = now.difference(checkInTime).inMinutes;

      final targetDocId = currentTodayRecord.attendanceId.isNotEmpty
          ? currentTodayRecord.attendanceId
          : '${currentTodayRecord.uid}_$todayDate';

      final updated = await _attendanceRepository.checkOut(
        attendanceId: targetDocId,
        checkOutTime: now,
        latitude: location?.latitude ?? 12.9716,
        longitude: location?.longitude ?? 77.5946,
        location: location?.formattedAddress ?? 'Bangalore Office Campus',
        selfiePath: event.selfiePath ?? state.selfiePath,
        workingMinutes: workingMinutes > 0 ? workingMinutes : 1,
      );

      final updatedHistory = _updateHistoryList(state.history, updated);

      emit(state.copyWith(
        todayAttendance: updated,
        activeDate: todayDate,
        history: updatedHistory,
        submissionStatus: AttendanceSubmissionStatus.success,
        successMessage: 'Punched out successfully!',
        currentLocation: location,
      ));
    } catch (e) {
      emit(state.copyWith(
        submissionStatus: AttendanceSubmissionStatus.failure,
        errorMessage: 'Check Out failed: $e',
      ));
    }
  }

  List<AttendanceModel> _updateHistoryList(
    List<AttendanceModel> history,
    AttendanceModel record,
  ) {
    final list = List<AttendanceModel>.from(history);
    final index = list.indexWhere((item) =>
        item.attendanceId == record.attendanceId ||
        (item.date == record.date && item.uid == record.uid));

    if (index != -1) {
      list[index] = record;
    } else {
      list.insert(0, record);
    }

    list.sort((a, b) => b.checkIn.compareTo(a.checkIn));
    return list;
  }

  Future<void> _onLoadAttendanceHistoryRequested(
    LoadAttendanceHistoryRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoadingHistory: true));

    try {
      final history = await _attendanceRepository.getAttendanceHistory(event.uid);
      emit(state.copyWith(
        history: history,
        isLoadingHistory: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingHistory: false));
    }
  }

  Future<void> _onLoadMonthAttendanceRequested(
    LoadMonthAttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoadingHistory: true));

    final year = event.month.year;
    final month = event.month.month;
    final startDate = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    try {
      final history = await _attendanceRepository.getAttendanceForMonth(
        uid: event.uid,
        startDate: startDate,
        endDate: endDate,
      );
      emit(state.copyWith(
        history: history,
        isLoadingHistory: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingHistory: false));
    }
  }

  @override
  Future<void> close() {
    _todayStreamSubscription?.cancel();
    return super.close();
  }
}
