import 'api_service.dart';
import 'api_config.dart';

/// Captain Steve AI service
/// Handles chat, recommendations, and fishing picks

class CaptainSteveService {
  final ApiService _api = ApiService();

  /// URL to Captain Steve chat page (web)
  static String get chatPageUrl => ApiConfig.captainSteveChat;

  /// Get fishing recommendations for all zones
  Future<Map<String, dynamic>?> getRecommendations() async {
    try {
      final response = await _api.get(ApiConfig.steveRecommendations);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get species scores (all 19 species)
  Future<Map<String, dynamic>?> getSpeciesScores() async {
    try {
      final response = await _api.get(ApiConfig.steveSpeciesScores);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Chat with Captain Steve (requires auth)
  Future<Map<String, dynamic>?> chat(String question, {List<Map<String, String>>? history}) async {
    try {
      final response = await _api.post(
        ApiConfig.steveChat,
        data: {
          'question': question,
          if (history != null) 'conversation_history': history,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get strike times (solunar calendar)
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

  /// Get data quality report
  Future<Map<String, dynamic>?> getDataQuality() async {
    try {
      final response = await _api.get(ApiConfig.steveDataQuality);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get city weather forecast summary
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
}
