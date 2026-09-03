import '../../data/models/leave_model.dart';

abstract interface class LeaveRepository {
  Future<LeaveModel> applyLeave(LeaveModel model);

  Future<List<LeaveModel>> getUserLeaves(String uid);

  Future<List<LeaveModel>> getAllLeaves();

  Stream<List<LeaveModel>> streamUserLeaves(String uid);

  Stream<List<LeaveModel>> streamAllLeaves();

  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  });

  Future<int> syncUnsyncedLeaves();
}
