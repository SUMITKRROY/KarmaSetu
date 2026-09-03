import 'package:flutter/foundation.dart';
import '../../data/models/leave_model.dart';

@immutable
sealed class LeaveEvent {
  const LeaveEvent();
}

final class LeaveLoadRequested extends LeaveEvent {
  final String uid;

  const LeaveLoadRequested({required this.uid});
}

final class LeaveApplyRequested extends LeaveEvent {
  final LeaveModel leave;

  const LeaveApplyRequested(this.leave);
}

final class LeaveSyncRequested extends LeaveEvent {
  const LeaveSyncRequested();
}

final class LeaveStatusUpdateRequested extends LeaveEvent {
  final String leaveId;
  final String status;
  final String? remarks;
  final String? uid;

  const LeaveStatusUpdateRequested({
    required this.leaveId,
    required this.status,
    this.remarks,
    this.uid,
  });
}
