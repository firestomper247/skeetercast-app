import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../services/api_config.dart';

/// Channel Survey Screen - Native depth survey map
/// Shows USACE depth surveys with pre-rendered surface images like the website

class ChannelSurveyScreen extends StatefulWidget {
  final String inletId;
  final String inletName;
  final double lat;
  final double lon;

  const ChannelSurveyScreen({
    super.key,
    required this.inletId,
    required this.inletName,
    required this.lat,
    required this.lon,
  });

  @override
  State<ChannelSurveyScreen> createState() => _ChannelSurveyScreenState();
}

class _ChannelSurveyScreenState extends State<ChannelSurveyScreen> {
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String? _error;
  LatLng? _userPosition;
  bool _showLegend = true;

  // Survey data
  List<String> _availableSurveys = [];
  String? _selectedSurvey;
  Map<String, dynamic>? _boundsData;
  List<Map<String, dynamic>> _depthPoints = [];

  // For depth popup on tap
  Map<String, dynamic>? _tappedDepth;

  @override
  void initState() {
    super.initState();
    _loadSurveySummary();
    _getUserLocation();
  }

  Future<void> _loadSurveySummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load survey summary to get available dates
      final summaryUrl = '${ApiConfig.mainSite}/data/depth_soundings/summary.json';
      final summaryResponse = await http.get(Uri.parse(summaryUrl)).timeout(const Duration(seconds: 15));

