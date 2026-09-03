import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/leave_model.dart';
import '../../domain/entities/leave_approval_request.dart';
import '../bloc/leave_bloc.dart';
import 'apply_leave_page.dart';
import 'leave_detail_page.dart';

class LeavePage extends StatefulWidget {
  final bool isTab;
  const LeavePage({super.key, this.isTab = true});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  @override
  void initState() {
    super.initState();
    _loadUserLeaves();
  }

  void _loadUserLeaves() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<LeaveBloc>().add(LeaveLoadRequested(uid: authState.user.uid));
    } else {
      context.read<LeaveBloc>().add(const LeaveLoadRequested(uid: 'guest_user'));
    }
  }

  String _formatDateDisplay(String dbDate) {
    try {
      final dt = DateTime.parse(dbDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]}';
    } catch (_) {
      return dbDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Management'),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        actions: [
          IconButton(
            tooltip: 'Sync Leaves',
            icon: const Icon(Icons.sync_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: () {
              context.read<LeaveBloc>().add(const LeaveSyncRequested());
              _loadUserLeaves();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<LeaveBloc, LeaveState>(
          builder: (context, state) {
            if (state is LeaveLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is LeaveLoaded) {
              if (state.leaves.isEmpty) {
                return _buildEmptyState();
              }
              return _buildLeaveOverviewContent(state);
            }

            return _buildEmptyState();
          },
        ),
      ),
    );
  }

  Widget _buildLeaveOverviewContent(LeaveLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadUserLeaves();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Leave Overview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Leave Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
                    );
                    if (result == true) {
                      _loadUserLeaves();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. 3 Stat Cards Row
            Row(
              children: [
                _buildStatCard('${state.availableLeaves}', 'Available'),
                const SizedBox(width: 10),
                _buildStatCard('${state.pendingLeaves}', 'Pending'),
                const SizedBox(width: 10),
                _buildStatCard('${state.approvedLeaves}', 'Approved'),
              ],
            ),
            const SizedBox(height: 24),

            // 3. My Leave Requests Section
            const Text(
              'My Leave Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Request Cards List
            ...state.leaves.map((leave) => _buildLeaveModelCard(leave)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveModelCard(LeaveModel leave) {
    final fromDisplay = _formatDateDisplay(leave.fromDate);
    final toDisplay = _formatDateDisplay(leave.toDate);
    final dateRange = leave.fromDate == leave.toDate
        ? fromDisplay
        : '$fromDisplay — $toDisplay';

    final durationText = '${leave.durationInDays} ${leave.durationInDays == 1 ? "Day" : "Days"}';

    Color statusColor = const Color(0xFFF57F17);
    Color statusBgColor = const Color(0xFFFFF8E1);
    IconData statusIcon = Icons.access_time_rounded;

    if (leave.isApproved) {
      statusColor = AppColors.primary;
      statusBgColor = const Color(0xFFE8F3EE);
      statusIcon = Icons.check_circle_outline;
    } else if (leave.isRejected) {
      statusColor = AppColors.error;
      statusBgColor = const Color(0xFFFFEBEE);
      statusIcon = Icons.cancel_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.leaveType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        leave.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration: $durationText',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeaveDetailPage(
                          request: LeaveApprovalRequest.fromLeaveModel(leave),
                          leaveId: leave.leaveId,
                          leaveType: leave.leaveType,
                          duration: durationText,
                          fromDate: leave.fromDate,
                          toDate: leave.toDate,
                          reason: leave.reason,
                          status: leave.status,
                          approverRemarks: leave.approverRemarks,
                          employeeName: leave.employeeName,
                          employeeId: leave.employeeId,
                        ),
                      ),
                    );
                    if (mounted) {
                      _loadUserLeaves();
                    }
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF4FE).withAlpha(160),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCE5FC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flight_takeoff_rounded, size: 14, color: Color(0xFF3355A6)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B5D3B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_outlined, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Leave Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You haven\'t submitted any leave requests\nyet. Is it time for a well-deserved break?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
                );
                if (result == true) {
                  _loadUserLeaves();
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Apply Leave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

