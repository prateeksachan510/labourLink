import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:labour_link/core/constants/app_constants.dart';

class DirectionsResult {
  const DirectionsResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<LatLng> polylinePoints;
  final double distanceKm;
  final double durationMinutes;

  bool get hasRoute => polylinePoints.isNotEmpty;
}

/// Fetches driving route + ETA from Google Directions API.
/// Falls back to straight-line ETA if the API call fails.
class DirectionsService {
  DirectionsService._();

  // Google Maps API key — same key used in AndroidManifest / AppDelegate.
  // Replace 'YOUR_MAPS_API_KEY' with the actual key if the constant isn't set.
  static const _apiKey = AppConstants.googleMapsApiKey;

  // Simple cache to avoid re-fetching for the same point pair.
  static LatLng? _lastOrigin;
  static LatLng? _lastDest;
  static DirectionsResult? _lastResult;
  static const _cacheRadiusMetres = 50.0;

  /// Returns route polyline + ETA between [origin] and [destination].
  /// Degrades gracefully — returns a result with empty polylinePoints on error.
  static Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Cache hit
    if (_lastResult != null &&
        _lastOrigin != null &&
        _lastDest != null &&
        _distance(_lastOrigin!, origin) < _cacheRadiusMetres &&
        _distance(_lastDest!, destination) < _cacheRadiusMetres) {
      debugPrint('[DirectionsService] cache hit');
      return _lastResult!;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );
      debugPrint('[DirectionsService] fetching route origin=$origin dest=$destination');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint(
          '[DirectionsService] HTTP error ${response.statusCode}',
        );
        return _fallback(origin, destination);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';
      if (status != 'OK') {
        debugPrint('[DirectionsService] API status=$status');
        return _fallback(origin, destination);
      }

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        debugPrint('[DirectionsService] No routes found');
        return _fallback(origin, destination);
      }

      final route = routes[0] as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      final leg = legs[0] as Map<String, dynamic>;

      final distanceMetres =
          (leg['distance']?['value'] as int?) ?? 0;
      final durationSecs =
          (leg['duration']?['value'] as int?) ?? 0;
      final encodedPolyline =
          route['overview_polyline']?['points'] as String? ?? '';

      final polylineDecoder = PolylinePoints();
      final decoded =
          polylineDecoder.decodePolyline(encodedPolyline);
      final latLngs = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final result = DirectionsResult(
        polylinePoints: latLngs,
        distanceKm: distanceMetres / 1000,
        durationMinutes: durationSecs / 60,
      );

      // Cache
      _lastOrigin = origin;
      _lastDest = destination;
      _lastResult = result;

      debugPrint(
        '[DirectionsService] route fetched distKm=${result.distanceKm.toStringAsFixed(2)} '
        'eta=${result.durationMinutes.toStringAsFixed(0)} min '
        'polylinePoints=${latLngs.length}',
      );
      return result;
    } catch (e) {
      debugPrint('[DirectionsService] getRoute error: $e');
      return _fallback(origin, destination);
    }
  }

  /// Straight-line fallback when Directions API is unavailable.
  static DirectionsResult _fallback(LatLng origin, LatLng dest) {
    final distKm = _distance(origin, dest) / 1000;
    final etaMins = (distKm / AppConstants.ridingSpeedKmh) * 60;
    debugPrint(
      '[DirectionsService] fallback straight-line distKm=${distKm.toStringAsFixed(2)} '
      'etaMins=${etaMins.toStringAsFixed(0)}',
    );
    return DirectionsResult(
      polylinePoints: const [],
      distanceKm: distKm,
      durationMinutes: etaMins,
    );
  }

  static double _distance(LatLng a, LatLng b) {
    // Haversine approximation in metres
    const R = 6371000.0;
    final lat1 = a.latitude * 3.141592653589793 / 180;
    final lat2 = b.latitude * 3.141592653589793 / 180;
    final dLat = (b.latitude - a.latitude) * 3.141592653589793 / 180;
    final dLng = (b.longitude - a.longitude) * 3.141592653589793 / 180;
    final sinLat = _sin(dLat / 2);
    final sinLng = _sin(dLng / 2);
    final a2 =
        sinLat * sinLat + _cos(lat1) * _cos(lat2) * sinLng * sinLng;
    final c = 2 * _atan2(a2);
    return R * c;
  }

  static double _sin(double x) => x - (x * x * x) / 6;
  static double _cos(double x) =>
      1 - (x * x) / 2 + (x * x * x * x) / 24;
  static double _atan2(double x) => x < 1 ? x * (1 - x / 3) : x;
}
