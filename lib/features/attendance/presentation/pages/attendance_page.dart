import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendancePage extends StatefulWidget {
  final bool isTab;
  const AttendancePage({super.key, this.isTab = true});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Live ticking timer for real-time offline/online duration tracking
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAttendanceData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initAttendanceData();
    }
  }

  void _initAttendanceData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AttendanceBloc>().add(
            CheckTodayAttendanceRequested(
              uid: authState.user.uid ,
              employeeId: authState.user.employeeId,
            ),
          );
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        // Save to persistent application documents directory so local SQLite path is always permanent & valid offline
        final appDir = await getApplicationDocumentsDirectory();
        final selfiesDir = Directory(p.join(appDir.path, 'attendance_selfies'));
        if (!await selfiesDir.exists()) {
          await selfiesDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final persistentPath = p.join(selfiesDir.path, 'selfie_$timestamp.jpg');
        await File(photo.path).copy(persistentPath);

        if (mounted) {
          context.read<AttendanceBloc>().add(
            SelfieCaptured(persistentPath),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handlePunchAction(AttendanceState state) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    final user = authState.user;
    final hasSelfie = state.selfiePath != null && File(state.selfiePath!).existsSync();
    final hasLocation = state.currentLocation != null;

    // Condition 1: Selfie image is strictly mandatory
    if (!hasSelfie) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.isCheckedIn
              ? 'Selfie image is mandatory for Check-Out. Please take a photo first.'
              : 'Selfie image is mandatory for Check-In. Please take a photo first.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _takeSelfie();
      return;
    }

    // Condition 2: GPS Location is strictly mandatory (works offline via device GPS)
    if (!hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS Location is mandatory for attendance. Acquiring location, please wait...'),
          backgroundColor: Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<AttendanceBloc>().add(const RefreshAttendanceLocationRequested());
      return;
    }

    if (state.isNotCheckedIn) {
      context.read<AttendanceBloc>().add(
            PerformCheckInRequested(
              uid: user.uid,
              employeeId: user.employeeId,
              selfiePath: state.selfiePath,
            ),
          );
    } else if (state.isCheckedIn) {
      final currentRecord = state.verifiedTodayAttendance;
      if (currentRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active check-in found for today. Please check in first.')),
        );
        return;
      }

      context.read<AttendanceBloc>().add(
            PerformCheckOutRequested(
              attendanceId: currentRecord.attendanceId,
              selfiePath: state.selfiePath,
            ),
          );
    }
  }

  String _formatTrackedTime(DateTime? checkIn, DateTime? checkOut, int workingMinutes) {
    if (checkOut != null && workingMinutes > 0) {
      final h = workingMinutes ~/ 60;
      final m = workingMinutes % 60;
      return 'Total working hours: ${h}h ${m}m';
    } else if (checkIn != null) {
      final diff = DateTime.now().difference(checkIn);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      return 'Working hours tracked: ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} (Live)';
    }
    return 'Shift hours: 09:30 AM - 06:30 PM';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state.submissionStatus == AttendanceSubmissionStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: const Color(0xFF083E2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.submissionStatus == AttendanceSubmissionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        final user = (authState is AuthAuthenticated) ? authState.user : null;
        final name = user?.name ?? 'Employee';
        final employeeId = user?.employeeId ?? 'EMP001';
        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        final todayStr = AppDateUtils.formatDisplayDate(DateTime.now());
        final todayAttendance = state.verifiedTodayAttendance;
        final now = DateTime.now();

        final checkInTimeStr = todayAttendance?.checkIn != null
            ? AppDateUtils.formatDisplayTime(todayAttendance!.checkIn)
            : AppDateUtils.formatDisplayTime(now);

        final checkOutTimeStr = todayAttendance?.checkOut != null
            ? AppDateUtils.formatDisplayTime(todayAttendance!.checkOut)
            : '--:--';
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Attendance'),
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials.isEmpty ? 'EM' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _initAttendanceData();
                context.read<AttendanceBloc>().add(const RefreshAttendanceLocationRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connectivity & Sync Status Banner
                    _buildConnectivityBanner(state),

                    // 1. Today's Attendance Card
                    _buildTodayAttendanceCard(
                      dateStr: todayStr,
                      checkInTime: checkInTimeStr,
                      checkOutTime: checkOutTimeStr,
                      state: state,
                    ),
                    const SizedBox(height: 16),

                    // 2. Identity Verification Card (Camera / Selfie) - Mandatory for both Check-In & Check-Out
                    _buildIdentityVerificationCard(
                      name: name,
                      employeeId: employeeId,
                      selfiePath: state.selfiePath,
                      state: state,
                    ),
                    const SizedBox(height: 16),

                    // 3. Location Verified Card (GPS / Geocoding)
                    _buildLocationVerifiedCard(
                      location: state.currentLocation,
                      isFetching: state.isFetchingLocation,
                    ),
                    const SizedBox(height: 24),

                    // 4. Primary Punch Button
                    _buildPunchButton(state),
                    const SizedBox(height: 12),

                    // Tracked working hours text
                    Center(
                      child: Text(
                        _formatTrackedTime(
                          todayAttendance?.checkIn,
                          todayAttendance?.checkOut,
                          todayAttendance?.workingMinutes ?? 0,
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAttendanceCard({
    required String dateStr,
    required String checkInTime,
    required String checkOutTime,
    required AttendanceState state,
  }) {
    final isCheckedIn = state.isCheckedIn;
    final isCheckedOut = state.isCheckedOut;

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (isCheckedOut) {
      statusText = 'Completed (Checked Out)';
      statusColor = const Color(0xFF1D4ED8);
      statusBgColor = const Color(0xFFDBEAFE);
    } else if (isCheckedIn) {
      statusText = 'Checked In (Active)';
      statusColor = AppColors.primary;
      statusBgColor = const Color(0xFFE8F3EE);
    } else {
      statusText = 'Not Checked In';
      statusColor = AppColors.error;
      statusBgColor = const Color(0xFFFFEBEE);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.login_rounded, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Check In',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        checkInTime,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Check Out',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        checkOutTime,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn || isCheckedOut ? Icons.circle : Icons.cancel_outlined,
                      size: 8,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.todayAttendance != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.todayAttendance!.isSynced
                        ? const Color(0xFFE8F3EE)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.todayAttendance!.isSynced ? Icons.cloud_done : Icons.cloud_off,
                        size: 12,
                        color: state.todayAttendance!.isSynced
                            ? AppColors.primary
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state.todayAttendance!.isSynced ? 'Synced' : 'Saved Locally',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: state.todayAttendance!.isSynced
                              ? AppColors.primary
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityBanner(AttendanceState state) {
    if (state.isSyncing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Syncing offline attendance records with server...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isOffline) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Offline Mode: Attendance will save locally and auto-sync once connected.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFFD97706)),
              tooltip: 'Retry Sync',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                context.read<AttendanceBloc>().add(const SyncUnsyncedAttendanceRequested());
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildIdentityVerificationCard({
    required String name,
    required String employeeId,
    required String? selfiePath,
    required AttendanceState state,
  }) {
    final todayAttendance = state.verifiedTodayAttendance;
    final isCheckedIn = state.isCheckedIn;
    final isCheckedOut = state.isCheckedOut;

    // Resolve which image to display:
    // 1. Newly captured selfie (for either check-in or check-out)
    // 2. Or saved check-in / check-out image from local SQLite database
    String? displayImagePath;
    String photoStatusLabel = '';
    bool isNewlyCaptured = false;

    if (selfiePath != null && File(selfiePath).existsSync()) {
      displayImagePath = selfiePath;
      photoStatusLabel = isCheckedIn ? 'Ready for Check-Out' : 'Ready for Check-In';
      isNewlyCaptured = true;
    } else if (isCheckedOut) {
      if (todayAttendance?.checkOutSelfie != null && File(todayAttendance!.checkOutSelfie!).existsSync()) {
        displayImagePath = todayAttendance.checkOutSelfie;
        photoStatusLabel = 'Check-Out Photo (Saved Locally)';
      } else if (todayAttendance?.checkInSelfie != null && File(todayAttendance!.checkInSelfie!).existsSync()) {
        displayImagePath = todayAttendance.checkInSelfie;
        photoStatusLabel = 'Check-In Photo (Saved Locally)';
      }
    } else if (isCheckedIn) {
      if (todayAttendance?.checkInSelfie != null && File(todayAttendance!.checkInSelfie!).existsSync()) {
        displayImagePath = todayAttendance.checkInSelfie;
        photoStatusLabel = 'Check-In Photo (Saved in DB)';
      }
    }

    final hasDisplayImage = displayImagePath != null && File(displayImagePath).existsSync();

    String cardTitle;
    String badgeTitle;
    String promptText;
    String buttonText;

    if (isCheckedOut) {
      cardTitle = 'Identity Verification';
      badgeTitle = 'Shift Completed';
      promptText = 'Attendance verified for Check-In and Check-Out';
      buttonText = 'Retake Photo';
    } else if (isCheckedIn) {
      cardTitle = 'Identity Verification (Check-Out)';
      badgeTitle = isNewlyCaptured ? 'Ready for Punch-Out' : 'Check-Out Photo Required';
      promptText = 'Capture selfie with camera to Punch Out';
      buttonText = isNewlyCaptured ? 'Retake Photo' : 'Take Selfie for Check-Out';
    } else {
      cardTitle = 'Identity Verification (Check-In)';
      badgeTitle = hasDisplayImage ? 'Ready for Punch-In' : '*';
      promptText = 'Capture selfie with camera to Punch In';
      buttonText = hasDisplayImage ? 'Retake Photo' : 'Take Selfie for Check-In';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCheckedOut || (hasDisplayImage && (!isCheckedIn || isNewlyCaptured))
                      ? const Color(0xFFE8F3EE)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCheckedOut
                      ? 'Verified'
                      : (hasDisplayImage && (!isCheckedIn || isNewlyCaptured)
                          ? 'Verified'
                          : badgeTitle),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCheckedOut || (hasDisplayImage && (!isCheckedIn || isNewlyCaptured))
                        ? const Color(0xFF059669)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasDisplayImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.file(
                      File(displayImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(180),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$name (EMP: $employeeId)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              photoStatusLabel,
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (!isCheckedOut)
                          ElevatedButton.icon(
                            onPressed: _takeSelfie,
                            icon: const Icon(Icons.camera_alt_outlined, size: 15),
                            label: Text(
                              isCheckedIn && !isNewlyCaptured ? 'Take Check-Out Photo' : 'Retake',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCheckedIn && !isNewlyCaptured
                                  ? AppColors.primary
                                  : Colors.white,
                              foregroundColor: isCheckedIn && !isNewlyCaptured
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              elevation: 2,
                              minimumSize: const Size(80, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isCheckedIn && !isNewlyCaptured) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _takeSelfie,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Capture Selfie for Check-Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ] else if (isCheckedOut) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Shift completed! Both check-in and check-out photos were captured and recorded in local database.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promptText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _takeSelfie,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationVerifiedCard({
    required LocationResult? location,
    required bool isFetching,
  }) {
    final address = location?.formattedAddress ??
        (isFetching ? 'Fetching current GPS location...' : 'Location coordinates unavailable');
    final coords = location != null
        ? 'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}'
        : 'GPS Ready';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Location Verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (isFetching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.primary),
                  onPressed: () {
                    context.read<AttendanceBloc>().add(const RefreshAttendanceLocationRequested());
                  },
                  tooltip: 'Refresh Location',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Map styling
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EDFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.2,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coords,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location?.locality ?? 'Current GPS Location',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: location != null ? const Color(0xFFE8F3EE) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      location != null ? Icons.check_circle : Icons.gps_not_fixed,
                      size: 13,
                      color: location != null ? AppColors.primary : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location != null ? 'Active' : 'Acquiring',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: location != null ? AppColors.primary : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPunchButton(AttendanceState state) {
    final isSubmitting = state.submissionStatus == AttendanceSubmissionStatus.submitting;
    final isCheckedIn = state.isCheckedIn;
    final isCheckedOut = state.isCheckedOut;

    if (isCheckedOut) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8CD4B4), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF0B5D3B), size: 22),
            SizedBox(width: 8),
            Text(
              'Shift Completed for Today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B5D3B),
              ),
            ),
          ],
        ),
      );
    }

    final btnColor = isCheckedIn ? const Color(0xFFEF4444) : AppColors.primary;
    final btnIcon = isCheckedIn ? Icons.logout_rounded : Icons.fingerprint;
    final btnLabel = isCheckedIn ? 'Confirm Check Out' : 'Confirm Check In';

    return ElevatedButton(
      onPressed: isSubmitting ? null : () => _handlePunchAction(state),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(btnIcon, size: 22),
                const SizedBox(width: 8),
                Text(
                  btnLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
