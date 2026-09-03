import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/date_utils.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

const double _assignedLat = 12.9031027;
const double _assignedLng = 77.6325216;
const double _maxRadiusMeters = 500.0;

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final LocationService _locationService;
  final ConnectivityService _connectivityService;
  StreamSubscription<AttendanceModel?>? _todayStreamSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  AttendanceBloc({
    required AttendanceRepository attendanceRepository,
    LocationService? locationService,
    ConnectivityService? connectivityService,
  })  : _attendanceRepository = attendanceRepository,
        _locationService = locationService ?? LocationService.instance,
        _connectivityService = connectivityService ?? ConnectivityService.instance,
        super(AttendanceState(
          isOffline: !(connectivityService ?? ConnectivityService.instance).hasConnection,
        )) {
    on<CheckTodayAttendanceRequested>(_onCheckTodayAttendanceRequested);
    on<RefreshAttendanceLocationRequested>(_onRefreshAttendanceLocationRequested);
    on<SelfieCaptured>(_onSelfieCaptured);
    on<ClearSelfieRequested>(_onClearSelfieRequested);
    on<PerformCheckInRequested>(_onPerformCheckInRequested);
    on<PerformCheckOutRequested>(_onPerformCheckOutRequested);
    on<AttendanceStreamUpdated>(_onAttendanceStreamUpdated);
    on<LoadAttendanceHistoryRequested>(_onLoadAttendanceHistoryRequested);
    on<LoadMonthAttendanceRequested>(_onLoadMonthAttendanceRequested);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<SyncUnsyncedAttendanceRequested>(_onSyncUnsyncedAttendanceRequested);

    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      add(ConnectivityChanged(isConnected));
    });
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<AttendanceState> emit,
  ) async {
    final wasOffline = state.isOffline;
    emit(state.copyWith(isOffline: !event.isConnected));

    if (event.isConnected && wasOffline) {
      debugPrint('[AttendanceBloc] Connection restored! Triggering auto-sync...');
      add(const SyncUnsyncedAttendanceRequested());
    }
  }

  Future<void> _onSyncUnsyncedAttendanceRequested(
    SyncUnsyncedAttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));

    try {
      final syncedCount = await _attendanceRepository.syncUnsyncedRecords();
      debugPrint('[AttendanceBloc] Auto-synced $syncedCount offline records.');

      if (syncedCount > 0) {
        // Refresh today attendance to reflect synced state
        final todayDate = AppDateUtils.getCurrentLocalDate();
        final currentAttendance = state.todayAttendance;
        if (currentAttendance != null) {
          final refreshed = await _attendanceRepository.getTodayAttendance(
            uid: currentAttendance.uid,
            date: todayDate,
          );
          emit(state.copyWith(
            todayAttendance: refreshed ?? currentAttendance.copyWith(isSynced: true),
            isSyncing: false,
            successMessage: '$syncedCount offline attendance record(s) synced to server!',
          ));
        } else {
          emit(state.copyWith(
            isSyncing: false,
            successMessage: '$syncedCount offline attendance record(s) synced to server!',
          ));
        }
      } else {
        emit(state.copyWith(isSyncing: false));
      }
    } catch (e) {
      emit(state.copyWith(isSyncing: false));
    }
  }

  Future<void> _onCheckTodayAttendanceRequested(
    CheckTodayAttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    final todayDate = AppDateUtils.getCurrentLocalDate();
    debugPrint('[KarmaSetu] Current attendance date: $todayDate');
    debugPrint('[KarmaSetu] Current user UID: ${event.uid}');

    // If we already have valid today attendance in memory for todayDate, keep it so it doesn't flicker or wipe out
    final existingToday = state.verifiedTodayAttendance;
    final hasValidToday = existingToday != null && existingToday.date == todayDate;

    emit(state.copyWith(
      clearTodayAttendance: !hasValidToday,
      activeDate: todayDate,
      isLoadingToday: !hasValidToday,
      clearMessages: true,
    ));

    // Cancel existing stream before subscribing
    await _todayStreamSubscription?.cancel();
    try {
      _todayStreamSubscription = _attendanceRepository
          .streamTodayAttendance(uid: event.uid, date: todayDate)
          .listen((attendance) {
        add(AttendanceStreamUpdated(attendance));
      }, onError: (error) {
        debugPrint('[KarmaSetu] streamTodayAttendance error: $error');
      });
    } catch (e) {
      debugPrint('[KarmaSetu] Failed to subscribe to attendance stream: $e');
    }

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
      final validAttendance = isFound ? attendance : (hasValidToday ? existingToday : null);

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
        // clearSelfie: validAttendance != null,
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

    // Guard: If remote stream emits null, NEVER wipe out existing local/offline attendance!
    if (event.attendance == null && state.verifiedTodayAttendance != null) {
      return;
    }

    final rawAttendance = (event.attendance != null && event.attendance!.date == currentToday)
        ? event.attendance
        : null;

    final existing = state.verifiedTodayAttendance;
    // Guard: If local record is checked out but not synced, don't let remote revert it
    if (existing != null && !existing.isSynced && existing.isCheckedOut) {
      if (rawAttendance != null && !rawAttendance.isCheckedOut) {
        return;
      }
    }

    if (rawAttendance == null && existing != null) {
      return;
    }

    // Preserve local selfie paths if incoming remote stream doesn't have them
    final validAttendance = rawAttendance != null
        ? rawAttendance.copyWith(
            checkInSelfie: (rawAttendance.checkInSelfie?.isNotEmpty ?? false)
                ? rawAttendance.checkInSelfie
                : existing?.checkInSelfie,
            checkOutSelfie: (rawAttendance.checkOutSelfie?.isNotEmpty ?? false)
                ? rawAttendance.checkOutSelfie
                : existing?.checkOutSelfie,
          )
        : existing;

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
      // clearSelfie: validAttendance != null,
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

      // Mandatory condition 1: Selfie image verification
      final selfie = event.selfiePath ?? state.selfiePath;
      if (selfie == null || !File(selfie).existsSync()) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'Selfie photo is mandatory for Check-In. Please take a photo first.',
        ));
        return;
      }

      // Mandatory condition 2: GPS Location verification
      LocationResult? location = state.currentLocation;
      location ??= await _locationService.getCurrentLocationWithAddress();
      if (location == null) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'GPS Location is mandatory for Check-In. Please turn on GPS and grant location permission.',
        ));
        return;
      }

      // Mandatory condition 3: Geofencing constraint
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        _assignedLat,
        _assignedLng,
      );
      if (distance > _maxRadiusMeters) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'Location blocked: You are outside the assigned site radius (${distance.toStringAsFixed(0)}m > ${_maxRadiusMeters.toStringAsFixed(0)}m).',
        ));
        return;
      }

      final docId = '${event.uid}_$todayDate';

      final model = AttendanceModel(
        attendanceId: docId,
        uid: event.uid,
        employeeId: event.employeeId,
        date: todayDate,
        checkIn: now,
        checkInLatitude: location.latitude,
        checkInLongitude: location.longitude,
        checkInLocation: location.formattedAddress,
        checkInSelfie: selfie,
        status: 'CHECKED_IN',
        workingMinutes: 0,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _attendanceRepository.checkIn(model);
      final updatedHistory = _updateHistoryList(state.history, saved);

      final message = saved.isSynced
          ? 'Punched in successfully!'
          : 'Punched in locally (Offline Mode). Stored in local database.';

      emit(state.copyWith(
        todayAttendance: saved,
        activeDate: todayDate,
        history: updatedHistory,
        submissionStatus: AttendanceSubmissionStatus.success,
        successMessage: message,
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

      // Mandatory condition 1: Selfie image verification
      final selfie = event.selfiePath ?? state.selfiePath;
      if (selfie == null || !File(selfie).existsSync()) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'Selfie photo is mandatory for Check-Out. Please take a photo first.',
        ));
        return;
      }

      // Mandatory condition 2: GPS Location verification
      LocationResult? location = state.currentLocation;
      location ??= await _locationService.getCurrentLocationWithAddress();
      if (location == null) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'GPS Location is mandatory for Check-Out. Please turn on GPS and grant location permission.',
        ));
        return;
      }

      // Mandatory condition 3: Geofencing constraint
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        _assignedLat,
        _assignedLng,
      );
      if (distance > _maxRadiusMeters) {
        emit(state.copyWith(
          submissionStatus: AttendanceSubmissionStatus.failure,
          errorMessage: 'Location blocked: You are outside the assigned site radius (${distance.toStringAsFixed(0)}m > ${_maxRadiusMeters.toStringAsFixed(0)}m).',
        ));
        return;
      }

      final checkInTime = currentTodayRecord.checkIn;
      final workingMinutes = now.difference(checkInTime).inMinutes;

      final targetDocId = currentTodayRecord.attendanceId.isNotEmpty
          ? currentTodayRecord.attendanceId
          : '${currentTodayRecord.uid}_$todayDate';

      final updated = await _attendanceRepository.checkOut(
        attendanceId: targetDocId,
        checkOutTime: now,
        latitude: location.latitude,
        longitude: location.longitude,
        location: location.formattedAddress,
        selfiePath: selfie,
        workingMinutes: workingMinutes > 0 ? workingMinutes : 1,
      );

      final updatedHistory = _updateHistoryList(state.history, updated);

      final message = updated.isSynced
          ? 'Punched out successfully!'
          : 'Punched out locally (Offline Mode). Stored in local database.';

      emit(state.copyWith(
        todayAttendance: updated,
        activeDate: todayDate,
        history: updatedHistory,
        submissionStatus: AttendanceSubmissionStatus.success,
        successMessage: message,
        currentLocation: location,
        clearSelfie: true,
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
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
