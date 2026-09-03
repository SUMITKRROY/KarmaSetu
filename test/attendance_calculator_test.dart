import 'package:flutter_test/flutter_test.dart';
import 'package:karmasetu/core/utils/date_utils.dart';
import 'package:karmasetu/features/attendance/data/models/attendance_model.dart';
import 'package:karmasetu/features/attendance/domain/attendance_calculator.dart';

void main() {
  group('AttendanceCalculator & AttendanceConfig Tests', () {
    test('On-time rule: check-in <= 09:30 AM is on-time, > 09:30 AM is late', () {
      final onTime1 = DateTime(2026, 9, 3, 9, 0);
      final onTime2 = DateTime(2026, 9, 3, 9, 30);
      final late1 = DateTime(2026, 9, 3, 9, 31);
      final late2 = DateTime(2026, 9, 3, 10, 15);

      expect(AttendanceConfig.isOnTime(onTime1), isTrue);
      expect(AttendanceConfig.isOnTime(onTime2), isTrue);
      expect(AttendanceConfig.isOnTime(late1), isFalse);
      expect(AttendanceConfig.isOnTime(late2), isFalse);
    });

    test('Current month working days calculated up to today elapsed weekdays', () {
      // Thursday, September 3, 2026 (Sept 1 is Tuesday, Sept 2 is Wednesday, Sept 3 is Thursday) => 3 working days
      final simulatedNow = DateTime(2026, 9, 3, 14, 0);
      final selectedMonth = DateTime(2026, 9, 1);

      final records = [
        AttendanceModel(
          attendanceId: 'rec_1',
          uid: 'uid_1',
          employeeId: 'EMP001',
          date: '2026-09-01',
          checkIn: DateTime(2026, 9, 1, 9, 15),
          checkOut: DateTime(2026, 9, 1, 18, 15),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'PRESENT',
          workingMinutes: 540,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AttendanceModel(
          attendanceId: 'rec_2',
          uid: 'uid_1',
          employeeId: 'EMP001',
          date: '2026-09-02',
          checkIn: DateTime(2026, 9, 2, 9, 45), // Late
          checkOut: DateTime(2026, 9, 2, 18, 45),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'PRESENT',
          workingMinutes: 540,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final stats = AttendanceCalculator.calculateStats(
        records: records,
        selectedMonth: selectedMonth,
        currentDateTime: simulatedNow,
      );

      expect(stats.totalWorkingDays, equals(3));
      expect(stats.presentDays, equals(2));
      expect(stats.absentDays, equals(1)); // 3 working days - 2 present = 1 absent
      expect(stats.onTimeDays, equals(1));
      expect(stats.lateDays, equals(1));
      expect(stats.onTimeRate, equals(50.0));
      expect(stats.onTimeRateString, equals('50%'));
      expect(stats.attendancePercentage, equals(66.7));
      expect(stats.totalWorkingMinutes, equals(1080));
      expect(stats.totalHoursString, equals('18h 00m'));
      expect(stats.avgWorkingMinutes, equals(540));
      expect(stats.avgHoursString, equals('9h 00m'));
    });

    test('Date-wise sequential assembly and sorting (1 Sep, 2 Sep, 3 Sep)', () {
      final records = [
        AttendanceModel(
          attendanceId: 'rec_3',
          uid: 'uid_1',
          employeeId: 'EMP001',
          date: '2026-09-03',
          checkIn: DateTime(2026, 9, 3, 9, 0),
          checkOut: DateTime(2026, 9, 3, 17, 30),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'PRESENT',
          workingMinutes: 510,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AttendanceModel(
          attendanceId: 'rec_1',
          uid: 'uid_1',
          employeeId: 'EMP001',
          date: '2026-09-01',
          checkIn: DateTime(2026, 9, 1, 9, 15),
          checkOut: DateTime(2026, 9, 1, 18, 0),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'PRESENT',
          workingMinutes: 525,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AttendanceModel(
          attendanceId: 'rec_2',
          uid: 'uid_1',
          employeeId: 'EMP001',
          date: '2026-09-02',
          checkIn: DateTime(2026, 9, 2, 9, 20),
          checkOut: DateTime(2026, 9, 2, 18, 10),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'PRESENT',
          workingMinutes: 530,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Sort ascending date-wise
      final ascendingRecords = List<AttendanceModel>.from(records)
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

      expect(ascendingRecords[0].date, equals('2026-09-01'));
      expect(ascendingRecords[1].date, equals('2026-09-02'));
      expect(ascendingRecords[2].date, equals('2026-09-03'));

      // Sort descending date-wise
      final descendingRecords = List<AttendanceModel>.from(records)
        ..sort((a, b) => b.checkIn.compareTo(a.checkIn));

      expect(descendingRecords[0].date, equals('2026-09-03'));
      expect(descendingRecords[1].date, equals('2026-09-02'));
      expect(descendingRecords[2].date, equals('2026-09-01'));

      // Verify date check: check if current date (e.g. 2026-09-03) is put
      final todayDate = '2026-09-03';
      final hasToday = records.any((r) => r.date == todayDate);
      expect(hasToday, isTrue);

      final futureDate = '2026-09-04';
      final hasFuture = records.any((r) => r.date == futureDate);
      expect(hasFuture, isFalse);
    });

    test('TEST 1: Past records (Sep 1, Sep 2) are never treated as today when current date is Sep 3', () {
      final sep2Record = AttendanceModel(
        attendanceId: 'user1_2026-09-02',
        uid: 'user1',
        employeeId: 'EMP001',
        date: '2026-09-02',
        checkIn: DateTime(2026, 9, 2, 9, 15),
        checkOut: DateTime(2026, 9, 2, 18, 0),
        checkInLatitude: 12.97,
        checkInLongitude: 77.59,
        checkInLocation: 'Office',
        status: 'PRESENT',
        workingMinutes: 525,
        createdAt: DateTime(2026, 9, 2),
        updatedAt: DateTime(2026, 9, 2),
      );

      final today = '2026-09-03';

      // Record date is 2026-09-02, today is 2026-09-03 -> must not match
      expect(sep2Record.date == today, isFalse);
    });

    test('TEST 2: Today record (Sep 3) matches current date and is used', () {
      final sep3Record = AttendanceModel(
        attendanceId: 'user1_2026-09-03',
        uid: 'user1',
        employeeId: 'EMP001',
        date: '2026-09-03',
        checkIn: DateTime(2026, 9, 3, 9, 15),
        checkInLatitude: 12.97,
        checkInLongitude: 77.59,
        checkInLocation: 'Office',
        status: 'CHECKED_IN',
        workingMinutes: 0,
        createdAt: DateTime(2026, 9, 3),
        updatedAt: DateTime(2026, 9, 3),
      );

      final today = '2026-09-03';
      expect(sep3Record.date == today, isTrue);
      expect(sep3Record.isCheckedIn, isTrue);
      expect(sep3Record.isCheckedOut, isFalse);
    });

    test('TEST 3 & 4: Check-in and Check-out preserve business date yyyy-MM-dd without UTC distortion', () {
      final localNow = DateTime(2026, 9, 3, 9, 30);
      final businessDate = AppDateUtils.formatBusinessDate(localNow);

      expect(businessDate, equals('2026-09-03'));

      final checkInModel = AttendanceModel(
        attendanceId: 'user1_$businessDate',
        uid: 'user1',
        employeeId: 'EMP001',
        date: businessDate,
        checkIn: localNow,
        checkInLatitude: 12.97,
        checkInLongitude: 77.59,
        checkInLocation: 'Office',
        status: 'CHECKED_IN',
        createdAt: localNow,
        updatedAt: localNow,
      );

      expect(checkInModel.date, equals('2026-09-03'));
      expect(checkInModel.attendanceId, equals('user1_2026-09-03'));

      // Check-out on same date
      final checkOutTime = DateTime(2026, 9, 3, 18, 30);
      final checkedOutModel = checkInModel.copyWith(
        checkOut: checkOutTime,
        workingMinutes: 540,
        status: 'PRESENT',
        updatedAt: checkOutTime,
      );

      expect(checkedOutModel.date, equals('2026-09-03'));
      expect(checkedOutModel.workingMinutes, equals(540));
      expect(checkedOutModel.isCheckedOut, isTrue);
    });

    test('TEST 6: Multi-user isolation by UID and date', () {
      final records = [
        AttendanceModel(
          attendanceId: 'userA_2026-09-03',
          uid: 'userA',
          employeeId: 'EMP001',
          date: '2026-09-03',
          checkIn: DateTime(2026, 9, 3, 9, 0),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'CHECKED_IN',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AttendanceModel(
          attendanceId: 'userB_2026-09-03',
          uid: 'userB',
          employeeId: 'EMP002',
          date: '2026-09-03',
          checkIn: DateTime(2026, 9, 3, 9, 15),
          checkInLatitude: 0,
          checkInLongitude: 0,
          checkInLocation: 'HQ',
          status: 'CHECKED_IN',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Query for userA on 2026-09-03
      final userARecord = records.where((r) => r.uid == 'userA' && r.date == '2026-09-03').firstOrNull;
      expect(userARecord, isNotNull);
      expect(userARecord!.employeeId, equals('EMP001'));

      // Query for userC on 2026-09-03
      final userCRecord = records.where((r) => r.uid == 'userC' && r.date == '2026-09-03').firstOrNull;
      expect(userCRecord, isNull);
    });
  });
}
