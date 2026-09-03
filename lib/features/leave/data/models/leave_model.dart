import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String leaveId;
  final String uid;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final String fromDate; // YYYY-MM-DD or MM/DD/YYYY
  final String toDate; // YYYY-MM-DD or MM/DD/YYYY
  final int durationInDays;
  final String reason;
  final String? documentUrl;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? approverRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveModel({
    required this.leaveId,
    required this.uid,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.durationInDays,
    required this.reason,
    this.documentUrl,
    this.status = 'Pending',
    this.approverRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  LeaveModel copyWith({
    String? leaveId,
    String? uid,
    String? employeeId,
    String? employeeName,
    String? leaveType,
    String? fromDate,
    String? toDate,
    int? durationInDays,
    String? reason,
    String? documentUrl,
    String? status,
    String? approverRemarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveModel(
      leaveId: leaveId ?? this.leaveId,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      leaveType: leaveType ?? this.leaveType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      durationInDays: durationInDays ?? this.durationInDays,
      reason: reason ?? this.reason,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      approverRemarks: approverRemarks ?? this.approverRemarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leaveId': leaveId,
      'uid': uid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'fromDate': fromDate,
      'toDate': toDate,
      'durationInDays': durationInDays,
      'reason': reason,
      'documentUrl': documentUrl ?? '',
      'status': status,
      'approverRemarks': approverRemarks ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LeaveModel.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    DateTime parseDate(dynamic val, DateTime defaultVal) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? defaultVal;
      if (val is DateTime) return val;
      return defaultVal;
    }

    final now = DateTime.now();

    return LeaveModel(
      leaveId: data['leaveId'] as String? ?? docId ?? '',
      uid: data['uid'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? '',
      leaveType: data['leaveType'] as String? ?? 'Casual Leave',
      fromDate: data['fromDate'] as String? ?? '',
      toDate: data['toDate'] as String? ?? '',
      durationInDays: (data['durationInDays'] as num?)?.toInt() ?? 1,
      reason: data['reason'] as String? ?? '',
      documentUrl: (data['documentUrl'] as String?)?.isNotEmpty == true
          ? data['documentUrl'] as String
          : null,
      status: data['status'] as String? ?? 'Pending',
      approverRemarks: (data['approverRemarks'] as String?)?.isNotEmpty == true
          ? data['approverRemarks'] as String
          : null,
      createdAt: parseDate(data['createdAt'], now),
      updatedAt: parseDate(data['updatedAt'], now),
    );
  }

  Map<String, dynamic> toSqfliteMap({int isSynced = 0, String syncError = ''}) {
    return {
      'leaveId': leaveId,
      'uid': uid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'fromDate': fromDate,
      'toDate': toDate,
      'durationInDays': durationInDays,
      'reason': reason,
      'documentUrl': documentUrl ?? '',
      'status': status,
      'approverRemarks': approverRemarks ?? '',
      'isSynced': isSynced,
      'syncError': syncError,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LeaveModel.fromSqfliteMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime defaultVal) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? defaultVal;
      }
      return defaultVal;
    }

    final now = DateTime.now();

    return LeaveModel(
      leaveId: map['leaveId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      leaveType: map['leaveType'] as String? ?? 'Casual Leave',
      fromDate: map['fromDate'] as String? ?? '',
      toDate: map['toDate'] as String? ?? '',
      durationInDays: (map['durationInDays'] as num?)?.toInt() ?? 1,
      reason: map['reason'] as String? ?? '',
      documentUrl: (map['documentUrl'] as String?)?.isNotEmpty == true
          ? map['documentUrl'] as String
          : null,
      status: map['status'] as String? ?? 'Pending',
      approverRemarks: (map['approverRemarks'] as String?)?.isNotEmpty == true
          ? map['approverRemarks'] as String
          : null,
      createdAt: parseDate(map['createdAt'], now),
      updatedAt: parseDate(map['updatedAt'], now),
    );
  }
}