      if (summaryResponse.statusCode == 200) {
        final summaryData = json.decode(summaryResponse.body);
        final inletData = summaryData['inlets']?[widget.inletId];

        if (inletData != null) {
          final surveys = (inletData['surveys'] as List<dynamic>?)?.cast<String>() ?? [];
          setState(() {
            _availableSurveys = surveys;
            _selectedSurvey = surveys.isNotEmpty ? surveys.first : null;
          });

          if (_selectedSurvey != null) {
            await _loadSurveyData(_selectedSurvey!);
          }
        } else {
          // Try loading default survey
          await _loadSurveyData(null);
        }
      } else {
        // Try loading default survey without summary
        await _loadSurveyData(null);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load survey list: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSurveyData(String? surveyDate) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _boundsData = null;
      _depthPoints = [];
    });

    try {
      // Load bounds data for image overlay
      final boundsFileName = surveyDate != null
          ? '${widget.inletId}_${surveyDate}_bounds.json'
          : '${widget.inletId}_bounds.json';
      final boundsUrl = '${ApiConfig.mainSite}/data/depth_soundings/$boundsFileName';

      final boundsResponse = await http.get(Uri.parse(boundsUrl)).timeout(const Duration(seconds: 15));

      if (boundsResponse.statusCode == 200) {
        final bounds = json.decode(boundsResponse.body);
        setState(() {
          _boundsData = bounds;
        });
      }

      // Also load GeoJSON depth points for tap-to-query
      final jsonFileName = surveyDate != null
          ? '${widget.inletId}_$surveyDate.json'
          : '${widget.inletId}.json';
      final jsonUrl = '${ApiConfig.mainSite}/data/depth_soundings/$jsonFileName';

      final jsonResponse = await http.get(Uri.parse(jsonUrl)).timeout(const Duration(seconds: 30));

      if (jsonResponse.statusCode == 200) {
        final data = json.decode(jsonResponse.body);
        final features = data['features'] as List<dynamic>? ?? [];

        final points = <Map<String, dynamic>>[];
        for (final feature in features) {
          final geometry = feature['geometry'];
          final props = feature['properties'];
          if (geometry?['type'] == 'Point' && props != null) {
            final coords = geometry['coordinates'] as List<dynamic>;
            points.add({
              'lat': (coords[1] as num).toDouble(),
              'lon': (coords[0] as num).toDouble(),
              'depth': ((props['depth_ft'] as num?)?.toDouble() ?? 0).abs(),
            });
          }
        }

        setState(() {
          _depthPoints = points;
        });
      }

      // Fit map to survey bounds
      if (_boundsData != null && mounted) {
        final bounds = _boundsData!['bounds'] as List<dynamic>;
        final sw = LatLng((bounds[0] as List)[0], (bounds[0] as List)[1]);
        final ne = LatLng((bounds[1] as List)[0], (bounds[1] as List)[1]);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds(sw, ne),
                padding: const EdgeInsets.all(30),
              ),
            );
          }
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load survey: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Could not get user location: $e');
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_depthPoints.isEmpty) return;

    // Find nearest depth point
    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final p in _depthPoints) {
      final dist = sqrt(
        pow(p['lat'] - point.latitude, 2) +
        pow(p['lon'] - point.longitude, 2)
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = p;
      }
    }

    // Only show if within reasonable distance (about 50m)
    if (nearest != null && minDist < 0.0005) {
      setState(() {
        _tappedDepth = {
          'lat': nearest!['lat'],
          'lon': nearest['lon'],
          'depth': nearest['depth'],
        };
      });
    } else {
      setState(() {
        _tappedDepth = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.inletName, style: const TextStyle(fontSize: 16)),
            Text(
              'Channel Depth Survey',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showLegend ? Icons.layers : Icons.layers_outlined),
            onPressed: () => setState(() => _showLegend = !_showLegend),
            tooltip: 'Toggle Legend',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToUserLocation,
            tooltip: 'My Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSurveyData(_selectedSurvey),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.lat, widget.lon),
              initialZoom: 14,
              minZoom: 10,
              maxZoom: 18,
              onTap: _onMapTap,
            ),
            children: [
              // Satellite imagery
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.skeetercast.app',
              ),
              // Depth surface image overlay
              if (_boundsData != null && !_isLoading)
                _buildDepthOverlay(),
              // User location marker
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('⛵', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ],
                ),
              // Tapped depth popup marker
              if (_tappedDepth != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_tappedDepth!['lat'], _tappedDepth!['lon']),
                      width: 120,
                      height: 60,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_tappedDepth!['depth'] as double).toStringAsFixed(1)} ft',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getDepthTextColor(_tappedDepth!['depth']),
                              ),
                            ),
                            const Text('Below MLLW', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // Attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('USACE eHydro'),
                  TextSourceAttribution('Esri'),
                ],
              ),
            ],
          ),

          // Survey date selector
          if (_availableSurveys.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildDateSelector(theme),
            ),

          // Legend (simplified)
          if (_showLegend && !_isLoading)
            Positioned(
              left: 12,
              bottom: 80,
              child: _buildLegend(theme),
            ),

          // Loading
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading depth survey...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error
          if (_error != null && !_isLoading)
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _loadSurveyData(_selectedSurvey),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepthOverlay() {
    final bounds = _boundsData!['bounds'] as List<dynamic>;
    final imageFile = _boundsData!['image'] as String;
    final imageUrl = '${ApiConfig.mainSite}/data/depth_soundings/$imageFile';

    // Parse bounds: [[lat1, lon1], [lat2, lon2]]
    final sw = LatLng(
      (bounds[0] as List<dynamic>)[0] as double,
      (bounds[0] as List<dynamic>)[1] as double,
    );
    final ne = LatLng(
      (bounds[1] as List<dynamic>)[0] as double,
      (bounds[1] as List<dynamic>)[1] as double,
    );

    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: LatLngBounds(sw, ne),
          imageProvider: NetworkImage(imageUrl),
          opacity: 0.85,
        ),
      ],
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('📅 Survey Date:', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSurvey,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  isExpanded: true,
                  items: _availableSurveys.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(date, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedSurvey) {
                      setState(() {
                        _selectedSurvey = value;
                        _tappedDepth = null;
                      });
                      _loadSurveyData(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDepthTextColor(double depth) {
    if (depth < 4) return Colors.red;
    if (depth < 8) return Colors.orange;
    if (depth < 12) return Colors.green;
    return Colors.blue;
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Depth (ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
          const SizedBox(height: 6),
          // Compact gradient bar
          Container(
            width: 140,
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFF6600),
                  Color(0xFFFFFF00),
                  Color(0xFF00C864),
                  Color(0xFF0064FF),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text('4', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text('8', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text('12', style: TextStyle(fontSize: 9, color: Colors.grey)),
                Text('14+', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap for depth', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    // Calculate stats
    double minDepth = double.infinity;
    double maxDepth = 0;
    double sumDepth = 0;

    for (final point in _depthPoints) {
      final depth = point['depth'] as double;
      if (depth < minDepth) minDepth = depth;
      if (depth > maxDepth) maxDepth = depth;
      sumDepth += depth;
    }

    final avgDepth = _depthPoints.isNotEmpty ? sumDepth / _depthPoints.length : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Survey Stats',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildStatRow('Soundings', '${_depthPoints.length}'),
          _buildStatRow('Min Depth', '${minDepth.toStringAsFixed(1)} ft'),
          _buildStatRow('Max Depth', '${maxDepth.toStringAsFixed(1)} ft'),
          _buildStatRow('Avg Depth', '${avgDepth.toStringAsFixed(1)} ft'),
          if (_boundsData?['survey_date'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Survey: ${_boundsData!['survey_date']}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  void _goToUserLocation() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 16);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      _getUserLocation();
    }
  }
}
