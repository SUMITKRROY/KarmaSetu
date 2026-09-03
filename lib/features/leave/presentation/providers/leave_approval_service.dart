import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/leave_local_datasource.dart';
import '../../data/datasources/leave_remote_datasource.dart';
import '../../data/models/leave_model.dart';
import '../../data/repositories/leave_repository_impl.dart';
import '../../domain/entities/leave_approval_request.dart';
import '../../domain/repositories/leave_repository.dart';

class LeaveApprovalService extends ChangeNotifier {
  static final LeaveApprovalService _instance = LeaveApprovalService._internal();
  factory LeaveApprovalService({LeaveRepository? repository}) {
    if (repository != null) {
      _instance._repository = repository;
    }
    return _instance;
  }

  LeaveRepository _repository;
  StreamSubscription<List<LeaveModel>>? _leavesSubscription;

  LeaveApprovalService._internal()
      : _repository = LeaveRepositoryImpl(
          remoteDataSource: LeaveRemoteDataSourceImpl(),
          localDataSource: LeaveLocalDataSourceImpl(),
        ) {
    _initData();
  }

  final List<LeaveApprovalRequest> _allRequests = [];
  final List<LeaveApprovalRequest> _recentActivities = [];
  final Set<String> _loadingRequestIds = {};
  bool _isLoading = false;

  // Toggle mode for overview grid
  bool _useGridOverview = false;
  bool _forceEmptyPending = false;

  bool get isLoading => _isLoading;
  bool isRequestLoading(String id) => _loadingRequestIds.contains(id);
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
  int get approvedCount => approvedRequests.length;
  int get rejectedCount => rejectedRequests.length;

  void toggleOverviewVariant() {
    _useGridOverview = !_useGridOverview;
    notifyListeners();
  }

  void toggleEmptyPendingState() {
    _forceEmptyPending = !_forceEmptyPending;
    notifyListeners();
  }

  void _initData() {
    _loadFromRepository();
    _subscribeToLeavesStream();
  }

  void _subscribeToLeavesStream() {
    _leavesSubscription?.cancel();
    _leavesSubscription = _repository.streamAllLeaves().listen(
      (leaves) {
        _processLeaves(leaves);
      },
      onError: (_) {
        // Fallback to local fetch if stream encounters error
        _loadFromRepository();
      },
    );
  }

  Future<void> _loadFromRepository() async {
    _isLoading = true;
    notifyListeners();
    try {
      final leaves = await _repository.getAllLeaves();
      _processLeaves(leaves);
    } catch (_) {
      // If repository fails, keep current items
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processLeaves(List<LeaveModel> leaves) {
    _allRequests.clear();
    _recentActivities.clear();

    if (leaves.isEmpty) {
      // If database has no leaves yet, populate initial sample data
      _populateMockFallback();
      notifyListeners();
      return;
    }

    for (final model in leaves) {
      final request = LeaveApprovalRequest.fromLeaveModel(model);
      _allRequests.add(request);

      // If approved or rejected, add to recent activities
      if (request.isApproved || request.isRejected) {
        _recentActivities.add(request);
      }
    }

    // Sort all requests: pending first, then by date descending
    _allRequests.sort((a, b) {
      if (a.isPending && !b.isPending) return -1;
      if (!a.isPending && b.isPending) return 1;
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime.now();
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    // Sort recent activities by most recently updated/created
    _recentActivities.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime.now();
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

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

  Future<void> approveRequest(String id) async {
    _loadingRequestIds.add(id);
    notifyListeners();

    final index = _allRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _allRequests[index];
      req.status = 'Approved';
      req.rejectionReason = null;

      // Update in recent activities
      _recentActivities.removeWhere((r) => r.id == id);
      _recentActivities.insert(
        0,
        req.copyWith(
          status: 'Approved',
          activityTime: 'Just now',
          updatedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }

    // Persist to repository (Firestore + SQLite)
    try {
      await _repository.updateLeaveStatus(
        leaveId: id,
        status: 'Approved',
      );
    } catch (_) {} finally {
      _loadingRequestIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String id, String reason) async {
    final trimmedReason = reason.trim().isEmpty ? 'Project deadline conflicts' : reason.trim();
    _loadingRequestIds.add(id);
    notifyListeners();

    final index = _allRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _allRequests[index];
      req.status = 'Rejected';
      req.rejectionReason = trimmedReason;

      // Update in recent activities
      _recentActivities.removeWhere((r) => r.id == id);
      _recentActivities.insert(
        0,
        req.copyWith(
          status: 'Rejected',
          rejectionReason: trimmedReason,
          activityTime: 'Just now',
          updatedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }

    // Persist to repository (Firestore + SQLite)
    try {
      await _repository.updateLeaveStatus(
        leaveId: id,
        status: 'Rejected',
        remarks: trimmedReason,
      );
    } catch (_) {} finally {
      _loadingRequestIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> withdrawRequest(String id) async {
    _loadingRequestIds.add(id);
    notifyListeners();

    final index = _allRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _allRequests[index];
      req.status = 'Withdrawn';
      req.rejectionReason = 'Withdrawn by employee';

      // Update in recent activities
      _recentActivities.removeWhere((r) => r.id == id);
      _recentActivities.insert(
        0,
        req.copyWith(
          status: 'Withdrawn',
          rejectionReason: 'Withdrawn by employee',
          activityTime: 'Just now',
          updatedAt: DateTime.now(),
        ),
      );
      notifyListeners();
    }

    // Persist to repository (Firestore + SQLite)
    try {
      await _repository.updateLeaveStatus(
        leaveId: id,
        status: 'Withdrawn',
        remarks: 'Withdrawn by employee',
      );
    } catch (_) {} finally {
      _loadingRequestIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadFromRepository();
  }

  void _populateMockFallback() {
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
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
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
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
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
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
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
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
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
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  @override
  void dispose() {
    _leavesSubscription?.cancel();
    super.dispose();
  }
}
