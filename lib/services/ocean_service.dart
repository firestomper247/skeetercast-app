import 'api_service.dart';
import 'api_config.dart';

/// Ocean service for fishing conditions and data

class OceanService {
  final ApiService _api = ApiService();

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await _api.get(ApiConfig.oceanHealth);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch latest SST data
  Future<Map<String, dynamic>?> getLatestSST() async {
    try {
      final response = await _api.get(ApiConfig.latestSST);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch latest chlorophyll data
  Future<Map<String, dynamic>?> getLatestChlorophyll() async {
    try {
      final response = await _api.get(ApiConfig.latestChlorophyll);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch latest ocean currents
  Future<Map<String, dynamic>?> getLatestCurrents() async {
    try {
      final response = await _api.get(ApiConfig.latestCurrents);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch latest wave data
  Future<Map<String, dynamic>?> getLatestWaves() async {
    try {
      final response = await _api.get(ApiConfig.latestWaves);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch point data for specific coordinates
  Future<Map<String, dynamic>?> getPointData(double lat, double lon) async {
    try {
      final response = await _api.get(
        ApiConfig.oceanPointData,
        params: {'lat': lat, 'lon': lon},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch data freshness info
  Future<Map<String, dynamic>?> getDataAge() async {
    try {
      final response = await _api.get(ApiConfig.oceanDataAge);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get tile URL for map overlay
  String getTileUrl(String type) {
    // Use MUR SST tiles (cloud-free, gap-filled) for SST
    if (type == 'sst') {
      return '${ApiConfig.oceanTiles}/sst/mur/{z}/{x}/{y}.png';
    }
    return '${ApiConfig.oceanTiles}/$type/{z}/{x}/{y}.png';
  }

  /// Fetch SSH contours (GeoJSON)
  Future<Map<String, dynamic>?> getSSHContours() async {
    try {
      final response = await _api.get(ApiConfig.sshContours);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get user's saved fishing spots
  Future<List<Map<String, dynamic>>> getUserSpots() async {
    try {
      final response = await _api.get(ApiConfig.userSpots);
      if (response.statusCode == 200) {
        final spots = response.data['spots'] as List<dynamic>? ?? [];
        return spots.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Save a new fishing spot
  Future<bool> saveSpot({
    required String name,
    required double lat,
    required double lon,
    String? notes,
    String? spotType,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.userSpots,
        data: {
          'name': name,
          'latitude': lat,
          'longitude': lon,
          'notes': notes ?? '',
          'spot_type': spotType ?? 'fishing',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Delete a saved fishing spot
  Future<bool> deleteSpot(int spotId) async {
    try {
      final response = await _api.delete(ApiConfig.deleteSpot(spotId));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
