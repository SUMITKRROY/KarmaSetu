import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils.dart';

class AttendanceModel {
  final String attendanceId;
  final String uid;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final DateTime checkIn;
  final DateTime? checkOut;
  final double checkInLatitude;
  final double checkInLongitude;
  final String checkInLocation;
  final String? checkInSelfie;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutLocation;
  final String? checkOutSelfie;
  final String status; // 'PRESENT', 'CHECKED_IN', 'CHECKED_OUT', 'HALF_DAY', etc.
  final int workingMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const AttendanceModel({
    required this.attendanceId,
    required this.uid,
    required this.employeeId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.checkInLocation,
    this.checkInSelfie,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutLocation,
    this.checkOutSelfie,
    required this.status,
    this.workingMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  bool get isCheckedIn => checkOut == null;
  bool get isCheckedOut => checkOut != null;

  AttendanceModel copyWith({
    String? attendanceId,
    String? uid,
    String? employeeId,
    String? date,
    DateTime? checkIn,
    DateTime? checkOut,
    double? checkInLatitude,
    double? checkInLongitude,
    String? checkInLocation,
    String? checkInSelfie,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkOutLocation,
    String? checkOutSelfie,
    String? status,
    int? workingMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkInSelfie: checkInSelfie ?? this.checkInSelfie,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkOutSelfie: checkOutSelfie ?? this.checkOutSelfie,
      status: status ?? this.status,
      workingMinutes: workingMinutes ?? this.workingMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'attendanceId': attendanceId,
      'uid': uid,
      'employeeId': employeeId,
      'date': date,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInLocation': checkInLocation,
      'checkInSelfie': checkInSelfie,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutLocation': checkOutLocation,
      'checkOutSelfie': checkOutSelfie,
      'status': status,
      'workingMinutes': workingMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AttendanceModel.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    DateTime parseDate(dynamic val, DateTime defaultVal) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? defaultVal;
      if (val is DateTime) return val;
      return defaultVal;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is DateTime) return val;
      return null;
    }

    final now = DateTime.now();

    return AttendanceModel(
      attendanceId: data['attendanceId'] as String? ?? docId ?? '',
      uid: data['uid'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      checkIn: parseDate(data['checkIn'], now),
      checkOut: parseNullableDate(data['checkOut']),
      checkInLatitude: (data['checkInLatitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (data['checkInLongitude'] as num?)?.toDouble() ?? 0.0,
      checkInLocation: data['checkInLocation'] as String? ?? '',
      checkInSelfie: data['checkInSelfie'] as String?,
      checkOutLatitude: (data['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (data['checkOutLongitude'] as num?)?.toDouble(),
      checkOutLocation: data['checkOutLocation'] as String?,
      checkOutSelfie: data['checkOutSelfie'] as String?,
      status: data['status'] as String? ?? 'PRESENT',
      workingMinutes: (data['workingMinutes'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt'], now),
      updatedAt: parseDate(data['updatedAt'], now),
      isSynced: true,
    );
  }

  Map<String, dynamic> toSqfliteMap({int? isSynced, String syncError = ''}) {
    return {
      'attendanceId': attendanceId,
      'uid': uid,
      'employeeId': employeeId,
      'date': date,
      'checkIn': checkIn.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInLocation': checkInLocation,
      'checkInSelfie': checkInSelfie ?? '',
      'checkOut': checkOut?.toIso8601String() ?? '',
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutLocation': checkOutLocation ?? '',
      'checkOutSelfie': checkOutSelfie ?? '',
      'status': status,
      'workingMinutes': workingMinutes,
      'isSynced': isSynced ?? (this.isSynced ? 1 : 0),
      'syncError': syncError,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromSqfliteMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime defaultVal) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? defaultVal;
      }
      return defaultVal;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    final now = DateTime.now();

    return AttendanceModel(
      attendanceId: map['attendanceId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      checkIn: parseDate(map['checkIn'], now),
      checkOut: parseNullableDate(map['checkOut']),
      checkInLatitude: (map['checkInLatitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (map['checkInLongitude'] as num?)?.toDouble() ?? 0.0,
      checkInLocation: map['checkInLocation'] as String? ?? '',
      checkInSelfie: (map['checkInSelfie'] as String?)?.isNotEmpty == true ? map['checkInSelfie'] as String : null,
      checkOutLatitude: (map['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (map['checkOutLongitude'] as num?)?.toDouble(),
      checkOutLocation: (map['checkOutLocation'] as String?)?.isNotEmpty == true ? map['checkOutLocation'] as String : null,
      checkOutSelfie: (map['checkOutSelfie'] as String?)?.isNotEmpty == true ? map['checkOutSelfie'] as String : null,
      status: map['status'] as String? ?? 'PRESENT',
      workingMinutes: (map['workingMinutes'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
    );
  }

  static String formatDate(DateTime dt) {
    return AppDateUtils.formatBusinessDate(dt);
  }
}
