import 'api_service.dart';
import 'api_config.dart';

/// Radar service for weather maps and alerts

class RadarService {
  final ApiService _api = ApiService();
  
  /// Base URL for radar tiles
  String get radarTileUrl => '${ApiConfig.radarTiles}/{z}/{x}/{y}.png';
  
  /// Fetch weather alerts
  Future<List<Map<String, dynamic>>> getAlerts({double? lat, double? lon}) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null) params['lat'] = lat;
      if (lon != null) params['lon'] = lon;
      
      final response = await _api.get(ApiConfig.alerts, params: params);
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }
}
