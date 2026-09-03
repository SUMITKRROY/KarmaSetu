import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_local_datasource.dart';
import '../datasources/leave_remote_datasource.dart';
import '../models/leave_model.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource _remoteDataSource;
  final LeaveLocalDataSource _localDataSource;

  LeaveRepositoryImpl({
    required LeaveRemoteDataSource remoteDataSource,
    LeaveLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource ?? LeaveLocalDataSourceImpl();

  @override
  Future<LeaveModel> applyLeave(LeaveModel model) async {
    // 1. Immediately store to local SQLite table (offline first)
    await _localDataSource.saveLeave(model);

    // 2. Sync to Firebase Firestore
    try {
      final savedRemote = await _remoteDataSource.applyLeave(model);
      await _localDataSource.saveLeave(savedRemote);
      await _localDataSource.markSynced(savedRemote.leaveId);
      return savedRemote;
    } catch (_) {
      // Return local model if offline (will be synced later)
      return model;
    }
  }

  @override
  Future<List<LeaveModel>> getUserLeaves(String uid) async {
    // 1. Fetch from local SQLite table first
    final localLeaves = await _localDataSource.getLeavesForUser(uid: uid);

    // 2. Fetch and sync from Firestore in background
    try {
      final remoteLeaves = await _remoteDataSource.getLeavesForUser(uid);
      for (final leave in remoteLeaves) {
        await _localDataSource.saveLeave(leave);
        await _localDataSource.markSynced(leave.leaveId);
      }
      return await _localDataSource.getLeavesForUser(uid: uid);
    } catch (_) {
      return localLeaves;
    }
  }

  @override
  Future<List<LeaveModel>> getAllLeaves() async {
    // 1. Fetch from local SQLite database first
    final localLeaves = await _localDataSource.getAllLeaves();

    // 2. Fetch and sync from Firestore
    try {
      final remoteLeaves = await _remoteDataSource.getAllLeaves();
      for (final leave in remoteLeaves) {
        await _localDataSource.saveLeave(leave);
        await _localDataSource.markSynced(leave.leaveId);
      }
      return await _localDataSource.getAllLeaves();
    } catch (_) {
      return localLeaves;
    }
  }

  @override
  Stream<List<LeaveModel>> streamUserLeaves(String uid) {
    return _remoteDataSource.streamLeavesForUser(uid).map((leaves) {
      for (final leave in leaves) {
        _localDataSource.saveLeave(leave);
        _localDataSource.markSynced(leave.leaveId);
      }
      return leaves;
    });
  }

  @override
  Stream<List<LeaveModel>> streamAllLeaves() {
    return _remoteDataSource.streamAllLeaves().map((leaves) {
      for (final leave in leaves) {
        _localDataSource.saveLeave(leave);
        _localDataSource.markSynced(leave.leaveId);
      }
      return leaves;
    });
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  }) async {
    await _localDataSource.updateStatus(leaveId, status, remarks: remarks);
    try {
      await _remoteDataSource.updateLeaveStatus(
        leaveId: leaveId,
        status: status,
        remarks: remarks,
      );
      await _localDataSource.markSynced(leaveId);
    } catch (_) {
      // Saved locally, will sync when online
    }
  }

  @override
  Future<int> syncUnsyncedLeaves() async {
    try {
      final unsynced = await _localDataSource.getUnsyncedLeaves();
      int count = 0;
      for (final leave in unsynced) {
        try {
          await _remoteDataSource.applyLeave(leave);
          await _localDataSource.markSynced(leave.leaveId);
          count++;
        } catch (_) {}
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}
