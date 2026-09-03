import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/leave_model.dart';

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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory LeaveApprovalRequest.fromLeaveModel(LeaveModel model) {
    // Generate initials
    final name = model.employeeName.trim().isNotEmpty ? model.employeeName.trim() : 'Employee';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.isNotEmpty
        ? (parts.length > 1 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0]).toUpperCase()
        : 'EM';

    // Generate stable avatar background color
    final colors = [
      const Color(0xFF083E2F),
      const Color(0xFF1E3A8A),
      const Color(0xFF047857),
      const Color(0xFFB45309),
      const Color(0xFF6D28D9),
      const Color(0xFFBE185D),
    ];
    final colorIndex = name.hashCode.abs() % colors.length;
    final avatarBgColor = colors[colorIndex];

    // Format date range
    String fromFormatted = model.fromDate;
    String toFormatted = model.toDate;
    try {
      final fDt = DateTime.parse(model.fromDate);
      final tDt = DateTime.parse(model.toDate);
      fromFormatted = DateFormat('dd MMM yyyy').format(fDt);
      toFormatted = DateFormat('dd MMM yyyy').format(tDt);
    } catch (_) {}

    final dateRange = model.fromDate == model.toDate
        ? fromFormatted
        : '$fromFormatted - $toFormatted';

    final durationText = '${model.durationInDays} ${model.durationInDays == 1 ? "Day" : "Days"}';

    // Format relative activity time
    final targetTime = model.updatedAt.isAfter(model.createdAt)
        ? model.updatedAt
        : model.createdAt;
    final diff = DateTime.now().difference(targetTime);
    String activityTimeStr = 'Just now';
    if (diff.inSeconds < 60) {
      activityTimeStr = 'Just now';
    } else if (diff.inMinutes < 60) {
      activityTimeStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      activityTimeStr = '${diff.inHours}h ago';
    } else if (diff.inDays < 2) {
      activityTimeStr = 'Yesterday';
    } else if (diff.inDays < 7) {
      activityTimeStr = '${diff.inDays}d ago';
    } else {
      activityTimeStr = DateFormat('dd MMM').format(targetTime);
    }

    return LeaveApprovalRequest(
      id: model.leaveId,
      employeeName: name,
      employeeId: model.employeeId.isNotEmpty ? model.employeeId : 'EMP1001',
      designation: 'Team Member',
      initials: initials,
      avatarBgColor: avatarBgColor,
      leaveType: model.leaveType,
      fromDate: fromFormatted,
      toDate: toFormatted,
      duration: durationText,
      dateRangeText: dateRange,
      reason: model.reason,
      status: model.status,
      leaveBalance: '8 Days',
      rejectionReason: model.approverRemarks,
      activityTime: activityTimeStr,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  LeaveApprovalRequest copyWith({
    String? status,
    String? rejectionReason,
    String? activityTime,
    DateTime? updatedAt,
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
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
