import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import 'channel_survey_screen.dart';

/// NC Inlet Conditions Page
/// Shows live conditions, tides, and channel surveys for NC inlets

/// Inlet data with caution levels and descriptions
const List<Map<String, dynamic>> _ncInlets = [
  {
    'id': 'oregon_inlet',
    'name': 'Oregon Inlet',
    'subtitle': 'Outer Banks',
    'lat': 35.796,
    'lon': -75.548,
    'barDepth': 4,
    'controllingDepth': 3,
    'tideStation': '8652587',
    'caution': 'extreme',
    'description': 'EXTREMELY DANGEROUS - Shifting bar with only 3-4 ft controlling depth. Local knowledge essential.',
    'emoji': '☠️',
  },
  {
    'id': 'hatteras_inlet',
    'name': 'Hatteras Inlet',
    'subtitle': 'Cape Hatteras',
    'lat': 35.21,
    'lon': -75.7,
    'barDepth': 5,
    'controllingDepth': 5,
    'tideStation': '8654467',
    'caution': 'extreme',
    'description': "EXTREMELY DANGEROUS - 'Ditch of Death'. Ocean bar not federally maintained. Shifting sands.",
    'emoji': '☠️',
  },
  {
    'id': 'ocracoke_inlet',
    'name': 'Ocracoke Inlet',
    'subtitle': 'Ocracoke Island',
    'lat': 35.0585,
    'lon': -76.0097,
    'barDepth': 6,
    'controllingDepth': 5,
    'tideStation': '8654467',
    'caution': 'high',
    'description': 'More reliable than neighboring Outer Banks inlets but still requires caution. Use Teaches Hole Channel.',
    'emoji': '🚨',
  },
  {
    'id': 'beaufort_inlet',
    'name': 'Beaufort Inlet',
    'subtitle': 'Morehead City',
    'lat': 34.6938,
    'lon': -76.6663,
    'barDepth': 47,
    'controllingDepth': 45,
    'tideStation': '8656483',
    'caution': 'low',
    'description': 'Well-maintained commercial harbor. Project depth 47 ft over ocean bar, 45 ft to Morehead City.',
    'emoji': '✅',
  },
  {
    'id': 'bogue_inlet',
    'name': 'Bogue Inlet',
    'subtitle': 'Emerald Isle',
    'lat': 34.6569,
    'lon': -77.0908,
    'barDepth': 8,
    'controllingDepth': 6,
    'tideStation': 'TEC2837',
    'caution': 'moderate',
    'description': 'Authorized channel 6-8 ft MLW. Subject to shoaling, periodic dredging required.',
    'emoji': '⚠️',
  },
  {
    'id': 'new_river_inlet',
    'name': 'New River Inlet',
    'subtitle': 'Camp Lejeune',
    'lat': 34.5408,
    'lon': -77.3347,
    'barDepth': 5,
    'controllingDepth': 5,
    'tideStation': 'TEC2793',
    'caution': 'high',
    'description': 'DANGEROUS - Bar not maintained, only 5 ft controlling depth. Highly variable shoaling.',
    'emoji': '🚨',
  },
  {
    'id': 'masonboro_inlet',
    'name': 'Masonboro Inlet',
    'subtitle': 'Wrightsville Beach',
    'lat': 34.1458,
    'lon': -77.7886,
    'barDepth': 7,
    'controllingDepth': 5,
    'tideStation': '8658163',
    'caution': 'high',
    'description': 'Unmaintained inlet, 5-7 ft controlling depth. Frequent shoaling, use extreme caution.',
    'emoji': '🚨',
  },
  {
    'id': 'carolina_beach_inlet',
    'name': 'Carolina Beach Inlet',
    'subtitle': 'Carolina Beach',
    'lat': 34.0333,
    'lon': -77.8833,
    'barDepth': 6,
    'controllingDepth': 5,
    'tideStation': 'TEC2863',
    'caution': 'high',
    'description': 'Unmaintained inlet. Only 5-6 ft controlling depth with frequent changes. Local knowledge required.',
    'emoji': '🚨',
  },
  {
    'id': 'cape_fear_river',
    'name': 'Cape Fear River',
    'subtitle': 'Wilmington/Southport',
    'lat': 33.9167,
    'lon': -78.0167,
    'barDepth': 42,
    'controllingDepth': 42,
    'tideStation': '8659084',
    'caution': 'low',
    'description': 'Major commercial port, well-maintained 42 ft channel. Project depth maintained year-round.',
    'emoji': '✅',
  },
];

