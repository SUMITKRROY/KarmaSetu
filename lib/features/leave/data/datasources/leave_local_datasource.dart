import '../../../../core/storage/table/leave_table.dart';
import '../models/leave_model.dart';

abstract interface class LeaveLocalDataSource {
  Future<List<LeaveModel>> getLeavesForUser({
    required String uid,
    bool ascending = false,
  });

  Future<List<LeaveModel>> getAllLeaves({bool ascending = false});

  Future<void> saveLeave(LeaveModel model);

  Future<void> saveLeaveBatch(List<LeaveModel> models);

  Future<LeaveModel?> getLeaveById(String leaveId);

  Future<List<LeaveModel>> getUnsyncedLeaves();

  Future<void> markSynced(String leaveId);

  Future<void> updateStatus(
    String leaveId,
    String status, {
    String? remarks,
  });

  Future<void> deleteLeave(String leaveId);
}

class LeaveLocalDataSourceImpl implements LeaveLocalDataSource {
  final LeaveTable _leaveTable;

  LeaveLocalDataSourceImpl({LeaveTable? leaveTable})
      : _leaveTable = leaveTable ?? LeaveTable();

  @override
  Future<List<LeaveModel>> getLeavesForUser({
    required String uid,
    bool ascending = false,
  }) async {
    final maps = await _leaveTable.getAllForUser(uid, ascending: ascending);
    return maps.map((m) => LeaveModel.fromSqfliteMap(m)).toList();
  }

  @override
  Future<List<LeaveModel>> getAllLeaves({bool ascending = false}) async {
    final maps = await _leaveTable.getAll(ascending: ascending);
    return maps.map((m) => LeaveModel.fromSqfliteMap(m)).toList();
  }

  @override
  Future<void> saveLeave(LeaveModel model) async {
    await _leaveTable.insertOrUpdate(model.toSqfliteMap());
  }

  @override
  Future<void> saveLeaveBatch(List<LeaveModel> models) async {
    final maps = models.map((m) => m.toSqfliteMap()).toList();
    await _leaveTable.insertBatch(maps);
  }

  @override
  Future<LeaveModel?> getLeaveById(String leaveId) async {
    final map = await _leaveTable.getById(leaveId);
    if (map != null) {
      return LeaveModel.fromSqfliteMap(map);
    }
    return null;
  }

  @override
  Future<List<LeaveModel>> getUnsyncedLeaves() async {
    final maps = await _leaveTable.getUnsynced();
    return maps.map((m) => LeaveModel.fromSqfliteMap(m)).toList();
  }

  @override
  Future<void> markSynced(String leaveId) async {
    await _leaveTable.markSynced(leaveId);
  }

  @override
  Future<void> updateStatus(
    String leaveId,
    String status, {
    String? remarks,
  }) async {
    await _leaveTable.updateStatus(leaveId, status, remarks: remarks);
  }

  @override
  Future<void> deleteLeave(String leaveId) async {
    await _leaveTable.delete(leaveId);
  }
}
