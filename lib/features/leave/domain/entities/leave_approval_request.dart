import 'package:flutter/material.dart';

class LeaveApprovalRequest {
  final String id;
  final String employeeName;
  final String employeeId;
  final String designation;
  final String initials;
  final Color avatarBgColor;
  final String? avatarImageUrl;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String duration;
  final String dateRangeText;
  final String reason;
  String status; // 'Pending', 'Approved', 'Rejected'
  final String leaveBalance;
  String? rejectionReason;
  final String? activityTime;

  LeaveApprovalRequest({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.designation,
    required this.initials,
    required this.avatarBgColor,
    this.avatarImageUrl,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.duration,
    required this.dateRangeText,
    required this.reason,
    this.status = 'Pending',
    required this.leaveBalance,
    this.rejectionReason,
    this.activityTime,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  LeaveApprovalRequest copyWith({
    String? status,
    String? rejectionReason,
    String? activityTime,
  }) {
    return LeaveApprovalRequest(
      id: id,
      employeeName: employeeName,
      employeeId: employeeId,
      designation: designation,
      initials: initials,
      avatarBgColor: avatarBgColor,
      avatarImageUrl: avatarImageUrl,
      leaveType: leaveType,
      fromDate: fromDate,
      toDate: toDate,
      duration: duration,
      dateRangeText: dateRangeText,
      reason: reason,
      status: status ?? this.status,
      leaveBalance: leaveBalance,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      activityTime: activityTime ?? this.activityTime,
    );
  }
}
