import 'package:flutter/material.dart';
import '../../domain/entities/leave_approval_request.dart';

class LeaveApprovalService extends ChangeNotifier {
  static final LeaveApprovalService _instance = LeaveApprovalService._internal();
  factory LeaveApprovalService() => _instance;

  LeaveApprovalService._internal() {
    _initInitialData();
  }

  final List<LeaveApprovalRequest> _allRequests = [];
  final List<LeaveApprovalRequest> _recentActivities = [];

  // Toggle mode for testing alternate overview grid / empty states
  bool _useGridOverview = false;
  bool _forceEmptyPending = false;

  bool get useGridOverview => _useGridOverview;
  bool get forceEmptyPending => _forceEmptyPending;

  List<LeaveApprovalRequest> get allRequests => List.unmodifiable(_allRequests);

  List<LeaveApprovalRequest> get pendingRequests =>
      _forceEmptyPending ? [] : _allRequests.where((r) => r.isPending).toList();

  List<LeaveApprovalRequest> get approvedRequests =>
      _allRequests.where((r) => r.isApproved).toList();

  List<LeaveApprovalRequest> get rejectedRequests =>
      _allRequests.where((r) => r.isRejected).toList();

  List<LeaveApprovalRequest> get recentActivities =>
      List.unmodifiable(_recentActivities);

  int get pendingCount => _forceEmptyPending ? 0 : pendingRequests.length;
  int get approvedCount => 18 + approvedRequests.length;
  int get rejectedCount => 2 + rejectedRequests.length;

  void toggleOverviewVariant() {
    _useGridOverview = !_useGridOverview;
    notifyListeners();
  }

  void toggleEmptyPendingState() {
    _forceEmptyPending = !_forceEmptyPending;
    notifyListeners();
  }

  LeaveApprovalRequest? getRequestById(String id) {
    try {
      return _allRequests.firstWhere((r) => r.id == id);
    } catch (_) {
      try {
        return _recentActivities.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void approveRequest(String id) {
    final index = _allRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _allRequests[index];
      req.status = 'Approved';
      req.rejectionReason = null;

      // Add to recent activities
      _recentActivities.insert(
        0,
        req.copyWith(
          status: 'Approved',
          activityTime: 'Just now',
        ),
      );
      notifyListeners();
    }
  }

  void rejectRequest(String id, String reason) {
    final index = _allRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _allRequests[index];
      req.status = 'Rejected';
      req.rejectionReason = reason.trim().isEmpty ? 'Project deadline conflicts' : reason.trim();

      // Add to recent activities
      _recentActivities.insert(
        0,
        req.copyWith(
          status: 'Rejected',
          rejectionReason: req.rejectionReason,
          activityTime: 'Just now',
        ),
      );
      notifyListeners();
    }
  }

  void resetToMockData() {
    _initInitialData();
    _forceEmptyPending = false;
    notifyListeners();
  }

  void _initInitialData() {
    _allRequests.clear();
    _recentActivities.clear();

    _allRequests.addAll([
      LeaveApprovalRequest(
        id: 'REQ-101',
        employeeName: 'Rahul Sharma',
        employeeId: 'EMP1028',
        designation: 'Software Engineer',
        initials: 'RS',
        avatarBgColor: const Color(0xFFD6E4FF),
        leaveType: 'Casual Leave',
        fromDate: '10 Sep 2026',
        toDate: '11 Sep 2026',
        duration: '2 Days',
        dateRangeText: '10 Sep - 11 Sep',
        reason: 'Personal work requiring travel out of city.',
        status: 'Pending',
        leaveBalance: '8 Days',
      ),
      LeaveApprovalRequest(
        id: 'REQ-102',
        employeeName: 'Sumit Roy',
        employeeId: 'EMP1015',
        designation: 'UI/UX Designer',
        initials: 'SR',
        avatarBgColor: const Color(0xFFFFE7BA),
        leaveType: 'Sick Leave',
        fromDate: '12 Sep 2026',
        toDate: '12 Sep 2026',
        duration: '1 Day',
        dateRangeText: '12 Sep',
        reason: 'Severe viral fever and doctor advised 1 day complete rest.',
        status: 'Pending',
        leaveBalance: '10 Days',
      ),
      LeaveApprovalRequest(
        id: 'REQ-103',
        employeeName: 'Priya Singh',
        employeeId: 'EMP1042',
        designation: 'Product Manager',
        initials: 'PS',
        avatarBgColor: const Color(0xFF083E2F),
        leaveType: 'Annual Leave',
        fromDate: '18 Sep 2026',
        toDate: '20 Sep 2026',
        duration: '3 Days',
        dateRangeText: '18 Sep — 20 Sep',
        reason: 'Family function in hometown.',
        status: 'Pending',
        leaveBalance: '14 Days',
      ),
    ]);

    _recentActivities.addAll([
      LeaveApprovalRequest(
        id: 'REQ-201',
        employeeName: 'Anita Kumar',
        employeeId: 'EMP1008',
        designation: 'Frontend Engineer',
        initials: 'AK',
        avatarBgColor: const Color(0xFF083E2F),
        leaveType: 'Sick Leave',
        fromDate: '02 Sep 2026',
        toDate: '03 Sep 2026',
        duration: '2 days',
        dateRangeText: '02 Sep - 03 Sep',
        reason: 'Medical checkup and recovery.',
        status: 'Approved',
        leaveBalance: '6 Days',
        activityTime: '2 hrs ago',
      ),
      LeaveApprovalRequest(
        id: 'REQ-202',
        employeeName: 'Vikram Desai',
        employeeId: 'EMP1033',
        designation: 'Backend Architect',
        initials: 'VD',
        avatarBgColor: const Color(0xFFD6E4FF),
        leaveType: 'Casual Leave',
        fromDate: '01 Sep 2026',
        toDate: '01 Sep 2026',
        duration: '1 day',
        dateRangeText: '01 Sep',
        reason: 'Urgent personal errand.',
        status: 'Rejected',
        rejectionReason: 'Critical sprint release window',
        leaveBalance: '5 Days',
        activityTime: 'Yesterday',
      ),
      LeaveApprovalRequest(
        id: 'REQ-203',
        employeeName: 'Sneha Mehta',
        employeeId: 'EMP1055',
        designation: 'QA Lead',
        initials: 'SM',
        avatarBgColor: const Color(0xFF083E2F),
        leaveType: 'Privilege Leave',
        fromDate: '12 Oct 2026',
        toDate: '16 Oct 2026',
        duration: '5 days',
        dateRangeText: '12 Oct - 16 Oct',
        reason: 'Annual family vacation.',
        status: 'Approved',
        leaveBalance: '15 Days',
        activityTime: 'Oct 12',
      ),
      LeaveApprovalRequest(
        id: 'REQ-204',
        employeeName: 'Amit Kumar',
        employeeId: 'EMP1019',
        designation: 'DevOps Engineer',
        initials: 'AK',
        avatarBgColor: const Color(0xFFFFD8D8),
        leaveType: 'Casual Leave',
        fromDate: '28 Aug 2026',
        toDate: '28 Aug 2026',
        duration: '1 Day',
        dateRangeText: '28 Aug',
        reason: 'Personal work',
        status: 'Rejected',
        rejectionReason: 'Production deployment scheduled',
        leaveBalance: '7 Days',
        activityTime: '28 Aug 2026',
      ),
    ]);
  }
}
