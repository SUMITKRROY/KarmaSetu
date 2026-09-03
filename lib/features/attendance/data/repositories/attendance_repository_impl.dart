import '../../../../core/network/network_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remoteDataSource;
  final AttendanceLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AttendanceRepositoryImpl({
    required AttendanceRemoteDataSource remoteDataSource,
    AttendanceLocalDataSource? localDataSource,
    NetworkInfo? networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource ?? AttendanceLocalDataSourceImpl(),
        _networkInfo = networkInfo ?? NetworkInfoImpl();

  @override
  Future<AttendanceModel?> getTodayAttendance({
    required String uid,
    required String date,
  }) async {
    // Check local SQLite first for immediate response
    final local = await _localDataSource.getTodayAttendance(uid: uid, date: date);
    if (local != null) {
      return local;
    }

    // Check internet before remote query
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return null;
    }

    // Fallback to remote and cache locally
    try {
      final remote = await _remoteDataSource.getTodayAttendance(uid: uid, date: date);
      if (remote != null) {
        await _localDataSource.saveAttendance(remote, isSynced: true);
      }
      return remote;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AttendanceModel?> streamTodayAttendance({
    required String uid,
    required String date,
  }) {
    return _remoteDataSource.streamTodayAttendance(uid: uid, date: date).asyncMap((model) async {
      final local = await _localDataSource.getTodayAttendance(uid: uid, date: date);

      // Local has unsynced checkout data remote doesn't know about yet — remote is stale, don't overwrite.
      if (local != null && !local.isSynced && local.isCheckedOut) {
        if (model == null || !model.isCheckedOut) {
          return local;
        }
      }

      if (model != null) {
        final merged = model.copyWith(
          checkInSelfie: (model.checkInSelfie?.isNotEmpty ?? false) ? model.checkInSelfie : local?.checkInSelfie,
          checkOutSelfie: (model.checkOutSelfie?.isNotEmpty ?? false) ? model.checkOutSelfie : local?.checkOutSelfie,
        );
        await _localDataSource.saveAttendance(merged, isSynced: true);
        return merged;
      }

      return local;
    });
  }

  @override
  Future<AttendanceModel> checkIn(AttendanceModel model) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      // Offline mode: Store locally with isSynced = 0
      final offlineModel = model.copyWith(isSynced: false);
      await _localDataSource.saveAttendance(offlineModel, isSynced: false);
      return offlineModel;
    }

    try {
      final saved = await _remoteDataSource.checkIn(model);
      final syncedModel = saved.copyWith(isSynced: true);
      await _localDataSource.saveAttendance(syncedModel, isSynced: true);
      return syncedModel;
    } catch (_) {
      // Fallback: Store locally if network request fails
      final offlineModel = model.copyWith(isSynced: false);
      await _localDataSource.saveAttendance(offlineModel, isSynced: false);
      return offlineModel;
    }
  }

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
    final todayDate = AttendanceModel.formatDate(checkOutTime);
    final lastUnderscore = attendanceId.lastIndexOf('_');
    final uid = lastUnderscore != -1
        ? attendanceId.substring(0, lastUnderscore)
        : attendanceId;
    final local = await _localDataSource.getTodayAttendance(uid: uid, date: todayDate);

    final isConnected = await _networkInfo.isConnected;
    AttendanceModel? resultModel;

    if (isConnected) {
      try {
        final updated = await _remoteDataSource.checkOut(
          attendanceId: attendanceId,
          checkOutTime: checkOutTime,
          latitude: latitude,
          longitude: longitude,
          location: location,
          selfiePath: selfiePath,
          workingMinutes: workingMinutes,
        );

        final mergedModel = updated.copyWith(
          uid: updated.uid.isNotEmpty ? updated.uid : (local?.uid ?? uid),
          employeeId: updated.employeeId.isNotEmpty ? updated.employeeId : (local?.employeeId ?? ''),
          date: updated.date.isNotEmpty ? updated.date : (local?.date ?? todayDate),
          checkInSelfie: (updated.checkInSelfie?.isNotEmpty ?? false)
              ? updated.checkInSelfie
              : local?.checkInSelfie,
          checkOutSelfie: (selfiePath?.isNotEmpty ?? false)
              ? selfiePath
              : ((updated.checkOutSelfie?.isNotEmpty ?? false)
                  ? updated.checkOutSelfie
                  : local?.checkOutSelfie),
          isSynced: true,
        );

        await _localDataSource.saveAttendance(mergedModel, isSynced: true);
        resultModel = mergedModel;
      } catch (_) {
        // Fallback to offline local update on remote exception
      }
    }

    // Offline checkout mode or fallback
    if (resultModel == null) {
      if (local != null) {
        final updatedLocal = local.copyWith(
          checkOut: checkOutTime,
          checkOutLatitude: latitude,
          checkOutLongitude: longitude,
          checkOutLocation: location,
          checkOutSelfie: selfiePath ?? local.checkOutSelfie,
          workingMinutes: workingMinutes,
          status: 'PRESENT',
          updatedAt: DateTime.now(),
          isSynced: false,
        );
        await _localDataSource.saveAttendance(updatedLocal, isSynced: false);
        resultModel = updatedLocal;
      } else {
        // Create and save offline checkout model
        final offlineModel = AttendanceModel(
          attendanceId: attendanceId,
          uid: uid,
          employeeId: '',
          date: todayDate,
          checkIn: checkOutTime,
          checkOut: checkOutTime,
          checkInLatitude: latitude,
          checkInLongitude: longitude,
          checkInLocation: location,
          checkOutLatitude: latitude,
          checkOutLongitude: longitude,
          checkOutLocation: location,
          checkOutSelfie: selfiePath,
          status: 'PRESENT',
          workingMinutes: workingMinutes,
          createdAt: checkOutTime,
          updatedAt: checkOutTime,
          isSynced: false,
        );
        await _localDataSource.saveAttendance(offlineModel, isSynced: false);
        resultModel = offlineModel;
      }
    }

    return resultModel;
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory(String uid) async {
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteHistory = await _remoteDataSource.getAttendanceHistory(uid);
        for (final item in remoteHistory) {
          await _localDataSource.saveAttendance(item, isSynced: true);
        }
        return remoteHistory;
      } catch (_) {}
    }

    final now = DateTime.now();
    final startDate = '${now.year - 1}-01-01';
    final endDate = '${now.year + 1}-12-31';
    return await _localDataSource.getAttendanceForMonth(
      uid: uid,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AttendanceModel>> getAttendanceForMonth({
    required String uid,
    required String startDate,
    required String endDate,
  }) async {
    // 1. Fetch from local SQLite AttendanceTable first
    final localList = await _localDataSource.getAttendanceForMonth(
      uid: uid,
      startDate: startDate,
      endDate: endDate,
    );

    // 2. Fetch remote in background/sync and save to local if connected
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteList = await _remoteDataSource.getAttendanceHistory(uid);
        for (final item in remoteList) {
          await _localDataSource.saveAttendance(item, isSynced: true);
        }

        // Re-query local database after sync
        return await _localDataSource.getAttendanceForMonth(
          uid: uid,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (_) {}
    }

    return localList;
  }

  @override
  Future<void> saveLocalAttendance(AttendanceModel model) async {
    await _localDataSource.saveAttendance(model);
  }

  @override
  Future<int> syncUnsyncedRecords() async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return 0;
    }

    try {
      final unsynced = await _localDataSource.getUnsyncedRecords();
      int syncedCount = 0;

      for (final record in unsynced) {
        try {
          await _remoteDataSource.syncAttendance(record);
          await _localDataSource.markSynced(record.attendanceId);
          syncedCount++;
        } catch (e) {
          // If individual upload fails, proceed to next
        }
      }

      return syncedCount;
    } catch (_) {
      return 0;
    }
  }
}

