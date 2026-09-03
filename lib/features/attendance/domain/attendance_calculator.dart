import 'dart:math';
import '../data/models/attendance_model.dart';

abstract final class AttendanceConfig {
  static const int expectedCheckInHour = 9;
  static const int expectedCheckInMinute = 30; // 09:30 AM

  static bool isOnTime(DateTime checkInTime) {
    if (checkInTime.hour < expectedCheckInHour) return true;
    if (checkInTime.hour == expectedCheckInHour && checkInTime.minute <= expectedCheckInMinute) {
      return true;
    }
    return false;
  }
}

class MonthlyAttendanceStats {
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int onTimeDays;
  final int lateDays;
  final int totalWorkingMinutes;
  final int avgWorkingMinutes;
  final double onTimeRate;
  final double attendancePercentage;

  const MonthlyAttendanceStats({
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.onTimeDays,
    required this.lateDays,
    required this.totalWorkingMinutes,
    required this.avgWorkingMinutes,
    required this.onTimeRate,
    required this.attendancePercentage,
  });

  String get totalHoursString {
    final h = totalWorkingMinutes ~/ 60;
    final m = totalWorkingMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String get avgHoursString {
    final h = avgWorkingMinutes ~/ 60;
    final m = avgWorkingMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String get onTimeRateString {
    return onTimeRate % 1 == 0 ? '${onTimeRate.toInt()}%' : '${onTimeRate.toStringAsFixed(1)}%';
  }

  String get attendancePercentageString {
    return attendancePercentage % 1 == 0
        ? '${attendancePercentage.toInt()}%'
        : '${attendancePercentage.toStringAsFixed(1)}%';
  }

  factory MonthlyAttendanceStats.empty() {
    return const MonthlyAttendanceStats(
      totalWorkingDays: 0,
      presentDays: 0,
      absentDays: 0,
      onTimeDays: 0,
      lateDays: 0,
      totalWorkingMinutes: 0,
      avgWorkingMinutes: 0,
      onTimeRate: 0.0,
      attendancePercentage: 0.0,
    );
  }
}

class AttendanceCalculator {
  static MonthlyAttendanceStats calculateStats({
    required List<AttendanceModel> records,
    required DateTime selectedMonth,
    DateTime? currentDateTime,
  }) {
    final now = currentDateTime ?? DateTime.now();

    // 1. Calculate working days (Monday-Friday) for selected month
    int totalWorkingDays = 0;

    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final isPastMonth = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    if (isCurrentMonth) {
      // Elapsed weekdays up to today only
      for (int day = 1; day <= now.day; day++) {
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);
        if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
          totalWorkingDays++;
        }
      }
    } else if (isPastMonth) {
      // Full month weekdays
      final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      for (int day = 1; day <= lastDay; day++) {
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);
        if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
          totalWorkingDays++;
        }
      }
    } else {
      // Future month
      totalWorkingDays = 0;
    }

    // 2. Count Present, On-time, Late, Working minutes
    int presentDays = 0;
    int onTimeDays = 0;
    int lateDays = 0;
    int totalWorkingMinutes = 0;

    for (final record in records) {
      // A day is present when record has valid checkIn
      presentDays++;

      if (AttendanceConfig.isOnTime(record.checkIn)) {
        onTimeDays++;
      } else {
        lateDays++;
      }

      int minutes = record.workingMinutes;
      if (minutes <= 0 && record.checkOut != null) {
        minutes = max(0, record.checkOut!.difference(record.checkIn).inMinutes);
      }
      totalWorkingMinutes += minutes;
    }

    // 3. Absent Days = max(0, Working Days - Present Days)
    final absentDays = max(0, totalWorkingDays - presentDays);

    // 4. On-Time Rate = (On-Time Days / Present Days) * 100
    double onTimeRate = 0.0;
    if (presentDays > 0) {
      onTimeRate = (onTimeDays / presentDays) * 100;
      onTimeRate = double.parse(onTimeRate.toStringAsFixed(1));
    }

    // 5. Attendance Percentage = (Present Days / Working Days) * 100
    double attendancePercentage = 0.0;
    if (totalWorkingDays > 0) {
      attendancePercentage = (presentDays / totalWorkingDays) * 100;
      attendancePercentage = double.parse(attendancePercentage.toStringAsFixed(1));
    }

    // 6. Average Working Minutes
    final avgWorkingMinutes = presentDays > 0 ? (totalWorkingMinutes ~/ presentDays) : 0;

    return MonthlyAttendanceStats(
      totalWorkingDays: totalWorkingDays,
      presentDays: presentDays,
      absentDays: absentDays,
      onTimeDays: onTimeDays,
      lateDays: lateDays,
      totalWorkingMinutes: totalWorkingMinutes,
      avgWorkingMinutes: avgWorkingMinutes,
      onTimeRate: onTimeRate,
      attendancePercentage: attendancePercentage,
    );
  }
}
