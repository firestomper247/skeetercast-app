import 'api_service.dart';
import 'api_config.dart';

/// Captain Steve AI Chat service
/// Handles chat with Captain Steve AI assistant

class CaptainSteveService {
  final ApiService _api = ApiService();
  
  /// URL to Captain Steve chat interface
  static const String chatUrl = 'https://skeetercast.com/captain-steve';
  
  /// Send a message to Captain Steve and get response
  Future<String?> sendMessage(String message, {String? location}) async {
    try {
      final response = await _api.post(
        '${ApiConfig.aiBase}/api/chat',
        data: {
          'message': message,
          if (location != null) 'location': location,
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
  
  /// Get conversation history
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _api.get('${ApiConfig.aiBase}/api/history');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }
}
