import 'api_service.dart';
import 'api_config.dart';

/// Radar service for weather maps, satellite, and alerts

class RadarService {
  final ApiService _api = ApiService();

  /// Health check
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final response = await _api.get(ApiConfig.radarHealth);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get radar frames for a region and product
  /// region: southeast, northeast, etc.
  /// product: reflectivity, velocity, etc.
  Future<Map<String, dynamic>?> getRadarFrames(String region, String product) async {
    try {
      final response = await _api.get('${ApiConfig.radarFrames}/$region/$product');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get latest satellite imagery
  /// product: visible, infrared, water_vapor
  Future<Map<String, dynamic>?> getSatelliteLatest(String product) async {
    try {
      final response = await _api.get('${ApiConfig.satelliteLatest}/$product/latest');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get lightning strikes in the last N minutes
  Future<Map<String, dynamic>?> getLightning(int minutes) async {
    try {
      final response = await _api.get('${ApiConfig.lightning}/$minutes');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get active NWS warnings
  Future<Map<String, dynamic>?> getActiveWarnings() async {
    try {
      final response = await _api.get(ApiConfig.warnings);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
}
