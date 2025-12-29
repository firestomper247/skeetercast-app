import 'api_service.dart';
import 'api_config.dart';

/// Forecast service for city weather data
/// Provides full weather forecasts, saved cities, and alerts

class ForecastService {
  final ApiService _api = ApiService();

  /// Get full weather forecast for a city by name
  Future<Map<String, dynamic>?> getForecastByCity(String city) async {
    try {
      final response = await _api.get(ApiConfig.forecastByCity(city));
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get full weather forecast by zipcode
  Future<Map<String, dynamic>?> getForecastByZipcode(String zipcode) async {
    try {
      final response = await _api.get(ApiConfig.forecastByZipcode(zipcode));
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Smart search - detects if input is zipcode or city name
  Future<Map<String, dynamic>?> searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    // Check if it's a 5-digit zipcode
    if (RegExp(r'^\d{5}$').hasMatch(trimmed)) {
      return getForecastByZipcode(trimmed);
    }
    return getForecastByCity(trimmed);
  }

  /// Get weather alerts for a location
  Future<List<dynamic>> getAlerts(double lat, double lon) async {
    try {
      final response = await _api.get(ApiConfig.warningsByLocation(lat, lon));
      if (response.statusCode == 200) {
        return response.data['alerts'] ?? [];
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Get Captain Steve's weather narrative for a city
  Future<String?> getSteveForecast(String city, Map<String, dynamic> forecastData) async {
    try {
      // Extract forecast periods
      final forecast = forecastData['forecast'] as List<dynamic>? ?? [];
      if (forecast.isEmpty) return null;

      // Find tonight and tomorrow periods
      Map<String, dynamic>? tonightPeriod;
      Map<String, dynamic>? tomorrowPeriod;

      for (final period in forecast) {
        final name = (period['name'] ?? '').toString().toLowerCase();
        if (name.contains('tonight') || (name.contains('night') && period['is_daytime'] == false)) {
          tonightPeriod = period;
        }
        if (period['is_daytime'] == true && !name.contains('this') && !name.contains('today')) {
          tomorrowPeriod ??= period;
        }
      }

      final response = await _api.post(
        ApiConfig.steveCityForecast,
        data: {
          'city': city,
          'tonight_conditions': tonightPeriod?['short_forecast'] ?? 'Clear',
          'tonight_low': tonightPeriod?['temperature_f'],
          'tomorrow_conditions': tomorrowPeriod?['short_forecast'] ?? 'Sunny',
          'tomorrow_high': tomorrowPeriod?['temperature_f'],
          'wind_direction': tomorrowPeriod?['wind_direction'] ?? '',
          'wind_speed': tomorrowPeriod?['wind_speed'] ?? '',
          'rain_chance': tomorrowPeriod?['precip_probability'] ?? 0,
        },
      );

      if (response.statusCode == 200) {
        return response.data['response'];
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get saved cities for logged-in user
  Future<List<Map<String, dynamic>>> getSavedCities() async {
    try {
      final response = await _api.get(ApiConfig.savedCities);
      if (response.statusCode == 200) {
        final cities = response.data['cities'] as List<dynamic>? ?? [];
        return cities.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Save a city for the user
  Future<bool> saveCity({
    required String cityName,
    String? zipcode,
    String state = 'NC',
    required double lat,
    required double lon,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.savedCities,
        data: {
          'city_name': cityName,
          'zipcode': zipcode ?? '',
          'state': state,
          'lat': lat,
          'lon': lon,
          'is_primary': isPrimary,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Remove a saved city
  Future<bool> removeSavedCity(int cityId) async {
    try {
      final response = await _api.delete(ApiConfig.deleteSavedCity(cityId));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
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

  // Legacy method for backwards compatibility
  Future<Map<String, dynamic>?> getCityForecast(String city) async {
    return getForecastByCity(city);
  }
}
