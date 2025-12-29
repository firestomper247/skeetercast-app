import 'api_service.dart';
import 'api_config.dart';

/// Forecast service for city weather data
/// Note: City forecasts come through Captain Steve's city-forecast endpoint

class ForecastService {
  final ApiService _api = ApiService();

  /// Get weather summary for a city from Captain Steve
  Future<Map<String, dynamic>?> getCityForecast(String city) async {
    try {
      final response = await _api.post(
        ApiConfig.steveCityForecast,
        data: {'city': city},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get strike times (solunar fishing calendar)
  Future<Map<String, dynamic>?> getStrikeTimes() async {
    try {
      final response = await _api.get(ApiConfig.steveStrikeTimes);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
}
