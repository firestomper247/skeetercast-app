import 'api_service.dart';
import 'api_config.dart';

/// Ocean service for fishing conditions and data

class OceanService {
  final ApiService _api = ApiService();
  
  /// Fetch current ocean conditions
  Future<Map<String, dynamic>?> getConditions({String? location}) async {
    try {
      final response = await _api.get(
        ApiConfig.oceanConditions,
        params: location != null ? {'location': location} : null,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
  
  /// Fetch species fishing scores
  Future<List<Map<String, dynamic>>> getSpeciesScores({String? location}) async {
    try {
      final response = await _api.get(
        ApiConfig.speciesScores,
        params: location != null ? {'location': location} : null,
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }
  
  /// Fetch sea surface temperature data
  Future<Map<String, dynamic>?> getSSTData({double? lat, double? lon}) async {
    try {
      final params = <String, dynamic>{};
      if (lat != null) params['lat'] = lat;
      if (lon != null) params['lon'] = lon;
      
      final response = await _api.get(ApiConfig.sstData, params: params);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
  
  /// Fetch tide information
  Future<Map<String, dynamic>?> getTides({String? stationId}) async {
    try {
      final response = await _api.get(
        ApiConfig.tides,
        params: stationId != null ? {'station': stationId} : null,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
  
  /// Fetch inlet conditions
  Future<Map<String, dynamic>?> getInletConditions({String? inlet}) async {
    try {
      final response = await _api.get(
        ApiConfig.inletConditions,
        params: inlet != null ? {'inlet': inlet} : null,
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
}
