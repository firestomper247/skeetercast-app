import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import 'api_config.dart';

/// Manages offline caching and sync for SkeeterCast
/// Handles: weather data, saved spots, condition reports, and pending actions
class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static OfflineService get instance => _instance;

  // Hive boxes
  late Box<String> _weatherCache;
  late Box<String> _spotsCache;
  late Box<String> _pendingActions;
  late Box<String> _settingsCache;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isInitialized = false;

  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  /// Initialize offline service - call this in main.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Open boxes
    _weatherCache = await Hive.openBox<String>('weather_cache');
    _spotsCache = await Hive.openBox<String>('spots_cache');
    _pendingActions = await Hive.openBox<String>('pending_actions');
    _settingsCache = await Hive.openBox<String>('settings_cache');

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);

      if (wasOffline && _isOnline) {
        // Back online - sync pending actions
        _syncPendingActions();
      }

      notifyListeners();
    });

    _isInitialized = true;
    debugPrint('OfflineService initialized. Online: $_isOnline');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // ============ WEATHER CACHING ============

  /// Cache weather data for a location
  Future<void> cacheWeatherData(String key, Map<String, dynamic> data) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _weatherCache.put(key, jsonEncode(cacheEntry));
  }

  /// Get cached weather data (returns null if expired or not found)
  Map<String, dynamic>? getCachedWeatherData(String key, {Duration maxAge = const Duration(hours: 6)}) {
    final cached = _weatherCache.get(key);
    if (cached == null) return null;

    try {
      final entry = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(entry['timestamp'] as String);

      if (DateTime.now().difference(timestamp) > maxAge) {
        return null; // Expired
      }

      return entry['data'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cache city forecast data
  Future<void> cacheCityForecast(String cityName, Map<String, dynamic> data) async {
    await cacheWeatherData('forecast_$cityName', data);
  }

  /// Get cached city forecast
  Map<String, dynamic>? getCachedCityForecast(String cityName) {
    return getCachedWeatherData('forecast_$cityName');
  }

  /// Cache ocean data (SST, chlorophyll, etc.)
  Future<void> cacheOceanData(String dataType, Map<String, dynamic> data) async {
    await cacheWeatherData('ocean_$dataType', data);
  }

  /// Get cached ocean data
  Map<String, dynamic>? getCachedOceanData(String dataType) {
    return getCachedWeatherData('ocean_$dataType', maxAge: const Duration(hours: 12));
  }

  // ============ SPOTS CACHING ============

  /// Cache user's saved spots
  Future<void> cacheSpots(List<Map<String, dynamic>> spots) async {
    await _spotsCache.put('user_spots', jsonEncode(spots));
  }

  /// Get cached spots
  List<Map<String, dynamic>> getCachedSpots() {
    final cached = _spotsCache.get('user_spots');
    if (cached == null) return [];

    try {
      final list = jsonDecode(cached) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Save a spot offline (will sync when online)
  Future<void> saveSpotOffline(Map<String, dynamic> spot) async {
    // Generate temp ID if needed
    spot['temp_id'] = spot['temp_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    spot['pending_sync'] = true;

    // Add to local cache
    final spots = getCachedSpots();
    spots.add(spot);
    await cacheSpots(spots);

    // Queue for sync
    await _queueAction('save_spot', spot);

    notifyListeners();
  }

  // ============ CONDITION REPORTS ============

  /// Cache condition reports for viewing
  Future<void> cacheConditionReports(List<Map<String, dynamic>> reports) async {
    await _spotsCache.put('condition_reports', jsonEncode(reports));
  }

  /// Get cached condition reports
  List<Map<String, dynamic>> getCachedConditionReports() {
    final cached = _spotsCache.get('condition_reports');
    if (cached == null) return [];

    try {
      final list = jsonDecode(cached) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Submit a condition report offline
  Future<void> submitReportOffline(Map<String, dynamic> report) async {
    report['temp_id'] = DateTime.now().millisecondsSinceEpoch.toString();
    report['pending_sync'] = true;
    report['submitted_at'] = DateTime.now().toIso8601String();

    // Add to local cache for viewing
    final reports = getCachedConditionReports();
    reports.insert(0, report); // Add to front
    await cacheConditionReports(reports);

    // Queue for sync
    await _queueAction('submit_report', report);

    notifyListeners();
  }

  // ============ PENDING ACTIONS QUEUE ============

  /// Queue an action for later sync
  Future<void> _queueAction(String actionType, Map<String, dynamic> data) async {
    final action = {
      'type': actionType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retries': 0,
    };

    final actionId = DateTime.now().millisecondsSinceEpoch.toString();
    await _pendingActions.put(actionId, jsonEncode(action));

    debugPrint('Queued offline action: $actionType ($actionId)');
  }

  /// Get count of pending actions
  int get pendingActionsCount => _pendingActions.length;

  /// Sync all pending actions when online
  Future<void> _syncPendingActions() async {
    if (!_isOnline) return;

    debugPrint('Syncing ${_pendingActions.length} pending actions...');

    final api = ApiService();
    final keysToRemove = <String>[];

    for (final key in _pendingActions.keys) {
      try {
        final actionJson = _pendingActions.get(key);
        if (actionJson == null) continue;

        final action = jsonDecode(actionJson) as Map<String, dynamic>;
        final actionType = action['type'] as String;
        final data = action['data'] as Map<String, dynamic>;

        bool success = false;

        switch (actionType) {
          case 'save_spot':
            success = await _syncSaveSpot(api, data);
            break;
          case 'submit_report':
            success = await _syncSubmitReport(api, data);
            break;
          default:
            debugPrint('Unknown action type: $actionType');
            success = true; // Remove unknown actions
        }

        if (success) {
          keysToRemove.add(key as String);
          debugPrint('Synced action: $actionType ($key)');
        } else {
          // Increment retry count
          action['retries'] = (action['retries'] as int) + 1;
          if ((action['retries'] as int) >= 5) {
            keysToRemove.add(key as String); // Give up after 5 retries
            debugPrint('Giving up on action after 5 retries: $actionType ($key)');
          } else {
            await _pendingActions.put(key, jsonEncode(action));
          }
        }
      } catch (e) {
        debugPrint('Error syncing action $key: $e');
      }
    }

    // Remove synced actions
    for (final key in keysToRemove) {
      await _pendingActions.delete(key);
    }

    notifyListeners();
  }

  /// Sync a saved spot to server
  Future<bool> _syncSaveSpot(ApiService api, Map<String, dynamic> data) async {
    try {
      final response = await api.post(ApiConfig.userSpots, data: {
        'name': data['name'],
        'lat': data['lat'],
        'lon': data['lon'],
        'notes': data['notes'],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local cache with server ID
        final spots = getCachedSpots();
        final index = spots.indexWhere((s) => s['temp_id'] == data['temp_id']);
        if (index >= 0) {
          spots[index]['id'] = response.data['spot']?['id'];
          spots[index]['pending_sync'] = false;
          await cacheSpots(spots);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error syncing spot: $e');
    }
    return false;
  }

  /// Sync a condition report to server
  Future<bool> _syncSubmitReport(ApiService api, Map<String, dynamic> data) async {
    try {
      final response = await api.post(ApiConfig.observations, data: {
        'lat': data['lat'],
        'lon': data['lon'],
        'water_temp': data['water_temp'],
        'water_clarity': data['water_clarity'],
        'wind_speed': data['wind_speed'],
        'wind_direction': data['wind_direction'],
        'wave_height': data['wave_height'],
        'fish_activity': data['fish_activity'],
        'notes': data['notes'],
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local cache
        final reports = getCachedConditionReports();
        final index = reports.indexWhere((r) => r['temp_id'] == data['temp_id']);
        if (index >= 0) {
          reports[index]['id'] = response.data['observation']?['id'];
          reports[index]['pending_sync'] = false;
          await cacheConditionReports(reports);
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error syncing report: $e');
    }
    return false;
  }

  /// Force sync now (call from UI)
  Future<void> syncNow() async {
    if (_isOnline) {
      await _syncPendingActions();
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    await _weatherCache.clear();
    await _spotsCache.clear();
    // Don't clear pending actions - those should sync
    notifyListeners();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'weatherEntries': _weatherCache.length,
      'spotsEntries': _spotsCache.length,
      'pendingActions': _pendingActions.length,
    };
  }
}
