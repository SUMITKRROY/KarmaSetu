import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/leave_repository.dart';
import '../../data/models/leave_model.dart';
import 'leave_event.dart';
import 'leave_state.dart';

export 'leave_event.dart';
export 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveRepository _leaveRepository;

  LeaveBloc({required LeaveRepository leaveRepository})
      : _leaveRepository = leaveRepository,
        super(const LeaveInitial()) {
    on<LeaveLoadRequested>(_onLeaveLoadRequested);
    on<LeaveApplyRequested>(_onLeaveApplyRequested);
    on<LeaveSyncRequested>(_onLeaveSyncRequested);
    on<LeaveStatusUpdateRequested>(_onLeaveStatusUpdateRequested);
  }

  Future<void> _onLeaveStatusUpdateRequested(
    LeaveStatusUpdateRequested event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      await _leaveRepository.updateLeaveStatus(
        leaveId: event.leaveId,
        status: event.status,
        remarks: event.remarks,
      );

      final currentState = state;
      if (currentState is LeaveLoaded) {
        final updatedLeaves = currentState.leaves.map((l) {
          if (l.leaveId == event.leaveId) {
            return l.copyWith(
              status: event.status,
              approverRemarks: event.remarks,
              updatedAt: DateTime.now(),
            );
          }
          return l;
        }).toList();

        _emitLoadedState(updatedLeaves, emit);
      } else if (event.uid != null) {
        final leaves = await _leaveRepository.getUserLeaves(event.uid!);
        _emitLoadedState(leaves, emit);
      }
    } catch (_) {}
  }

  Future<void> _onLeaveLoadRequested(
    LeaveLoadRequested event,
    Emitter<LeaveState> emit,
  ) async {
    emit(const LeaveLoading());
    try {
      final leaves = await _leaveRepository.getUserLeaves(event.uid);
      _emitLoadedState(leaves, emit);
    } catch (e) {
      emit(const LeaveLoaded(leaves: []));
    }
  }

  Future<void> _onLeaveApplyRequested(
    LeaveApplyRequested event,
    Emitter<LeaveState> emit,
  ) async {
    emit(const LeaveApplyInProgress());
    try {
      final createdLeave = await _leaveRepository.applyLeave(event.leave);
      emit(LeaveApplySuccess(createdLeave));
    } catch (e) {
      emit(LeaveApplyFailure(e.toString()));
    }
  }

  Future<void> _onLeaveSyncRequested(
    LeaveSyncRequested event,
    Emitter<LeaveState> emit,
  ) async {
    try {
      await _leaveRepository.syncUnsyncedLeaves();
    } catch (_) {}
  }

  void _emitLoadedState(List<LeaveModel> leaves, Emitter<LeaveState> emit) {
    int pending = 0;
    int approved = 0;

    for (final l in leaves) {
      if (l.isPending) pending++;
      if (l.isApproved) approved++;
    }

    final available = (12 - approved) > 0 ? (12 - approved) : 0;

    emit(LeaveLoaded(
      leaves: leaves,
      availableLeaves: available,
      pendingLeaves: pending,
      approvedLeaves: approved,
    ));
  }
}
