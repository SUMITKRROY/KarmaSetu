import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/leave_approval_request.dart';
import '../providers/leave_approval_service.dart';
import '../widgets/approval_dialogs.dart';

class LeaveDetailPage extends StatefulWidget {
  final LeaveApprovalRequest? request;
  final String leaveType;
  final String duration;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final String? approverRemarks;
  final String employeeName;
  final String employeeId;
  final String designation;

  const LeaveDetailPage({
    super.key,
    this.request,
    this.leaveType = 'Casual Leave',
    this.duration = '2 Days',
    this.fromDate = '10 Sep 2026',
    this.toDate = '11 Sep 2026',
    this.reason = 'Personal work requiring travel out of city.',
    this.status = 'Pending',
    this.approverRemarks,
    this.employeeName = 'Rahul Sharma',
    this.employeeId = 'EMP1028',
    this.designation = 'Software Engineer',
  });

  @override
  State<LeaveDetailPage> createState() => _LeaveDetailPageState();
}

class _LeaveDetailPageState extends State<LeaveDetailPage> {
  final LeaveApprovalService _service = LeaveApprovalService();
  late LeaveApprovalRequest _currentRequest;

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _currentRequest = widget.request!;
    } else {
      _currentRequest = LeaveApprovalRequest(
        id: 'REQ-TEMP',
        employeeName: widget.employeeName,
        employeeId: widget.employeeId,
        designation: widget.designation,
        initials: widget.employeeName.isNotEmpty ? widget.employeeName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join() : 'RS',
        avatarBgColor: const Color(0xFFD6E4FF),
        leaveType: widget.leaveType,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        duration: widget.duration,
        dateRangeText: '${widget.fromDate} - ${widget.toDate}',
        reason: widget.reason,
        status: widget.status,
        leaveBalance: '8 Days',
        rejectionReason: widget.approverRemarks,
      );
    }
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    final updated = _service.getRequestById(_currentRequest.id);
    if (updated != null && mounted) {
      setState(() {
        _currentRequest = updated;
      });
    }
  }

  Future<void> _handleApprove() async {
    final confirmed = await ApprovalDialogs.showApproveConfirmation(
      context,
      request: _currentRequest,
    );

    if (confirmed == true && mounted) {
      _service.approveRequest(_currentRequest.id);
      setState(() {
        _currentRequest = _currentRequest.copyWith(status: 'Approved');
      });
    }
  }

  Future<void> _handleReject() async {
    final reason = await ApprovalDialogs.showRejectConfirmation(
      context,
      request: _currentRequest,
    );

    if (reason != null && mounted) {
      _service.rejectRequest(_currentRequest.id, reason);
      setState(() {
        _currentRequest = _currentRequest.copyWith(
          status: 'Rejected',
          rejectionReason: reason,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _currentRequest.isPending;
    final isApproved = _currentRequest.isApproved;
    final isRejected = _currentRequest.isRejected;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF083E2F),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Employee Profile Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: _currentRequest.avatarBgColor,
                    child: Text(
                      _currentRequest.initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _currentRequest.avatarBgColor == const Color(0xFF083E2F)
                            ? Colors.white
                            : const Color(0xFF083E2F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentRequest.employeeName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentRequest.employeeId} • ${_currentRequest.designation}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Main Leave Request Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withAlpha(80)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: "Leave Request" & Calendar icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Leave Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.textSecondary.withAlpha(180),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Status chip
                    _buildStatusChip(),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE), height: 1),
                    const SizedBox(height: 18),

                    // Leave Type
                    const Text(
                      'Leave Type',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRequest.leaveType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Date Row: From Date & To Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentRequest.fromDate,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentRequest.toDate,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Duration chip
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentRequest.duration,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Reason Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5FD),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF88A3DC), width: 3.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${_currentRequest.reason}"',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEEE), height: 1),
                    const SizedBox(height: 16),

                    // Balance & View History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance (${_currentRequest.leaveType})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentRequest.leaveBalance,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            ApprovalDialogs.showLeaveBalanceHistory(
                              context,
                              employeeName: _currentRequest.employeeName,
                              leaveType: _currentRequest.leaveType,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: const [
                                Text(
                                  'View History',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF083E2F),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Color(0xFF083E2F),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Status Feedback Banner if Approved or Rejected (Image 4)
              if (isApproved) ...[
                const LeaveStatusBanner(isApproved: true),
                const SizedBox(height: 24),
              ] else if (isRejected) ...[
                LeaveStatusBanner(
                  isApproved: false,
                  rejectionReason: _currentRequest.rejectionReason,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),

      // 4. Sticky Bottom Action Bar (when Pending)
      bottomNavigationBar: isPending
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Reject Button (Red Outlined with X icon)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleReject,
                      icon: const Icon(Icons.close, color: Color(0xFFC62828), size: 18),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Approve Button (Dark green filled with check icon)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleApprove,
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text(
                        'Approve',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF083E2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildStatusChip() {
    if (_currentRequest.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '• Approved',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    } else if (_currentRequest.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '• Rejected',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC62828),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '• Pending',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
      );
    }
  }
}
