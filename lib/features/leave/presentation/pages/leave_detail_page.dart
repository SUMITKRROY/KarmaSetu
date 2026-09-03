import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/leave_approval_request.dart';
import '../providers/leave_approval_service.dart';
import '../widgets/approval_dialogs.dart';

class LeaveDetailPage extends StatefulWidget {
  final LeaveApprovalRequest? request;
  final String? leaveId;
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
    this.leaveId,
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
        id: widget.leaveId ?? 'REQ-TEMP',
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

  bool _isActionInProgress = false;

  void _onServiceChanged() {
    final updated = _service.getRequestById(_currentRequest.id);
    if (updated != null && mounted) {
      setState(() {
        _currentRequest = updated;
      });
    }
  }

  Future<void> _handleWithdraw() async {
    if (_isActionInProgress) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FE),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFC62828),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Withdraw Leave Request?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to withdraw your ${_currentRequest.leaveType} request for ${_currentRequest.duration} (${_currentRequest.fromDate})?',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(64, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isActionInProgress = true;
      });
      await _service.withdrawRequest(_currentRequest.id);
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _currentRequest = _currentRequest.copyWith(
            status: 'Withdrawn',
            rejectionReason: 'Withdrawn by employee',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your leave request has been withdrawn'),
            backgroundColor: Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleApprove() async {
    if (_isActionInProgress) return;
    final confirmed = await ApprovalDialogs.showApproveConfirmation(
      context,
      request: _currentRequest,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isActionInProgress = true;
      });
      await _service.approveRequest(_currentRequest.id);
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _currentRequest = _currentRequest.copyWith(status: 'Approved');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentRequest.employeeName}\'s leave has been approved'),
            backgroundColor: const Color(0xFF083E2F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    if (_isActionInProgress) return;
    final reason = await ApprovalDialogs.showRejectConfirmation(
      context,
      request: _currentRequest,
    );

    if (reason != null && mounted) {
      setState(() {
        _isActionInProgress = true;
      });
      await _service.rejectRequest(_currentRequest.id, reason);
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
          _currentRequest = _currentRequest.copyWith(
            status: 'Rejected',
            rejectionReason: reason,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentRequest.employeeName}\'s leave has been rejected'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _currentRequest.isPending;
    final isApproved = _currentRequest.isApproved;
    final isRejected = _currentRequest.isRejected;
    final isWithdrawn = _currentRequest.status.toLowerCase() == 'withdrawn';

    final authState = context.read<AuthBloc>().state;
    final currentUser = (authState is AuthAuthenticated) ? authState.user : null;
    final isApprover = currentUser?.isApprover ?? false;

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
                    const SizedBox(height: 18),

                    // Attachments Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ATTACHMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD6E4FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.attach_file,
                                size: 16,
                                color: Color(0xFF1E5BB5),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'medical_certificate.pdf',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E5BB5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Row 5: Current Leave Balance & View History Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT BALANCE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentRequest.leaveBalance,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            ApprovalDialogs.showLeaveBalanceHistory(
                              context,
                              employeeName: _currentRequest.employeeName,
                              leaveType: _currentRequest.leaveType,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Text(
                                  'View History',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E5BB5),
                                  ),
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

              // 3. Status Feedback Banner if Approved, Rejected, or Withdrawn (Image 4)
              if (isWithdrawn) ...[
                const LeaveStatusBanner(isApproved: false, isWithdrawn: true),
                const SizedBox(height: 24),
              ] else if (isApproved) ...[
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
              child: isApprover
                  ? Row(
                      children: [
                        // Reject Button (Red Outlined with X icon)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isActionInProgress ? null : _handleReject,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.close, color: Color(0xFFC62828), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Approve Button (Dark green filled with check icon)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isActionInProgress ? null : _handleApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF083E2F),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isActionInProgress
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check, color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Approve',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isActionInProgress ? null : _handleWithdraw,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC62828), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isActionInProgress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFC62828),
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.remove_circle_outline, color: Color(0xFFC62828), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Withdraw Request',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFC62828),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
            )
          : null,
    );
  }

  Widget _buildStatusChip() {
    if (_currentRequest.status.toLowerCase() == 'withdrawn') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '• Withdrawn',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      );
    } else if (_currentRequest.isApproved) {
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
