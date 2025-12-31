import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/radar_service.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../config/tier_config.dart';
import '../widgets/upgrade_prompt.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final RadarService _radarService = RadarService();
  final MapController _mapController = MapController();

  // Default to central NC (covers entire state)
  static const LatLng _defaultCenter = LatLng(35.7, -79.5);
  static const double _defaultZoom = 7.0;

  // CONUS radar products (national mosaic)
  static const Map<String, String> _conusProducts = {
    'bref': 'Base Reflectivity',
    'cref': 'Composite',
    'echo_tops': 'Echo Tops',
    'precip_type': 'Precip Type',
  };

  // NEXRAD HD products (single station)
  static const Map<String, String> _nexradProducts = {
    'N0Q': 'Base Reflectivity',
    'N0U': 'Velocity',
    'N0S': 'Storm Velocity',
    'N0X': 'Diff Reflectivity',
    'N0C': 'Correlation Coef',
    'N0K': 'Specific Diff Phase',
  };

  // CONUS bounds from SkeeterCast server (lat/lon)
  // SW: (20, -130), NE: (55, -60)
  static const _radarBoundsSW = LatLng(20.0, -130.0);
  static const _radarBoundsNE = LatLng(55.0, -60.0);

  String _selectedConusProduct = 'bref'; // Default CONUS product
  String _selectedNexradProduct = 'N0Q'; // Default NEXRAD product

  // Animation state
  List<Map<String, dynamic>> _radarFrames = [];
  // Cache image providers for smooth animation
  final Map<String, NetworkImage> _imageCache = {};
  int _currentFrameIndex = 0;
  bool _isPlaying = false;
  Timer? _animationTimer;
  bool _isLoadingFrames = false;

  // NEXRAD HD state
  bool _isNexradHdMode = false;
  String? _currentNexradStation;
  Map<String, dynamic>? _nexradStations;
  static const double _nexradZoomThreshold = 8.0; // Switch to HD at this zoom level

  // NEXRAD station bounds (for HD mode overlay)
  LatLngBounds? _nexradBounds;

  // Overlay toggles
  bool _showRadar = true;
  bool _showSatellite = false;
  bool _showLightning = false;
  bool _showWarnings = true;

  // Overlay data
  List<Map<String, dynamic>> _warnings = [];
  List<Map<String, dynamic>> _lightningStrikes = [];
  String? _satelliteUrl;

  // Animation speed (ms between frames)
  int _animationSpeed = 500;

  @override
  void initState() {
    super.initState();
    _loadNexradStations();
    _loadRadarFrames();
    _loadWarnings();
  }

  Future<void> _loadNexradStations() async {
    try {
      final response = await http.get(
        Uri.parse('https://radar.skeetercast.com/api/nexrad/stations'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _nexradStations = json.decode(response.body) as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading NEXRAD stations: $e');
    }
  }

  String? _findNearestStation(LatLng center) {
    if (_nexradStations == null || _nexradStations!.isEmpty) return null;

    String? nearestStation;
    double minDistance = double.infinity;

    for (final entry in _nexradStations!.entries) {
      final stationId = entry.key;
      final stationData = entry.value as Map<String, dynamic>;
      final lat = (stationData['lat'] as num?)?.toDouble() ?? 0;
      final lon = (stationData['lon'] as num?)?.toDouble() ?? 0;

      // Simple distance calculation (good enough for this purpose)
      final distance = _calculateDistance(center.latitude, center.longitude, lat, lon);
      if (distance < minDistance) {
        minDistance = distance;
        nearestStation = stationId;
      }
    }

    return nearestStation;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula simplified
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLon = (lon2 - lon1) * 3.14159 / 180;
    final a = (dLat / 2) * (dLat / 2) +
              (dLon / 2) * (dLon / 2) *
              (lat1 * 3.14159 / 180).abs().clamp(0.5, 1.0);
    return a.abs();
  }

  void _onMapEvent(MapEvent event) {
    // Check zoom on any map event
    _checkZoomLevel();
  }

  void _checkZoomLevel() {
    final zoom = _mapController.camera.zoom;
    final center = _mapController.camera.center;
    final shouldBeHdMode = zoom >= _nexradZoomThreshold;

    if (shouldBeHdMode != _isNexradHdMode) {
      final nearestStation = shouldBeHdMode ? _findNearestStation(center) : null;

      // Clear existing frames before switching
      _animationTimer?.cancel();
      _isPlaying = false;

      setState(() {
        _radarFrames = [];
        _imageCache.clear();
        _isNexradHdMode = shouldBeHdMode;
        _currentNexradStation = nearestStation;
        _nexradBounds = null;
      });

      _loadRadarFrames();
    } else if (_isNexradHdMode) {
      // Check if we need to switch to a different station
      final nearestStation = _findNearestStation(center);
      if (nearestStation != _currentNexradStation) {
        _animationTimer?.cancel();
        _isPlaying = false;

        setState(() {
          _radarFrames = [];
          _imageCache.clear();
          _currentNexradStation = nearestStation;
          _nexradBounds = null;
        });

        _loadRadarFrames();
      }
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRadarFrames() async {
    setState(() => _isLoadingFrames = true);

    try {
      String url;
      if (_isNexradHdMode && _currentNexradStation != null) {
        // NEXRAD HD mode - fetch station-specific frames
        url = 'https://radar.skeetercast.com/api/radar/station/$_currentNexradStation/frames?product=$_selectedNexradProduct';
      } else {
        // CONUS mode - fetch national mosaic
        url = 'https://radar.skeetercast.com/api/radar/frames/conus/$_selectedConusProduct?tier=free&hours=2';
      }
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var frames = <Map<String, dynamic>>[];

        // Parse station bounds if in HD mode (from first frame's bounds)
        if (_isNexradHdMode && data['frames'] is List && (data['frames'] as List).isNotEmpty) {
          final firstFrame = data['frames'][0];
          if (firstFrame['bounds'] is List) {
            final bounds = firstFrame['bounds'] as List;
            // bounds format: [[lat1, lon1], [lat2, lon2]]
            final sw = bounds[0] as List;
            final ne = bounds[1] as List;
            _nexradBounds = LatLngBounds(
              LatLng((sw[0] as num).toDouble(), (sw[1] as num).toDouble()),
              LatLng((ne[0] as num).toDouble(), (ne[1] as num).toDouble()),
            );
          }
        }

        if (data['frames'] is List) {
          for (final frame in data['frames']) {
            final timestamp = frame['timestamp'] ?? '';
            // NEXRAD uses 'filepath', CONUS uses 'url'
            final imagePath = frame['filepath'] ?? frame['url'] ?? '';

            // Parse timestamp and build full image URL
            DateTime? frameTime;
            try {
              frameTime = DateTime.parse(timestamp);
            } catch (_) {
              frameTime = DateTime.now();
            }

            frames.add({
              'time': frameTime,
              'imageUrl': 'https://radar.skeetercast.com$imagePath',
              'timestamp': timestamp,
            });
          }
        }

        // CONUS frames come newest-first, NEXRAD comes oldest-first
        // Only reverse CONUS frames so animation plays forward in time
        if (!_isNexradHdMode) {
          frames = frames.reversed.toList();
        }

        // Pre-cache all radar images for smooth animation
        _imageCache.clear();
        for (final frame in frames) {
          final imageUrl = frame['imageUrl'] as String?;
          if (imageUrl != null && mounted) {
            final provider = NetworkImage(imageUrl);
            _imageCache[imageUrl] = provider;
            precacheImage(provider, context);
          }
        }

        setState(() {
          _radarFrames = frames;
          _currentFrameIndex = frames.isNotEmpty ? frames.length - 1 : 0; // Start at most recent (last in list)
          _isLoadingFrames = false;
        });
      } else {
        setState(() {
          _radarFrames = [];
          _isLoadingFrames = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading radar frames: $e');
      setState(() {
        _radarFrames = [];
        _isLoadingFrames = false;
      });
    }
  }

  Future<void> _loadWarnings() async {
    try {
      final response = await _radarService.getActiveWarnings();
      if (response != null && response['warnings'] is List) {
        setState(() {
          _warnings = List<Map<String, dynamic>>.from(response['warnings']);
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadLightning() async {
    try {
      final response = await _radarService.getLightning(30);
      if (response != null && response['strikes'] is List) {
        setState(() {
          _lightningStrikes = List<Map<String, dynamic>>.from(response['strikes']);
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadSatellite() async {
    try {
      final response = await _radarService.getSatelliteLatest('geocolor');
      if (response != null && response['url'] != null) {
        setState(() {
          _satelliteUrl = response['url'];
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _animationTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _animationTimer = Timer.periodic(
        Duration(milliseconds: _animationSpeed),
        (_) {
          setState(() {
            _currentFrameIndex = (_currentFrameIndex + 1) % _radarFrames.length;
          });
        },
      );
    }
  }

  void _stepFrame(int direction) {
    if (_radarFrames.isEmpty) return;
    setState(() {
      _currentFrameIndex = (_currentFrameIndex + direction) % _radarFrames.length;
      if (_currentFrameIndex < 0) _currentFrameIndex = _radarFrames.length - 1;
    });
  }

  String? _getCurrentRadarImageUrl() {
    if (_radarFrames.isEmpty || _currentFrameIndex >= _radarFrames.length) {
      return null;
    }
    return _radarFrames[_currentFrameIndex]['imageUrl'] as String?;
  }

  ImageProvider? _getCurrentRadarImage() {
    final url = _getCurrentRadarImageUrl();
    if (url == null) return null;
    // Return cached provider for smooth animation
    return _imageCache[url] ?? NetworkImage(url);
  }

  String _getCurrentFrameTime() {
    if (_radarFrames.isEmpty || _currentFrameIndex >= _radarFrames.length) {
      return '--:--';
    }
    final frame = _radarFrames[_currentFrameIndex];
    final frameTime = frame['time'] as DateTime?;
    if (frameTime != null) {
      // Convert to local time for display
      final local = frameTime.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 4,
              maxZoom: 12,
              onMapEvent: _onMapEvent,
            ),
            children: [
              // Base map layer with attribution
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skeetercast.app',
              ),

              // Radar overlay from SkeeterCast server (full pre-rendered images)
              // Stack all frames and only show current one for smooth animation
              if (_showRadar && _radarFrames.isNotEmpty)
                ...List.generate(_radarFrames.length, (index) {
                  final imageUrl = _radarFrames[index]['imageUrl'] as String?;
                  if (imageUrl == null) return const SizedBox.shrink();
                  final provider = _imageCache[imageUrl] ?? NetworkImage(imageUrl);
                  // Use NEXRAD bounds in HD mode, CONUS bounds otherwise
                  final bounds = _isNexradHdMode && _nexradBounds != null
                      ? _nexradBounds!
                      : LatLngBounds(_radarBoundsSW, _radarBoundsNE);
                  return OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        bounds: bounds,
                        imageProvider: provider,
                        opacity: index == _currentFrameIndex ? 0.8 : 0.0,
                      ),
                    ],
                  );
                }),

              // Attribution overlay
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  TextSourceAttribution('NOAA/NWS Radar via SkeeterCast'),
                ],
              ),

              // Lightning markers
              if (_showLightning && _lightningStrikes.isNotEmpty)
                MarkerLayer(
                  markers: _lightningStrikes.map((strike) {
                    final lat = strike['lat'] as double? ?? 0;
                    final lon = strike['lon'] as double? ?? 0;
                    return Marker(
                      point: LatLng(lat, lon),
                      width: 20,
                      height: 20,
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.yellow,
                        size: 20,
                      ),
                    );
                  }).toList(),
                ),

              // Warning polygons would go here (simplified for now)
              if (_showWarnings && _warnings.isNotEmpty)
                MarkerLayer(
                  markers: _warnings.take(20).map((warning) {
                    // Use center point of warning area
                    final lat = warning['centroid_lat'] as double? ?? 35.5;
                    final lon = warning['centroid_lon'] as double? ?? -75.5;
                    final event = warning['event'] ?? 'Warning';

                    Color warningColor = Colors.orange;
                    if (event.toString().toLowerCase().contains('tornado')) {
                      warningColor = Colors.red;
                    } else if (event.toString().toLowerCase().contains('flood')) {
                      warningColor = Colors.green.shade800;
                    } else if (event.toString().toLowerCase().contains('thunder')) {
                      warningColor = Colors.orange;
                    }

                    return Marker(
                      point: LatLng(lat, lon),
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.warning_amber,
                        color: warningColor,
                        size: 30,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: _buildTopBar(theme),
          ),

          // NEXRAD HD indicator
          if (_isNexradHdMode && _currentNexradStation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hd, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'NEXRAD: $_currentNexradStation',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Layer controls
          Positioned(
            top: MediaQuery.of(context).padding.top + (_isNexradHdMode ? 110 : 70),
            right: 8,
            child: _buildLayerControls(theme),
          ),

          // Map controls
          Positioned(
            bottom: 140,
            right: 8,
            child: _buildMapControls(theme),
          ),

          // Animation controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildAnimationControls(theme),
          ),

          // Warnings banner
          if (_warnings.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 8,
              right: 8,
              child: _buildWarningsBanner(theme),
            ),

          // Loading indicator
          if (_isLoadingFrames)
            Positioned(
              top: MediaQuery.of(context).padding.top + 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Loading radar...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    // Use appropriate products based on mode
    final products = _isNexradHdMode ? _nexradProducts : _conusProducts;
    final selectedProduct = _isNexradHdMode ? _selectedNexradProduct : _selectedConusProduct;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isNexradHdMode ? Icons.hd : Icons.radar),
            color: _isNexradHdMode ? Colors.green : null,
            onPressed: () {},
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: products.entries.map((entry) {
                  final isSelected = selectedProduct == entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (_isNexradHdMode) {
                              _selectedNexradProduct = entry.key;
                            } else {
                              _selectedConusProduct = entry.key;
                            }
                            _animationTimer?.cancel();
                            _isPlaying = false;
                          });
                          _loadRadarFrames();
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRadarFrames();
              _loadWarnings();
              if (_showLightning) _loadLightning();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayerControls(ThemeData theme) {
    final authService = Provider.of<AuthService>(context);
    final userTier = authService.tier;
    final hasPlusAccess = hasAccess(userTier, 'plus');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayerToggle(
            theme,
            icon: Icons.radar,
            label: 'Radar',
            color: Colors.green,
            isActive: _showRadar,
            onTap: () => setState(() => _showRadar = !_showRadar),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.satellite_alt,
            label: 'Satellite',
            color: Colors.blue,
            isActive: _showSatellite && hasPlusAccess,
            isLocked: !hasPlusAccess,
            onTap: hasPlusAccess
                ? () {
                    setState(() => _showSatellite = !_showSatellite);
                    if (_showSatellite && _satelliteUrl == null) {
                      _loadSatellite();
                    }
                  }
                : () => _showUpgradePrompt('Satellite Imagery', 'plus'),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.flash_on,
            label: 'Lightning',
            color: Colors.yellow.shade700,
            isActive: _showLightning && hasPlusAccess,
            isLocked: !hasPlusAccess,
            onTap: hasPlusAccess
                ? () {
                    setState(() => _showLightning = !_showLightning);
                    if (_showLightning && _lightningStrikes.isEmpty) {
                      _loadLightning();
                    }
                  }
                : () => _showUpgradePrompt('Lightning Data', 'plus'),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.warning,
            label: 'Warnings',
            color: Colors.orange,
            isActive: _showWarnings,
            onTap: () => setState(() => _showWarnings = !_showWarnings),
          ),
        ],
      ),
    );
  }

  void _showUpgradePrompt(String featureName, String minTier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UpgradeInfoSheet(targetTier: minTier),
    );
  }

  Widget _buildLayerToggle(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock : icon,
              size: 18,
              color: isLocked
                  ? Colors.amber
                  : (isActive ? color : theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isLocked
                    ? Colors.amber
                    : (isActive ? color : theme.colorScheme.onSurfaceVariant),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 2),
              const Text('➕', style: TextStyle(fontSize: 8)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'radar_zoom_in',
          onPressed: () {
            final newZoom = (_mapController.camera.zoom + 1).clamp(4.0, 12.0);
            _mapController.move(_mapController.camera.center, newZoom);
            Future.delayed(const Duration(milliseconds: 100), _checkZoomLevel);
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'radar_zoom_out',
          onPressed: () {
            final newZoom = (_mapController.camera.zoom - 1).clamp(4.0, 12.0);
            _mapController.move(_mapController.camera.center, newZoom);
            Future.delayed(const Duration(milliseconds: 100), _checkZoomLevel);
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'radar_my_location',
          onPressed: () {
            _mapController.move(_defaultCenter, _defaultZoom);
          },
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  Widget _buildAnimationControls(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timeline slider
              Row(
                children: [
                  Text(
                    _getCurrentFrameTime(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentFrameIndex.toDouble(),
                      min: 0,
                      max: (_radarFrames.length - 1).clamp(0, double.infinity).toDouble(),
                      divisions: _radarFrames.length > 1 ? _radarFrames.length - 1 : null,
                      onChanged: _radarFrames.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _currentFrameIndex = value.round();
                              });
                            },
                    ),
                  ),
                  Text(
                    '${_currentFrameIndex + 1}/${_radarFrames.length}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              // Playback controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speed selector
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.speed),
                    tooltip: 'Animation speed',
                    onSelected: (speed) {
                      setState(() => _animationSpeed = speed);
                      if (_isPlaying) {
                        _animationTimer?.cancel();
                        _animationTimer = Timer.periodic(
                          Duration(milliseconds: _animationSpeed),
                          (_) {
                            setState(() {
                              _currentFrameIndex = (_currentFrameIndex + 1) % _radarFrames.length;
                            });
                          },
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 1000, child: Text('Slow (1s)')),
                      PopupMenuItem(value: 500, child: Text('Normal (0.5s)')),
                      PopupMenuItem(value: 250, child: Text('Fast (0.25s)')),
                      PopupMenuItem(value: 100, child: Text('Very Fast (0.1s)')),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Step back
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => _stepFrame(-1),
                  ),
                  // Play/Pause
                  FloatingActionButton(
                    heroTag: 'radar_play',
                    onPressed: _radarFrames.isEmpty ? null : _togglePlayPause,
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  // Step forward
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => _stepFrame(1),
                  ),
                  const SizedBox(width: 16),
                  // Loop indicator
                  Icon(
                    Icons.loop,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningsBanner(ThemeData theme) {
    if (_warnings.isEmpty) return const SizedBox.shrink();

    final warningCount = _warnings.length;
    final firstWarning = _warnings.first;
    final event = firstWarning['event'] ?? 'Weather Warning';

    return GestureDetector(
      onTap: () => _showWarningsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                warningCount == 1
                    ? event.toString()
                    : '$warningCount Active Warnings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }

  void _showWarningsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Active Warnings (${_warnings.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _warnings.length,
                    itemBuilder: (ctx, index) {
                      final warning = _warnings[index];
                      final event = warning['event'] ?? 'Warning';
                      final headline = warning['headline'] ?? '';
                      final area = warning['areaDesc'] ?? '';

                      Color warningColor = Colors.orange;
                      if (event.toString().toLowerCase().contains('tornado')) {
                        warningColor = Colors.red;
                      } else if (event.toString().toLowerCase().contains('flood')) {
                        warningColor = Colors.green.shade800;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: warningColor,
                          child: const Icon(Icons.warning, color: Colors.white, size: 20),
                        ),
                        title: Text(event.toString()),
                        subtitle: Text(
                          headline.toString().isNotEmpty
                              ? headline.toString()
                              : area.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
