import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import 'apply_leave_page.dart';
import 'leave_detail_page.dart';

class LeavePage extends StatefulWidget {
  final bool isTab;
  const LeavePage({super.key, this.isTab = true});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  // Toggle between populated list and empty state
  bool _showEmptyState = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        actions: [
          // Demo toggle between Populated & Empty State
          IconButton(
            tooltip: _showEmptyState ? 'Show Leave Overview' : 'Show Empty State',
            icon: Icon(
              _showEmptyState ? Icons.view_list_rounded : Icons.filter_none_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showEmptyState = !_showEmptyState;
              });
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
        child: _showEmptyState ? _buildEmptyState() : _buildLeaveOverviewContent(),
      ),
    );
  }

  Widget _buildLeaveOverviewContent() {
    return SingleChildScrollView(
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
                  );
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
              _buildStatCard('12', 'Available'),
              const SizedBox(width: 10),
              _buildStatCard('2', 'Pending'),
              const SizedBox(width: 10),
              _buildStatCard('8', 'Approved'),
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
          _buildLeaveRequestCard(
            title: 'Casual Leave',
            dateRange: '03 Sep — 04 Sep',
            duration: '2 Days',
            status: 'Pending',
            statusColor: const Color(0xFFF57F17),
            statusBgColor: const Color(0xFFFFF8E1),
            statusIcon: Icons.access_time_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaveDetailPage(
                    leaveType: 'Casual Leave',
                    duration: '2 Days',
                    fromDate: '10 Sep 2026',
                    toDate: '11 Sep 2026',
                    reason: 'Personal work',
                    status: 'Pending',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildLeaveRequestCard(
            title: 'Annual Leave',
            dateRange: '20 Aug — 22 Aug',
            duration: '3 Days',
            status: 'Approved',
            statusColor: AppColors.primary,
            statusBgColor: const Color(0xFFE8F3EE),
            statusIcon: Icons.check_circle_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaveDetailPage(
                    leaveType: 'Annual Leave',
                    duration: '3 Days',
                    fromDate: '20 Aug 2026',
                    toDate: '22 Aug 2026',
                    reason: 'Family vacation',
                    status: 'Approved',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildLeaveRequestCard(
            title: 'Sick Leave',
            dateRange: '15 Aug',
            duration: '1 Day',
            status: 'Rejected',
            statusColor: AppColors.error,
            statusBgColor: const Color(0xFFFFEBEE),
            statusIcon: Icons.cancel_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaveDetailPage(
                    leaveType: 'Sick Leave',
                    duration: '1 Day',
                    fromDate: '15 Aug 2026',
                    toDate: '15 Aug 2026',
                    reason: 'Viral fever and rest',
                    status: 'Rejected',
                    approverRemarks: 'Leave request could not be approved due to critical project deliverables during this period.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
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

  Widget _buildLeaveRequestCard({
    required String title,
    required String dateRange,
    required String duration,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required IconData statusIcon,
    required VoidCallback onTap,
  }) {
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
              Text(
                title,
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
                      status,
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
                'Duration: $duration',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onTap,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative Illustration matching screenshot
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
                );
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
