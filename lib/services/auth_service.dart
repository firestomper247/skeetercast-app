import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'api_config.dart';

/// Authentication service for SkeeterCast
/// Handles login, registration, and user session

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  String? _tier; // free, basic, premium

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  String? get tier => _tier;
  bool get isPremium => _tier == 'premium';
  bool get isBasic => _tier == 'basic' || _tier == 'premium';
  
  AuthService() {
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    final token = await _api.getToken();
    if (token != null) {
      // Validate token by fetching user profile
      try {
        await fetchUserProfile();
      } catch (e) {
        // Token invalid, clear it
        await logout();
      }
    }
  }
  
  Future<bool> login(String username, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        await _api.saveToken(response.data['token']);
        if (response.data['refresh_token'] != null) {
          await _api.saveRefreshToken(response.data['refresh_token']);
        }
        if (response.data['session_token'] != null) {
          await _api.saveSessionToken(response.data['session_token']);
        }

        // User data is nested under 'user' key from API
        final userData = response.data['user'] ?? {};
        _isLoggedIn = true;
        _username = userData['username'] ?? username;
        _email = userData['email'];
        _tier = userData['tier'] ?? 'free';
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }
  
  Future<bool> register(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto-login after registration
        return await login(email, password);
      }
    } catch (e) {
      debugPrint('Registration error: $e');
    }
    return false;
  }
  
  Future<void> logout() async {
    await _api.clearTokens();
    _isLoggedIn = false;
    _username = null;
    _email = null;
    _tier = null;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await _api.get(ApiConfig.userProfile);

      if (response.statusCode == 200) {
        // User data is nested under 'user' key from API
        final userData = response.data['user'] ?? {};
        _isLoggedIn = true;
        _username = userData['username'];
        _email = userData['email'];
        _tier = userData['tier'] ?? 'free';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
      rethrow;
    }
  }
}
