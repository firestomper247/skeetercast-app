import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// Manages map tile caching for offline use
/// Uses flutter_map_tile_caching (FMTC) for efficient tile storage
class MapCacheService {
  static final MapCacheService _instance = MapCacheService._internal();
  factory MapCacheService() => _instance;
  MapCacheService._internal();

  static MapCacheService get instance => _instance;

  bool _isInitialized = false;
  FMTCStore? _mainStore;

  bool get isInitialized => _isInitialized;

  /// Initialize map caching - call this after OfflineService.initialize()
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize FMTC with ObjectBox backend
      await FMTCObjectBoxBackend().initialise();

      // Create a single store for all map tiles
      _mainStore = FMTCStore('map_tiles');

      // Create store if it doesn't exist
      await _mainStore!.manage.create();

      _isInitialized = true;
      debugPrint('MapCacheService initialized');
    } catch (e) {
      debugPrint('Error initializing MapCacheService: $e');
    }
  }

  /// Get a cached tile provider that automatically caches tiles as they're loaded
  TileProvider getCachedTileProvider() {
    if (!_isInitialized || _mainStore == null) {
      return NetworkTileProvider();
    }
    // FMTC v10 API - getTileProvider() returns the provider directly
    return _mainStore!.getTileProvider();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized || _mainStore == null) return {};

    try {
      final stats = await _mainStore!.stats.all;

      return {
        'tiles': stats.length,
        'size': stats.size,
        'sizeMB': (stats.size / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }

  /// Clear all cached tiles
  Future<void> clearAllCache() async {
    if (!_isInitialized || _mainStore == null) return;

    try {
      await _mainStore!.manage.reset();
      await _mainStore!.manage.create();
      debugPrint('All map cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}