class InletMap extends StatefulWidget {
  const InletMap({super.key});

  @override
  State<InletMap> createState() => _InletMapState();
}

class _InletMapState extends State<InletMap> {
  final MapController _mapController = MapController();

  // NC coast center
  static const LatLng _defaultCenter = LatLng(34.5, -76.5);
  static const double _defaultZoom = 7.0;

  // View mode: 0=List, 1=Map
  int _viewMode = 0;

  // Data
  Map<String, dynamic>? _tideData;
  Map<String, dynamic>? _waveData;
  Map<String, dynamic>? _windData;
  Map<String, dynamic>? _surveySummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _fetchJson(ApiConfig.inletTides),
        _fetchJson(ApiConfig.waveData),
        _fetchJson(ApiConfig.inletWinds),
        _fetchJson(ApiConfig.channelSurveySummary),
      ]);
      if (mounted) {
        setState(() {
          _tideData = results[0];
          _waveData = results[1];
          _windData = results[2];
          _surveySummary = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchJson(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching $url: $e');
    }
    return null;
  }

  Color _getCautionColor(String caution) {
    switch (caution) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'extreme':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCautionText(String caution) {
    switch (caution) {
      case 'low':
        return 'SAFE';
      case 'moderate':
        return 'CAUTION';
      case 'high':
        return 'HIGH RISK';
      case 'extreme':
        return 'EXTREME DANGER';
      default:
        return 'UNKNOWN';
    }
  }

  /// Get current wave height for inlet from SkeeterWave data
  /// Uses first hour in data (same as website) for consistency
  double? _getCurrentWaveHeight(String inletId) {
    final perInlet = _waveData?['per_inlet']?[inletId];
    if (perInlet == null) return null;

    final hours = perInlet['hours'] as List<dynamic>?;
    if (hours == null || hours.isEmpty) return null;

    // Use first available hour (same as website behavior)
    final current = hours.first;
    return (current['skeeter_ft'] as num?)?.toDouble() ??
           (current['ww3_ft'] as num?)?.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main content
        _viewMode == 0 ? _buildListView(theme) : _buildMapView(theme),

        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          child: _buildTopBar(theme),
        ),

        // Loading indicator
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Text('⚓', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'NC Inlet Conditions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // View toggle
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.list, size: 18)),
              ButtonSegment(value: 1, icon: Icon(Icons.map, size: 18)),
            ],
            selected: {_viewMode},
            onSelectionChanged: (s) => setState(() => _viewMode = s.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 80,
          bottom: 100,
        ),
        itemCount: _ncInlets.length + 1, // +1 for warning footer
        itemBuilder: (ctx, index) {
          if (index == _ncInlets.length) {
            return _buildWarningFooter(theme);
          }
          return _buildInletCard(theme, _ncInlets[index]);
        },
      ),
    );
  }

  Widget _buildInletCard(ThemeData theme, Map<String, dynamic> inlet) {
    final caution = inlet['caution'] as String;
    final color = _getCautionColor(caution);
    final surveyInfo = _surveySummary?['inlets']?[inlet['id']];
    final latestSurvey = surveyInfo?['latestSurvey'] as String?;
    final waveHeight = _getCurrentWaveHeight(inlet['id'] as String);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => _showInletDetails(inlet),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(inlet['emoji'] as String, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inlet['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      inlet['subtitle'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getCautionText(caution),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${inlet['controllingDepth']}ft depth',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (waveHeight != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🌊 ${waveHeight.toStringAsFixed(1)}ft',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue),
                          ),
                        ],
                      ],
                    ),
                    if (latestSurvey != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '📋 Survey: $latestSurvey',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: 6,
        maxZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.skeetercast.app',
        ),
        MarkerLayer(markers: _buildInletMarkers()),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('Esri'), TextSourceAttribution('NOAA')],
        ),
      ],
    );
  }

  List<Marker> _buildInletMarkers() {
    return _ncInlets.map((inlet) {
      final color = _getCautionColor(inlet['caution'] as String);
      return Marker(
        point: LatLng(inlet['lat'] as double, inlet['lon'] as double),
        width: 70,
        height: 65,
        child: GestureDetector(
          onTap: () => _showInletDetails(inlet),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                ),
                child: Text(inlet['emoji'] as String, style: const TextStyle(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (inlet['name'] as String).split(' ').first,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWarningFooter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('⚠️ IMPORTANT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          Text(
            'Bar conditions change constantly. Always check current weather, tides, and seek local knowledge before crossing any inlet. When in doubt, don\'t go out!',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tide predictions calculated using harmonic analysis • Valid through 2054',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showInletDetails(Map<String, dynamic> inlet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _InletDetailSheet(
        inlet: inlet,
        tideData: _tideData,
        waveData: _waveData,
        windData: _windData,
        surveySummary: _surveySummary,
      ),
    );
  }
}

/// Detailed inlet information sheet
class _InletDetailSheet extends StatefulWidget {
  final Map<String, dynamic> inlet;
  final Map<String, dynamic>? tideData;
  final Map<String, dynamic>? waveData;
  final Map<String, dynamic>? windData;
  final Map<String, dynamic>? surveySummary;

  const _InletDetailSheet({
    required this.inlet,
    required this.tideData,
    required this.waveData,
    required this.windData,
    required this.surveySummary,
  });

  @override
  State<_InletDetailSheet> createState() => _InletDetailSheetState();
}

class _InletDetailSheetState extends State<_InletDetailSheet> {
  List<Map<String, dynamic>> _upcomingTides = [];
  double? _currentWaveHeight;
  int _breakingProbability = 0;
  String _tidePhase = 'Unknown';
  String _tideStrength = '';
  Map<String, dynamic>? _nextHigh;
  Map<String, dynamic>? _nextLow;
  List<Map<String, dynamic>> _forecasts = [];
  Map<String, dynamic>? _windInfo;

  @override
  void initState() {
    super.initState();
    _loadConditions();
  }

  void _loadConditions() {
    _loadTides();
    _loadWaves();
    _loadWind();
  }

  void _loadTides() {
    final inletId = widget.inlet['id'] as String;
    final inletTides = widget.tideData?[inletId];
    if (inletTides == null) {
      debugPrint('No tide data for inlet: $inletId');
      return;
    }

    final now = DateTime.now();
    final currentYear = now.year.toString();
    debugPrint('Loading tides for $inletId, year $currentYear, now: $now');

    // Try current year, then next year if near year end
    List<dynamic> yearTides = inletTides['years']?[currentYear]?['tides'] as List<dynamic>? ?? [];
    debugPrint('Found ${yearTides.length} tides for $currentYear');

    // Also include next year's tides if available (for Dec 31 scenarios)
    final nextYear = (now.year + 1).toString();
    final nextYearTides = inletTides['years']?[nextYear]?['tides'] as List<dynamic>? ?? [];
    if (nextYearTides.isNotEmpty) {
      yearTides = [...yearTides, ...nextYearTides];
      debugPrint('Added ${nextYearTides.length} tides from $nextYear');
    }

    final upcoming = <Map<String, dynamic>>[];
    Map<String, dynamic>? nextHigh;
    Map<String, dynamic>? nextLow;

    for (final tide in yearTides) {
      // Parse local time string (same as website)
      // Format: "2025-12-30 03:15:00 EST"
      final timeStr = (tide['time'] as String? ?? '')
          .replaceAll(' EST', '').replaceAll(' EDT', '');

      // Parse as local time (replace space with T for ISO format)
      final tideTime = DateTime.tryParse(timeStr.replaceAll(' ', 'T'));
      if (tideTime == null) {
        debugPrint('Failed to parse tide time: ${tide['time']}');
        continue;
      }

      // Compare with current time (both in local)
      if (tideTime.isAfter(now)) {
        final tideInfo = {
          'type': tide['type'],
          'time': tideTime,
          'height_ft': tide['height_ft'],
        };
        upcoming.add(tideInfo);
        debugPrint('Added tide: ${tide['type']} at $tideTime (${tide['height_ft']} ft)');

        if (nextHigh == null && tide['type'] == 'High') nextHigh = tideInfo;
        if (nextLow == null && tide['type'] == 'Low') nextLow = tideInfo;

        if (upcoming.length >= 6) break;
      }
    }

    debugPrint('Total upcoming tides: ${upcoming.length}');

    // Calculate tide phase
    String phase = 'Unknown';
    String strength = '';
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      final minutesUntil = (next['time'] as DateTime).difference(now).inMinutes;

      if (next['type'] == 'High') {
        phase = 'Flood';
        if (minutesUntil < 30) {
          strength = 'Strong';
        } else if (minutesUntil < 90) {
          strength = 'Moderate';
        } else {
          strength = 'Weak';
        }
      } else {
        phase = 'Ebb';
        if (minutesUntil < 30) {
          strength = 'Strong';
        } else if (minutesUntil < 90) {
          strength = 'Moderate';
        } else {
          strength = 'Weak';
        }
      }
    }

    setState(() {
      _upcomingTides = upcoming;
      _nextHigh = nextHigh;
      _nextLow = nextLow;
      _tidePhase = phase;
      _tideStrength = strength;
    });
  }

  void _loadWaves() {
    final inletId = widget.inlet['id'] as String;
    final perInlet = widget.waveData?['per_inlet']?[inletId];
    if (perInlet == null) return;

    final hours = perInlet['hours'] as List<dynamic>?;
    if (hours == null || hours.isEmpty) return;

    // Use first hour as current (same as website)
    final current = hours.first;
    final currentWave = (current['skeeter_ft'] as num?)?.toDouble() ??
                        (current['ww3_ft'] as num?)?.toDouble() ?? 0.0;

    // Build forecast list from all hours
    final now = DateTime.now();
    final forecasts = <Map<String, dynamic>>[];
    for (int i = 0; i < hours.length && forecasts.length < 6; i++) {
      final hour = hours[i];
      final timeStr = hour['time_start'] as String?;
      if (timeStr == null) continue;
      final hourTime = DateTime.tryParse(timeStr);
      if (hourTime == null) continue;

      final waveHeight = (hour['skeeter_ft'] as num?)?.toDouble() ??
                        (hour['ww3_ft'] as num?)?.toDouble() ?? 0;
      forecasts.add({
        'hoursAhead': hourTime.difference(now).inHours.clamp(0, 999),
        'waveHeight': waveHeight,
      });
    }

    // Calculate breaking probability using website formula
    final controllingDepth = widget.inlet['controllingDepth'] as int;
    final breaking = _calcBreakingProb(currentWave, controllingDepth);

    setState(() {
      _currentWaveHeight = currentWave;
      _breakingProbability = breaking;
      _forecasts = forecasts;
    });
  }

  /// Breaking probability using same formula as website
  int _calcBreakingProb(double waveHeight, int controllingDepth) {
    final breakingRatio = waveHeight / controllingDepth;

    if (breakingRatio > 0.78) return 100;
    if (breakingRatio > 0.6) {
      return ((breakingRatio - 0.6) / 0.18 * 100).round();
    }
    if (waveHeight > 4) return 20;
    if (waveHeight > 2) return 5;
    return 0;
  }

  void _loadWind() {
    final inletId = widget.inlet['id'] as String;
    final inletWind = widget.windData?['inlets']?[inletId];
    if (inletWind != null) {
      setState(() => _windInfo = inletWind as Map<String, dynamic>?);
    }
  }

  /// Generate Captain Steve's commentary based on conditions (fallback style)
  String _generateSteveCommentary() {
    final inlet = widget.inlet;
    final name = inlet['name'] as String;
    final depth = inlet['controllingDepth'] as int;
    final waveText = _currentWaveHeight?.toStringAsFixed(1) ?? '?';

    if (_breakingProbability > 70) {
      return "Alright, listen up about $name. We've got $waveText ft waves hitting a $depth ft bar - that's breaking territory. This isn't the time to play hero. The tide's ${_tidePhase.toLowerCase()} and those waves are gonna stand up steep when they hit that shallow water. My advice? Wait it out. Check back in a few hours when conditions settle down. Better to miss a day of fishing than need the Coast Guard. Trust me on this one - I've seen too many boats get into trouble rushing these conditions.";
    } else if (depth <= 6) {
      return "$name - ah, the shallow one. Look, even with $waveText ft waves offshore, this $depth ft bar is gonna jack those waves up something fierce. Shallow inlets are trickier than folks think. Tide's ${_tidePhase.toLowerCase()} right now. If you're gonna cross, experienced hands only. Watch for that next slack tide - that's your window. Don't trust calm conditions to last - things can change fast out here. Local knowledge is king on this one.";
    } else {
      return "Looking at $name right now, we've got $waveText ft seas and a $depth ft controlling depth. That's manageable for experienced boaters, but don't get complacent. Tide's ${_tidePhase.toLowerCase()} - keep an eye on that because wind against tide will make things rougher than they look. This inlet's got decent depth, but conditions can change quick. Check the weather, watch your timing, and if something feels off, turn around. No shame in that. Forty years out here taught me to respect the ocean every single time.";
    }
  }

  Color _getCautionColor(String caution) {
    switch (caution) {
      case 'low': return Colors.green;
      case 'moderate': return Colors.blue;
      case 'high': return Colors.orange;
      case 'extreme': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _openChannelSurvey() {
    final inlet = widget.inlet;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelSurveyScreen(
          inletId: inlet['id'] as String,
          inletName: inlet['name'] as String,
          lat: inlet['lat'] as double,
          lon: inlet['lon'] as double,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inlet = widget.inlet;
    final caution = inlet['caution'] as String;
    final color = _getCautionColor(caution);
    final surveyInfo = widget.surveySummary?['inlets']?[inlet['id']];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(inlet['emoji'] as String, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inlet['name'] as String,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${inlet['subtitle']} • Live Predictions',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Conditions
                    _buildCurrentConditions(theme, color),
                    const SizedBox(height: 16),

                    // Tide Schedule
                    if (_upcomingTides.isNotEmpty) ...[
                      _buildTideSection(theme),
                      const SizedBox(height: 16),
                    ],

                    // Wave Forecast
                    if (_forecasts.isNotEmpty) ...[
                      _buildForecastSection(theme),
                      const SizedBox(height: 16),
                    ],

                    // Captain Steve's Assessment
                    _buildSteveSection(theme),
                    const SizedBox(height: 16),

                    // Channel Survey
                    if (surveyInfo != null) ...[
                      _buildSurveySection(theme, surveyInfo),
                      const SizedBox(height: 16),
                    ],

                    // Inlet Details
                    _buildDetailsSection(theme, inlet),
                    const SizedBox(height: 24),

                    // Data source
                    Text(
                      'Data: NOAA Tides & Currents, SkeeterWave Predictions, USACE eHydro Surveys',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentConditions(ThemeData theme, Color cautionColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌊 Current Conditions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildConditionCard(theme, 'WAVE HEIGHT', '${_currentWaveHeight?.toStringAsFixed(1) ?? "?"}ft', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildConditionCard(
                theme, 'BREAKING RISK', '$_breakingProbability%',
                _breakingProbability > 70 ? Colors.red : _breakingProbability > 40 ? Colors.orange : Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildConditionCard(theme, 'TIDE PHASE', '$_tidePhase\n$_tideStrength', Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _buildConditionCard(
                theme, 'WIND @ INLET',
                _windInfo != null
                    ? '${(_windInfo!['wind_speed_kt'] as num?)?.toStringAsFixed(0) ?? "?"}kt ${_windInfo!['wind_dir'] ?? ""}'
                    : 'N/A',
                Colors.grey,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTideSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌊 Tide Schedule (EST)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Next high/low summary
          Row(
            children: [
              if (_nextHigh != null) Expanded(child: _buildNextTideCard(theme, _nextHigh!, Colors.blue)),
              if (_nextHigh != null && _nextLow != null) const SizedBox(width: 12),
              if (_nextLow != null) Expanded(child: _buildNextTideCard(theme, _nextLow!, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          // Upcoming tides list
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next 6 Tides (${_upcomingTides.length} found):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ..._upcomingTides.map((tide) {
                  // Use same pattern as _buildNextTideCard which works
                  final tideType = tide['type'] as String? ?? 'N/A';
                  final tideTime = tide['time'] as DateTime?;
                  final heightFt = tide['height_ft'] as num?;
                  final timeStr = tideTime != null ? _formatDateTime(tideTime) : '??';
                  final heightStr = heightFt != null ? '${heightFt.toStringAsFixed(1)} ft' : '??';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: Text(
                            tideType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tideType == 'High' ? Colors.blue : Colors.orange,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            timeStr,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            heightStr,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextTideCard(ThemeData theme, Map<String, dynamic> tide, Color color) {
    final time = tide['time'] as DateTime;
    final height = tide['height_ft'] as num;
    final minutesUntil = time.difference(DateTime.now()).inMinutes;
    final isHigh = tide['type'] == 'High';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            isHigh ? '⬆️ NEXT HIGH' : '⬇️ NEXT LOW',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text('${height.toStringAsFixed(1)} ft'),
          if (minutesUntil > 0)
            Text(
              'in ${minutesUntil ~/ 60}h ${minutesUntil % 60}m',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 SkeeterWave Predictions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _forecasts.take(6).map((f) {
                final hours = f['hoursAhead'] as int;
                final wave = f['waveHeight'] as double;
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('+${hours}HR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('${wave.toStringAsFixed(1)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const Text('ft', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beats NOAA by 4-6x accuracy',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSteveSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚓', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Capt. Steve's Assessment", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('40 years of inlet experience', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _generateSteveCommentary(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveySection(ThemeData theme, Map<String, dynamic> surveyInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🗺️ USACE Channel Survey', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Latest Survey:', style: TextStyle(color: Colors.grey[600])),
              Text(surveyInfo['latestSurvey'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Surveys:', style: TextStyle(color: Colors.grey[600])),
              Text('${surveyInfo['surveyCount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openChannelSurvey,
              icon: const Icon(Icons.map),
              label: const Text('View Depth Survey Map'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme, Map<String, dynamic> inlet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Inlet Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailRow('Bar Depth', '${inlet['barDepth']} feet'),
          _buildDetailRow('Controlling Depth', '${inlet['controllingDepth']} feet'),
          _buildDetailRow('Coordinates', '${(inlet['lat'] as double).toStringAsFixed(4)}°N, ${(inlet['lon'] as double).abs().toStringAsFixed(4)}°W'),
          _buildDetailRow('Tide Station', inlet['tideStation'] as String),
          _buildDetailRow('Caution Level', (inlet['caution'] as String).toUpperCase()),
          const SizedBox(height: 8),
          Text(
            inlet['description'] as String,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDateTime(DateTime time) {
    final month = time.month;
    final day = time.day;
    return '$month/$day ${_formatTime(time)}';
  }
}
