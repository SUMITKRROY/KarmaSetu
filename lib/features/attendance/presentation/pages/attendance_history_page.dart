import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/attendance_calculator.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime _selectedDate = DateTime.now();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String get _currentMonthYear =>
      '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

  bool get _isCurrentOrFutureMonth {
    final now = DateTime.now();
    return (_selectedDate.year > now.year) ||
        (_selectedDate.year == now.year && _selectedDate.month >= now.month);
  }

  @override
  void initState() {
    super.initState();
    _fetchAttendanceForSelectedMonth();
  }

  void _fetchAttendanceForSelectedMonth() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AttendanceBloc>().add(
            LoadMonthAttendanceRequested(
              uid: authState.user.uid,
              month: _selectedDate,
            ),
          );
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _fetchAttendanceForSelectedMonth();
  }

  void _nextMonth() {
    if (_isCurrentOrFutureMonth) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _fetchAttendanceForSelectedMonth();
  }

  Future<void> _openCalendarPicker() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
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
      _fetchAttendanceForSelectedMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        // Filter records strictly matching the selected month and year, sorted date descending
        final history = state.history;
        final filteredHistory = history.where((item) {
          return item.checkIn.year == _selectedDate.year &&
              item.checkIn.month == _selectedDate.month;
        }).toList()
          ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

        final stats = AttendanceCalculator.calculateStats(
          records: filteredHistory,
          selectedMonth: _selectedDate,
        );

        final hasRecords = filteredHistory.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Attendance History'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
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
                                const SizedBox(height: 2),
                                Text(
                                  hasRecords
                                      ? '${stats.presentDays} Days Present • ${stats.attendancePercentageString}'
                                      : '0 Days Recorded',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _isCurrentOrFutureMonth
                                ? AppColors.textSecondary.withAlpha(80)
                                : AppColors.textPrimary,
                          ),
                          onPressed: _isCurrentOrFutureMonth ? null : _nextMonth,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Content: Populated List OR Centered Empty State
                Expanded(
                  child: state.isLoadingHistory
                      ? const Center(child: CircularProgressIndicator())
                      : (hasRecords
                          ? _buildHistoryList(filteredHistory)
                          : _buildCenteredEmptyState()),
                ),
              ],
            ),
          ),
        );
      },
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
            Text(
              'No attendance records found for $_currentMonthYear.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<AttendanceModel> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final dateStr = DateFormat('dd MMM yyyy').format(record.checkIn);
        final dayTag = DateFormat('EEE').format(record.checkIn);
        final checkInStr = DateFormat('hh:mm a').format(record.checkIn);
        final checkOutStr = record.checkOut != null
            ? DateFormat('hh:mm a').format(record.checkOut!)
            : '--:--';

        String? durationStr;
        int durationMinutes = record.workingMinutes;
        if (durationMinutes <= 0 && record.checkOut != null) {
          durationMinutes = record.checkOut!.difference(record.checkIn).inMinutes;
        }

        if (durationMinutes > 0) {
          final h = durationMinutes ~/ 60;
          final m = durationMinutes % 60;
          durationStr = '${h}h ${m.toString().padLeft(2, '0')}m';
        }

        final isCompleted = record.checkOut != null;
        final isOnTime = AttendanceConfig.isOnTime(record.checkIn);

        String status;
        Color statusColor;
        Color statusBgColor;
        IconData statusIcon;
        Color accentColor;

        if (isCompleted) {
          if (isOnTime) {
            status = 'Present';
            statusColor = AppColors.primary;
            statusBgColor = const Color(0xFFE8F3EE);
            statusIcon = Icons.check_circle_outline;
            accentColor = const Color(0xFF2E7D32);
          } else {
            status = 'Late';
            statusColor = const Color(0xFFD97706);
            statusBgColor = const Color(0xFFFEF3C7);
            statusIcon = Icons.access_time_rounded;
            accentColor = const Color(0xFFD97706);
          }
        } else {
          status = 'Checked In';
          statusColor = const Color(0xFF1976D2);
          statusBgColor = const Color(0xFFE3F2FD);
          statusIcon = Icons.access_time_rounded;
          accentColor = const Color(0xFF00695C);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildHistoryCard(
            date: dateStr,
            dayTag: dayTag,
            status: status,
            statusColor: statusColor,
            statusBgColor: statusBgColor,
            statusIcon: statusIcon,
            checkIn: checkInStr,
            checkOut: checkOutStr,
            duration: durationStr,
            location: record.checkInLocation.isNotEmpty ? record.checkInLocation : null,
            accentColor: accentColor,
          ),
        );
      },
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
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
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
