import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Location Service - handles GPS location detection with smart caching
/// Designed to be battery-efficient like other weather apps
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  Position? _lastPosition;
  DateTime? _lastPositionTime;

  // Distance threshold to trigger city change (5 miles in meters)
  static const double distanceThresholdMeters = 8046.72; // 5 miles

  // Minimum time between location checks (5 minutes)
  static const Duration minCheckInterval = Duration(minutes: 5);

  /// Check if location services are available and permissions granted
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position (battery-efficient)
  /// Uses cached position if recent, otherwise gets fresh location
  Future<Position?> getCurrentPosition({
    bool forceRefresh = false,
    Duration cacheTimeout = const Duration(minutes: 5),
  }) async {
    try {
      // Return cached position if recent enough
      if (!forceRefresh &&
          _lastPosition != null &&
          _lastPositionTime != null &&
          DateTime.now().difference(_lastPositionTime!) < cacheTimeout) {
        return _lastPosition;
      }

      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return null;
      }

      // Try last known position first (instant, no battery hit)
      Position? position = await Geolocator.getLastKnownPosition();

      // If no cached position or it's old, get fresh one
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Low accuracy = less battery
          timeLimit: const Duration(seconds: 10),
        );
      }

      if (position != null) {
        _lastPosition = position;
        _lastPositionTime = DateTime.now();
        await _saveLastPosition(position);
      }

      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Check if user has moved significantly from last saved location
  /// Returns true if moved more than 5 miles
  Future<bool> hasMovedSignificantly() async {
    final savedPosition = await _getSavedPosition();
    if (savedPosition == null) return true; // No saved position, should update

    final currentPosition = await getCurrentPosition();
    if (currentPosition == null) return false; // Can't determine, don't update

    final distance = Geolocator.distanceBetween(
      savedPosition['lat']!,
      savedPosition['lon']!,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    debugPrint('Distance from last city: ${(distance / 1609.34).toStringAsFixed(1)} miles');

    return distance > distanceThresholdMeters;
  }

  /// Save the position associated with current city
  Future<void> saveCityPosition(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('city_lat', lat);
    await prefs.setDouble('city_lon', lon);
    await prefs.setInt('city_position_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get last saved city position
  Future<Map<String, double>?> _getSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('city_lat');
    final lon = prefs.getDouble('city_lon');

    if (lat != null && lon != null) {
      return {'lat': lat, 'lon': lon};
    }
    return null;
  }

  /// Save last known position to prefs
  Future<void> _saveLastPosition(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', position.latitude);
    await prefs.setDouble('last_lon', position.longitude);
    await prefs.setInt('last_position_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if enough time has passed since last location check
  Future<bool> shouldCheckLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('last_location_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if at least 5 minutes have passed
    if (now - lastCheck < minCheckInterval.inMilliseconds) {
      return false;
    }

    await prefs.setInt('last_location_check', now);
    return true;
  }

  /// Get last known position (faster, may be stale)
  Future<Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Error getting last known position: $e');
      return null;
    }
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission denied forever)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Calculate distance between two points (in meters)
  double distanceBetween(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  /// Get cached position (no permission check, returns null if no cache)
  Position? get cachedPosition => _lastPosition;

  /// Clear cached data (for testing/logout)
  Future<void> clearCache() async {
    _lastPosition = null;
    _lastPositionTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('city_lat');
    await prefs.remove('city_lon');
    await prefs.remove('last_lat');
    await prefs.remove('last_lon');
  }
}
