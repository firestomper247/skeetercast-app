import 'api_service.dart';
import 'api_config.dart';

/// Forecast service for city weather data

class ForecastService {
  final ApiService _api = ApiService();
  
  /// Fetch forecast for a specific city
  Future<Map<String, dynamic>?> getCityForecast(String cityId) async {
    try {
      final response = await _api.get(
        ApiConfig.cityForecast,
        params: {'city': cityId},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
  
  /// Fetch forecast by coordinates
  Future<Map<String, dynamic>?> getForecastByCoords(double lat, double lon) async {
    try {
      final response = await _api.get(
        ApiConfig.cityForecast,
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
  
  /// Get user's saved cities
  Future<List<Map<String, dynamic>>> getSavedCities() async {
    try {
      final response = await _api.get(ApiConfig.savedCities);
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }
  
  /// Save a city to user's list
  Future<bool> saveCity(String cityId) async {
    try {
      final response = await _api.post(
        ApiConfig.savedCities,
        data: {'city': cityId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  /// Remove a city from user's list
  Future<bool> removeCity(String cityId) async {
    try {
      final response = await _api.delete('${ApiConfig.savedCities}/$cityId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
