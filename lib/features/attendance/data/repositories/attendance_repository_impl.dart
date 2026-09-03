import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remoteDataSource;
  final AttendanceLocalDataSource _localDataSource;

  AttendanceRepositoryImpl({
    required AttendanceRemoteDataSource remoteDataSource,
    AttendanceLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource ?? AttendanceLocalDataSourceImpl();

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

    // Fallback to remote and cache locally
    try {
      final remote = await _remoteDataSource.getTodayAttendance(uid: uid, date: date);
      if (remote != null) {
        await _localDataSource.saveAttendance(remote);
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
    return _remoteDataSource.streamTodayAttendance(uid: uid, date: date).map((model) {
      if (model != null) {
        _localDataSource.saveAttendance(model);
      }
      return model;
    });
  }

  @override
  Future<AttendanceModel> checkIn(AttendanceModel model) async {
    // Save to local SQLite table immediately
    await _localDataSource.saveAttendance(model);

    try {
      final saved = await _remoteDataSource.checkIn(model);
      await _localDataSource.saveAttendance(saved);
      return saved;
    } catch (_) {
      // Return locally saved record if offline
      return model;
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

      await _localDataSource.saveAttendance(updated);
      return updated;
    } catch (_) {
      // Update local record if offline
      final todayDate = AttendanceModel.formatDate(checkOutTime);
      final parts = attendanceId.split('_');
      final uid = parts.isNotEmpty ? parts[0] : '';
      final local = await _localDataSource.getTodayAttendance(uid: uid, date: todayDate);

      if (local != null) {
        final updatedLocal = local.copyWith(
          checkOut: checkOutTime,
          checkOutLatitude: latitude,
          checkOutLongitude: longitude,
          checkOutLocation: location,
          checkOutSelfie: selfiePath,
          workingMinutes: workingMinutes,
          status: 'PRESENT',
          updatedAt: DateTime.now(),
        );
        await _localDataSource.saveAttendance(updatedLocal);
        return updatedLocal;
      }
      rethrow;
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory(String uid) async {
    try {
      final remoteHistory = await _remoteDataSource.getAttendanceHistory(uid);
      for (final item in remoteHistory) {
        await _localDataSource.saveAttendance(item);
      }
      return remoteHistory;
    } catch (_) {
      final now = DateTime.now();
      final startDate = '${now.year - 1}-01-01';
      final endDate = '${now.year + 1}-12-31';
      return await _localDataSource.getAttendanceForMonth(
        uid: uid,
        startDate: startDate,
        endDate: endDate,
      );
    }
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

    // 2. Fetch remote in background/sync and save to local if needed
    try {
      final remoteList = await _remoteDataSource.getAttendanceHistory(uid);
      for (final item in remoteList) {
        await _localDataSource.saveAttendance(item);
      }

      // Re-query local database after sync
      return await _localDataSource.getAttendanceForMonth(
        uid: uid,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      // If offline or network error, return local SQLite records directly
      return localList;
    }
  }

  @override
  Future<void> saveLocalAttendance(AttendanceModel model) async {
    await _localDataSource.saveAttendance(model);
  }

  @override
  Future<int> syncUnsyncedRecords() async {
    try {
      final unsynced = await _localDataSource.getUnsyncedRecords();
      int syncedCount = 0;

      for (final record in unsynced) {
        try {
          await _remoteDataSource.checkIn(record);
          await _localDataSource.markSynced(record.attendanceId);
          syncedCount++;
        } catch (_) {
          // Continue with next record
        }
      }

      return syncedCount;
    } catch (_) {
      return 0;
    }
  }
}
