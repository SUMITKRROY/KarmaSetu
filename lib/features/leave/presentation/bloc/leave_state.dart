import 'package:flutter/foundation.dart';
import '../../data/models/leave_model.dart';

@immutable
sealed class LeaveState {
  const LeaveState();
}

final class LeaveInitial extends LeaveState {
  const LeaveInitial();
}

final class LeaveLoading extends LeaveState {
  const LeaveLoading();
}

final class LeaveLoaded extends LeaveState {
  final List<LeaveModel> leaves;
  final int availableLeaves;
  final int pendingLeaves;
  final int approvedLeaves;

  const LeaveLoaded({
    required this.leaves,
    this.availableLeaves = 12,
    this.pendingLeaves = 0,
    this.approvedLeaves = 0,
  });
}

final class LeaveApplyInProgress extends LeaveState {
  const LeaveApplyInProgress();
}

final class LeaveApplySuccess extends LeaveState {
  final LeaveModel leave;

  const LeaveApplySuccess(this.leave);
}

final class LeaveApplyFailure extends LeaveState {
  final String error;

  const LeaveApplyFailure(this.error);
}
