import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime _selectedDate = DateTime(2026, 9, 1);

  // Month names
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String get _currentMonthYear =>
      '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

  bool get _hasRecords => _selectedDate.month == 9 && _selectedDate.year == 2026;

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  Future<void> _openCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2028, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
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
        child: Column(
          children: [
            // 1. Month Selector Bar with Calendar trigger
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withAlpha(80)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                      onPressed: _previousMonth,
                    ),
                    InkWell(
                      onTap: _openCalendarPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _currentMonthYear,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (!_hasRecords) ...[
                              const SizedBox(height: 2),
                              const Text(
                                '0 Days Present',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Content: Populated List OR Centered Empty State
            Expanded(
              child: _hasRecords ? _buildHistoryList() : _buildCenteredEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative circular illustration
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
                Positioned(
                  top: 12,
                  right: 22,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8CD4B4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  left: 20,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB5EAD7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE5FC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 38,
                    color: Color(0xFF3355A6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'No attendance records',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'No attendance records found for this\nmonth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Request Update Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Attendance update requested for $_currentMonthYear!'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Request Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(190, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildHistoryCard(
          date: '03 Sep 2026',
          dayTag: 'Thu',
          status: 'Present',
          statusColor: AppColors.primary,
          statusBgColor: const Color(0xFFE8F3EE),
          statusIcon: Icons.check_circle_outline,
          checkIn: '09:42 AM',
          checkOut: '06:18 PM',
          duration: '8h 36m',
          location: 'Bangalore Office',
          accentColor: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 14),
        _buildHistoryCard(
          date: '02 Sep 2026',
          dayTag: 'Wed',
          status: 'Present',
          statusColor: AppColors.primary,
          statusBgColor: const Color(0xFFE8F3EE),
          statusIcon: Icons.check_circle_outline,
          checkIn: '09:38 AM',
          checkOut: '06:11 PM',
          duration: '8h 33m',
          location: 'Bangalore Office',
          accentColor: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 14),
        _buildHistoryCard(
          date: '01 Sep 2026',
          dayTag: 'Tue',
          status: 'Checked In',
          statusColor: const Color(0xFF1976D2),
          statusBgColor: const Color(0xFFE3F2FD),
          statusIcon: Icons.access_time_rounded,
          checkIn: '09:51 AM',
          checkOut: '--:--',
          duration: null,
          location: 'Bangalore Office',
          accentColor: const Color(0xFF00695C),
        ),
        const SizedBox(height: 14),
        _buildHistoryCard(
          date: '31 Aug 2026',
          dayTag: 'Mon',
          status: 'Absent',
          statusColor: AppColors.error,
          statusBgColor: const Color(0xFFFFEBEE),
          statusIcon: Icons.cancel_outlined,
          checkIn: '--:--',
          checkOut: '--:--',
          duration: null,
          location: null,
          accentColor: AppColors.error,
        ),
        const SizedBox(height: 14),
        _buildHistoryCard(
          date: '30 Aug 2026',
          dayTag: 'Sun',
          status: 'Leave',
          statusColor: const Color(0xFF5E35B1),
          statusBgColor: const Color(0xFFEDE7F6),
          statusIcon: Icons.flight_takeoff_rounded,
          checkIn: '--:--',
          checkOut: '--:--',
          duration: null,
          location: null,
          accentColor: const Color(0xFF9E9E9E),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String date,
    required String dayTag,
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required IconData statusIcon,
    required String checkIn,
    required String checkOut,
    required String? duration,
    required String? location,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          // Top Row: Date, Day, Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dayTag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3355A6),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
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
          const SizedBox(height: 14),

          // Time duration row
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.login_rounded, size: 16, color: Color(0xFF8CD4B4)),
                  const SizedBox(width: 4),
                  Text(
                    checkIn,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: AppColors.border,
                        thickness: 1,
                      ),
                    ),
                    if (duration != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border.withAlpha(100)),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AppColors.border,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    checkOut,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),

          if (location != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  ),
],
),
),
),
);
}
}
