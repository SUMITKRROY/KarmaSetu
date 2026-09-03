import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<Map<Permission, PermissionStatus>> requestDashboardPermissions() async {
    final permissions = [
      Permission.location,
      Permission.camera,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  Future<bool> checkAndRequestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted || status.isLimited;
  }

  Future<bool> checkAndRequestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }
}
