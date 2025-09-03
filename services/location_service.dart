import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Check if location services are enabled on the device
  static Future<bool> _isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  static Future<bool> checkPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await _isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // User denied forever → open settings
        print('Location permission denied forever. Opening app settings...');
        await openAppSettings();
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Get user's current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get user's current location with custom settings
  static Future<Position?> getCurrentLocationWithSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        print('Location permission not granted');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
    } catch (e) {
      print('Error getting current location with custom settings: $e');
      return null;
    }
  }

  /// Get distance between two positions in meters
  static double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Listen to location changes (returns a stream)
  static Stream<Position> getLocationStream({
    LocationSettings? locationSettings,
  }) {
    locationSettings ??= const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update when moved 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Check if location permission is permanently denied
  static Future<bool> isPermissionDeniedForever() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.deniedForever;
    } catch (e) {
      print('Error checking if permission is denied forever: $e');
      return false;
    }
  }
}
