import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests permission and returns current GPS position.
  /// Returns null if permission denied or not available.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Checks and requests location permissions if needed.
  /// Returns true only when app can access location updates.
  static Future<bool> ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stream with throttled location updates to avoid battery drain.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    );
  }

  /// Calculates distance in km between two lat/lng points.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final metres = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return metres / 1000;
  }
}
