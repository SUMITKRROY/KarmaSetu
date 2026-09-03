import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.locality,
    this.subLocality,
    this.administrativeArea,
  });
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<LocationResult?> getCurrentLocationWithAddress() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await checkAndRequestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        // Fallback to cached hardware GPS location if offline satellite fix is slow
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        return null;
      }

      String address = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      String? locality = 'GPS Location';
      String? subLocality;
      String? adminArea;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locality = place.locality;
          subLocality = place.subLocality;
          adminArea = place.administrativeArea;

          final addressParts = <String>[
            if (place.name != null && place.name!.isNotEmpty && place.name != place.street) place.name!,
            if (place.street != null && place.street!.isNotEmpty) place.street!,
            if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
            if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
            if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode!,
          ];

          if (addressParts.isNotEmpty) {
            address = addressParts.join(', ');
          }
        }
      } catch (_) {
        // Fallback to coordinates if geocoding fails
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        formattedAddress: address,
        locality: locality,
        subLocality: subLocality,
        administrativeArea: adminArea,
      );
    } catch (_) {
      return null;
    }
  }
}
