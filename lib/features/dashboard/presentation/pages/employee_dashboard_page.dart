import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/domain/attendance_calculator.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_event.dart';
import '../../../attendance/presentation/bloc/attendance_state.dart';
import '../../../attendance/presentation/pages/attendance_history_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../leave/presentation/pages/apply_leave_page.dart';
import '../../../leave/presentation/providers/leave_approval_service.dart';

class EmployeeDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToAttendance;
  final VoidCallback? onNavigateToLeaves;
  final VoidCallback? onNavigateToProfile;

  const EmployeeDashboardPage({
    super.key,
    this.onNavigateToAttendance,
    this.onNavigateToLeaves,
    this.onNavigateToProfile,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> with WidgetsBindingObserver {
  final LeaveApprovalService _leaveApprovalService = LeaveApprovalService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _leaveApprovalService.addListener(_onLeaveServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndAttendance();
    });
  }

  void _onLeaveServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _leaveApprovalService.removeListener(_onLeaveServiceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initPermissionsAndAttendance();
    }
  }

  Future<void> _initPermissionsAndAttendance() async {
    // 1. Request permissions on entering dashboard
    await PermissionService.instance.requestDashboardPermissions();

    if (!mounted) return;

    // 2. Fetch today's attendance for authenticated user using current local date
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AttendanceBloc>().add(
            CheckTodayAttendanceRequested(
              uid: authState.user.uid,
              employeeId: authState.user.employeeId,
            ),
          );
      context.read<AttendanceBloc>().add(
            LoadAttendanceHistoryRequested(authState.user.uid),
          );
    }
  }

  void _navigateToAttendance() {
    if (widget.onNavigateToAttendance != null) {
      widget.onNavigateToAttendance!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AttendancePage(isTab: false),
        ),
      );
    }
  }

  void _navigateToAttendanceHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AttendanceHistoryPage(),
      ),
    );
  }

  String _formatTrackedDuration(DateTime checkIn, DateTime? checkOut, int workingMinutes) {
    if (checkOut != null && workingMinutes > 0) {
      final h = workingMinutes ~/ 60;
      final m = workingMinutes % 60;
      return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
    }
    final diff = DateTime.now().difference(checkIn);
    final hours = diff.inHours.clamp(0, 24);
    final minutes = (diff.inMinutes % 60).clamp(0, 59);
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = (authState is AuthAuthenticated) ? authState.user : null;
        final name = user?.name.isNotEmpty == true ? user!.name : 'Test Employee';
        final employeeId = user?.employeeId.isNotEmpty == true ? user!.employeeId : 'EMP001';
        final department = user?.department.isNotEmpty == true ? user!.department : 'Engineering';
        final site = user?.site.isNotEmpty == true ? user!.site : 'Bangalore';
        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        return BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, attendanceState) {
            return Scaffold(
              backgroundColor: const Color(0xFFF7F9FC),
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (user != null) {
                      context.read<AttendanceBloc>().add(
                            CheckTodayAttendanceRequested(
                              uid: user.uid,
                              employeeId: user.employeeId,
                            ),
                          );
                      context.read<AttendanceBloc>().add(
                            LoadAttendanceHistoryRequested(user.uid),
                          );
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Employee Profile Header
                        _buildHeader(name, employeeId, department, site, initials),
                        const SizedBox(height: 20),

                        // 2. Punch Clock / Attendance Hero Card (dynamic from Firestore)
                        _buildAttendancePunchCard(site, attendanceState),
                        const SizedBox(height: 20),

                        // 3. Quick Action Shortcuts
                        _buildQuickActions(),
                        const SizedBox(height: 20),

                        // 4. Monthly Attendance Overview Metrics
                        _buildAttendanceStats(attendanceState),
                        const SizedBox(height: 20),

                        // 5. Leave Balances Summary
                        _buildLeaveBalancesCard(),
                        const SizedBox(height: 20),

                        // 6. Recent Activity Timeline
                        _buildRecentActivity(attendanceState),
                        const SizedBox(height: 20),

                        // 7. Upcoming Holidays Card
                        _buildUpcomingHolidays(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    String name,
    String employeeId,
    String department,
    String site,
    String initials,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onNavigateToProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF8CD4B4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'EM' : initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17211C),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      employeeId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$department • $site',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have no new notifications'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 24, color: AppColors.textPrimary),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE11D48),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendancePunchCard(String site, AttendanceState attendanceState) {
    final today = attendanceState.verifiedTodayAttendance;
    final isCheckedIn = attendanceState.isCheckedIn;
    final isCheckedOut = attendanceState.isCheckedOut;

    String badgeText;
    Color badgeBgColor;
    Color badgeBorderColor;
    Color badgeDotColor;

    if (isCheckedOut) {
      badgeText = 'Shift Completed • Present';
      badgeBgColor = const Color(0xFF10B981).withAlpha(35);
      badgeBorderColor = const Color(0xFF34D399).withAlpha(160);
      badgeDotColor = const Color(0xFF34D399);
    } else if (isCheckedIn) {
      badgeText = 'Punched In (Active)';
      badgeBgColor = const Color(0xFF10B981).withAlpha(40);
      badgeBorderColor = const Color(0xFF34D399);
      badgeDotColor = const Color(0xFF34D399);
    } else {
      badgeText = 'Not Marked Today • Pending';
      badgeBgColor = const Color(0xFFF59E0B).withAlpha(35);
      badgeBorderColor = const Color(0xFFFBBF24).withAlpha(180);
      badgeDotColor = const Color(0xFFFBBF24);
    }

    final punchInTimeStr = today != null ? AppDateUtils.formatDisplayTime(today.checkIn) : '--:--';
    final punchOutTimeStr = (today != null && today.checkOut != null)
        ? AppDateUtils.formatDisplayTime(today.checkOut!)
        : '--:--';
    final workingTimeStr = today != null
        ? _formatTrackedDuration(today.checkIn, today.checkOut, today.workingMinutes)
        : '00h 00m';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF083E2F), Color(0xFF0F5A46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF083E2F).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedOut ? Icons.check_circle_rounded : Icons.circle,
                      size: isCheckedOut ? 11 : 8,
                      color: badgeDotColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    site,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isCheckedOut) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUNCH IN',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      punchInTimeStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withAlpha(40),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUNCH OUT',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      punchOutTimeStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withAlpha(40),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL WORK',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workingTimeStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8CD4B4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PUNCH IN TIME',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      punchInTimeStr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withAlpha(40),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WORKING TIME',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workingTimeStr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8CD4B4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (isCheckedOut)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withAlpha(35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF34D399), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _navigateToAttendanceHistory,
                icon: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
                label: const Text(
                  'Shift Completed • View Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedIn ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _navigateToAttendance,
                icon: Icon(
                  isCheckedIn ? Icons.logout_rounded : Icons.fingerprint,
                  size: 20,
                ),
                label: Text(
                  isCheckedIn ? 'Punch Out Now' : 'Punch In Now',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            icon: Icons.add_circle_outline_rounded,
            label: 'Apply Leave',
            color: const Color(0xFF0F766E),
            bgColor: const Color(0xFFCCFBF1),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            icon: Icons.history_rounded,
            label: 'Attendance',
            color: const Color(0xFF1D4ED8),
            bgColor: const Color(0xFFDBEAFE),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AttendanceHistoryPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            icon: Icons.calendar_month_outlined,
            label: 'My Leaves',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            onTap: widget.onNavigateToLeaves,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats(AttendanceState attendanceState) {
    final now = DateTime.now();
    final currentMonthName = DateFormat('MMMM yyyy').format(now);

    // Merge verified today's attendance into history if not already present
    final historyList = List<AttendanceModel>.from(attendanceState.history);
    final todayRecord = attendanceState.verifiedTodayAttendance;
    if (todayRecord != null) {
      final exists = historyList.any((item) =>
          item.attendanceId == todayRecord.attendanceId ||
          (item.date == todayRecord.date && item.uid == todayRecord.uid));
      if (!exists) {
        historyList.insert(0, todayRecord);
      }
    }

    // Filter strictly for current month & year
    final currentMonthRecords = historyList.where((item) {
      return item.checkIn.year == now.year && item.checkIn.month == now.month;
    }).toList();

    final stats = AttendanceCalculator.calculateStats(
      records: currentMonthRecords,
      selectedMonth: now,
    );

    final daysPresentSubtitle = stats.totalWorkingDays > 0
        ? 'Out of ${stats.totalWorkingDays} working (${stats.attendancePercentageString})'
        : '0 working days elapsed';

    final avgHoursSubtitle = stats.totalWorkingMinutes > 0
        ? 'Total ${stats.totalHoursString} tracked'
        : 'No hours recorded yet';

    final onTimeSubtitle = stats.presentDays > 0
        ? (stats.lateDays == 0 ? 'All entries on time' : '${stats.lateDays} late entries')
        : 'No check-ins yet';

    final leavesSubtitle = stats.absentDays > 0
        ? '${stats.absentDays} leave/absent days'
        : 'No leaves taken';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Month ($currentMonthName)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (attendanceState.isLoadingToday || attendanceState.isLoadingHistory)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Days Present',
                value: '${stats.presentDays}',
                subtitle: daysPresentSubtitle,
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Hours',
                value: stats.avgHoursString,
                subtitle: avgHoursSubtitle,
                icon: Icons.access_time_rounded,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'On-Time Rate',
                value: stats.onTimeRateString,
                subtitle: onTimeSubtitle,
                icon: Icons.speed_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Leaves Taken',
                value: '${stats.absentDays}',
                subtitle: leavesSubtitle,
                icon: Icons.beach_access_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalancesCard() {
    final leaveService = LeaveApprovalService();
    final allRequests = leaveService.allRequests;

    int casualApproved = 0;
    int sickApproved = 0;
    int earnedApproved = 0;

    for (final req in allRequests) {
      if (req.isApproved) {
        final type = req.leaveType.toLowerCase();
        int days = 1;
        final match = RegExp(r'(\d+)').firstMatch(req.duration);
        if (match != null) {
          days = int.tryParse(match.group(1) ?? '1') ?? 1;
        }

        if (type.contains('casual')) {
          casualApproved += days;
        } else if (type.contains('sick')) {
          sickApproved += days;
        } else {
          earnedApproved += days;
        }
      }
    }

    final casualTotal = 12;
    final sickTotal = 10;
    final earnedTotal = 15;

    final casualLeft = (casualTotal - casualApproved).clamp(0, casualTotal);
    final sickLeft = (sickTotal - sickApproved).clamp(0, sickTotal);
    final earnedLeft = (earnedTotal - earnedApproved).clamp(0, earnedTotal);

    return Container(
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
              const Text(
                'Leave Balances',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
                  );
                },
                child: const Text(
                  '+ Apply Leave',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildLeaveTypePill('Casual Leave', '$casualApproved', '$casualLeft left', const Color(0xFF0F766E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLeaveTypePill('Sick Leave', '$sickApproved', '$sickLeft left', const Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLeaveTypePill('Earned Leave', '$earnedApproved', '$earnedLeft left', const Color(0xFFD97706)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypePill(String title, String used, String remaining, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            remaining,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AttendanceState attendanceState) {
    final history = attendanceState.history;
    final today = attendanceState.verifiedTodayAttendance;

    final items = <Widget>[];

    if (today != null) {
      if (today.checkOut != null) {
        items.add(
          _buildTimelineItem(
            time: '${AppDateUtils.formatDisplayTime(today.checkOut!)} • Today',
            title: 'Punched Out (Shift Completed)',
            subtitle: '${today.checkOutLocation ?? 'Office'} • ${today.workingMinutes ~/ 60}h ${today.workingMinutes % 60}m',
            icon: Icons.logout_rounded,
            color: const Color(0xFF6366F1),
            isFirst: true,
          ),
        );
      }
      items.add(
        _buildTimelineItem(
          time: '${AppDateUtils.formatDisplayTime(today.checkIn)} • Today',
          title: 'Punched In (GPS Verified)',
          subtitle: today.checkInLocation.isNotEmpty ? today.checkInLocation : 'Office Campus',
          icon: Icons.login_rounded,
          color: const Color(0xFF10B981),
          isFirst: today.checkOut == null,
          isLast: history.isEmpty,
        ),
      );
    }

    if (history.isNotEmpty) {
      final currentTodayStr = AppDateUtils.getCurrentLocalDate();
      for (int i = 0; i < history.length && i < 3; i++) {
        final item = history[i];
        if (today != null && item.attendanceId == today.attendanceId) continue;
        if (item.date == currentTodayStr) continue;

        final isLastItem = i == history.length - 1 || i == 2;
        final dateStr = AppDateUtils.formatDisplayDate(item.checkIn);
        final checkInStr = AppDateUtils.formatDisplayTime(item.checkIn);

        items.add(
          _buildTimelineItem(
            time: '$checkInStr • $dateStr',
            title: 'Attendance Recorded (${item.status})',
            subtitle: item.checkInLocation.isNotEmpty ? item.checkInLocation : 'Verified Entry',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF3B82F6),
            isFirst: items.isEmpty,
            isLast: isLastItem,
          ),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No recent attendance activity for today.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
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
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AttendanceHistoryPage(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items,
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingHolidays() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.celebration_outlined, color: Color(0xFF047857), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Public Holiday',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ganesh Chaturthi • Friday, Sep 18, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
