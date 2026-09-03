import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../leave/domain/entities/leave_approval_request.dart';
import '../../../leave/presentation/pages/leave_detail_page.dart';
import '../../../leave/presentation/providers/leave_approval_service.dart';
import '../../../leave/presentation/widgets/approval_dialogs.dart';

class ApproverDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToRequests;
  final VoidCallback? onNavigateToProfile;

  const ApproverDashboardPage({
    super.key,
    this.onNavigateToRequests,
    this.onNavigateToProfile,
  });

  @override
  State<ApproverDashboardPage> createState() => _ApproverDashboardPageState();
}

class _ApproverDashboardPageState extends State<ApproverDashboardPage> {
  final LeaveApprovalService _service = LeaveApprovalService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _service.refresh();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleApprove(LeaveApprovalRequest req) async {
    final confirmed = await ApprovalDialogs.showApproveConfirmation(
      context,
      request: req,
    );
    if (confirmed == true) {
      await _service.approveRequest(req.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${req.employeeName}\'s leave has been approved'),
            backgroundColor: const Color(0xFF083E2F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleReject(LeaveApprovalRequest req) async {
    final reason = await ApprovalDialogs.showRejectConfirmation(
      context,
      request: req,
    );
    if (reason != null) {
      await _service.rejectRequest(req.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${req.employeeName}\'s leave has been rejected'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequests = _service.pendingRequests;
    final recentActivities = _service.recentActivities;
    final useGridOverview = _service.useGridOverview;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = (authState is AuthAuthenticated) ? authState.user : null;
        final approverName = (user != null && user.name.trim().isNotEmpty)
            ? user.name.trim()
            : 'Approver';
        final initials = approverName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase();

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good Morning,'
            : (hour < 17 ? 'Good Afternoon,' : 'Good Evening,');

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await _service.refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Header (Image 1 & 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              approverName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Approver Dashboard',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Toggle variant preview button
                            IconButton(
                              tooltip: 'Toggle Overview Variant',
                              icon: Icon(
                                useGridOverview ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _service.toggleOverviewVariant();
                              },
                            ),
                            InkWell(
                              onTap: widget.onNavigateToProfile,
                              borderRadius: BorderRadius.circular(20),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF083E2F),
                                child: Text(
                                  initials.isNotEmpty ? initials : 'AP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                const SizedBox(height: 20),

                // 2. Overview Section
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Overview cards (Supports 3 vertical cards from Image 1 or 3-column grid from Image 2)
                if (useGridOverview) _buildGridOverview() else _buildVerticalOverview(),

                const SizedBox(height: 24),

                // 3. Pending Requests Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: widget.onNavigateToRequests,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: const [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF083E2F),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF083E2F),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pending requests cards or Empty State
                if (pendingRequests.isEmpty)
                  _buildNoPendingRequestsCard()
                else
                  ...pendingRequests.take(3).map((req) => _buildPendingRequestCard(req)),

                const SizedBox(height: 24),

                // 4. Recent Activity Section (Image 1 & 2)
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (recentActivities.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border.withAlpha(60)),
                    ),
                    child: const Center(
                      child: Text(
                        'No recent approval or rejection activity',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentActivities.take(5).map((act) => _buildRecentActivityCard(act)),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
}

  /// Vertical overview cards (Image 1)
  Widget _buildVerticalOverview() {
    return Column(
      children: [
        _buildOverviewCard(
          title: 'Pending Leaves',
          count: '${_service.pendingCount}',
          icon: Icons.assignment_outlined,
          iconBgColor: const Color(0xFFEFF4FE),
          iconColor: const Color(0xFF1E40AF),
        ),
        const SizedBox(height: 12),
        _buildOverviewCard(
          title: 'Approved (This Month)',
          count: '${_service.approvedCount}',
          icon: Icons.check_circle_outline_rounded,
          iconBgColor: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF059669),
        ),
        const SizedBox(height: 12),
        _buildOverviewCard(
          title: 'Rejected (This Month)',
          count: '${_service.rejectedCount}',
          icon: Icons.cancel_outlined,
          iconBgColor: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  /// 3-column horizontal grid overview (Image 2)
  Widget _buildGridOverview() {
    return Row(
      children: [
        // Pending
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE6F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_service.pendingCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Approved (Dark green)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF083E2F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_service.approvedCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Approved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Rejected (Light pink)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDADA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_service.rejectedCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rejected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Empty state illustration & message (Image 2)
  Widget _buildNoPendingRequestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFCBDDF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF083E2F),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up! Enjoy a moment of calm before the next wave arrives.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Pending Request Card (Image 1)
  Widget _buildPendingRequestCard(LeaveApprovalRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Leave Type + Duration pill
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaveDetailPage(request: req),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: req.avatarBgColor,
                  child: Text(
                    req.initials,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: req.avatarBgColor == const Color(0xFF083E2F)
                          ? Colors.white
                          : const Color(0xFF083E2F),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        req.leaveType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    req.duration,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Date Range Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF4A5568),
                ),
                const SizedBox(width: 8),
                Text(
                  req.dateRangeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Reject & Approve
          Builder(
            builder: (context) {
              final isLoading = _service.isRequestLoading(req.id);

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _handleReject(req),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC62828), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _handleApprove(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF083E2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Recent Activity Card (Image 1 & 2)
  Widget _buildRecentActivityCard(LeaveApprovalRequest act) {
    final isApproved = act.isApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: act.avatarBgColor,
            child: Text(
              act.initials,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: act.avatarBgColor == const Color(0xFF083E2F)
                    ? Colors.white
                    : const Color(0xFF083E2F),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.employeeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isApproved ? "Approved" : "Rejected"} • ${act.leaveType} (${act.duration})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isApproved ? 'Approved' : 'Rejected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isApproved ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
              if (act.activityTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  act.activityTime!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
