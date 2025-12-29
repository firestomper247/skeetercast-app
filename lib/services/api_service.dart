import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

/// Base API service with Dio HTTP client
/// Handles authentication tokens and common request logic

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionTokenKey = 'session_token';
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 - try to refresh token
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the request
            final opts = error.requestOptions;
            final token = await getToken();
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
  
  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveSessionToken(String token) async {
    await _storage.write(key: _sessionTokenKey, value: token);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _sessionTokenKey);
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await saveToken(response.data['token']);
        if (response.data['refresh_token'] != null) {
          await saveRefreshToken(response.data['refresh_token']);
        }
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }
  
  // Generic request methods
  Future<Response> get(String url, {Map<String, dynamic>? params}) async {
    return await _dio.get(url, queryParameters: params);
  }
  
  Future<Response> post(String url, {dynamic data}) async {
    return await _dio.post(url, data: data);
  }
  
  Future<Response> put(String url, {dynamic data}) async {
    return await _dio.put(url, data: data);
  }
  
  Future<Response> delete(String url) async {
    return await _dio.delete(url);
  }
}
