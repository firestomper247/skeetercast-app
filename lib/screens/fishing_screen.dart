import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/ocean_service.dart';
import '../services/captain_steve_service.dart';
import 'inshore_map.dart';
import 'inlet_map.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> with SingleTickerProviderStateMixin {
  final OceanService _oceanService = OceanService();
  final CaptainSteveService _steveService = CaptainSteveService();
  final MapController _mapController = MapController();

  // Tab controller for swipeable tabs
  late TabController _tabController;

  // NC Outer Banks default view
  static const LatLng _defaultCenter = LatLng(35.2, -75.5);
  static const double _defaultZoom = 7.0;

  // View mode
  int _selectedMode = 0; // 0=Offshore, 1=Inshore, 2=Strike Times, 3=Inlets

  // Layer toggles
  bool _showSST = false;
  bool _showChlorophyll = false;
  bool _showSSH = false;
  bool _showMySpots = true;
  bool _showStevePicks = true;

  // Data
  Map<String, dynamic>? _speciesScores;
  Map<String, dynamic>? _strikeTimesData;
  Map<String, dynamic>? _sshData;
  Map<String, dynamic>? _steveRecommendations;
  List<Map<String, dynamic>> _userSpots = [];
  List<Map<String, dynamic>> _stevePicks = [];
  bool _isLoadingData = true;

  // Point data popup
  Map<String, dynamic>? _pointData;
  LatLng? _selectedPoint;
  bool _isLoadingPoint = false;
  bool _isSavingSpot = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedMode = _tabController.index;
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);

    try {
      final futures = await Future.wait([
        _steveService.getSpeciesScores(),
        _steveService.getStrikeTimes(),
        _oceanService.getSSHContours(),
        _oceanService.getUserSpots(),
        _steveService.getRecommendations(),
      ]);

      setState(() {
        _speciesScores = futures[0] as Map<String, dynamic>?;
        _strikeTimesData = futures[1] as Map<String, dynamic>?;
        _sshData = futures[2] as Map<String, dynamic>?;
        _userSpots = futures[3] as List<Map<String, dynamic>>;
        _steveRecommendations = futures[4] as Map<String, dynamic>?;
        _stevePicks = _extractStevePicks(_steveRecommendations);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  List<Map<String, dynamic>> _extractStevePicks(Map<String, dynamic>? data) {
    if (data == null) return [];
    final picks = <Map<String, dynamic>>[];
    final zones = data['zones'] as Map<String, dynamic>? ?? {};

    for (final entry in zones.entries) {
      final zoneName = entry.key;
      final zoneData = entry.value as Map<String, dynamic>? ?? {};
      final spots = zoneData['spots'] as List<dynamic>? ?? [];

      for (final spot in spots) {
        final coords = spot['coordinates'] as Map<String, dynamic>?;
        if (coords != null && coords['lat'] != null && coords['lon'] != null) {
          picks.add({
            'zone': zoneName,
            'lat': (coords['lat'] as num).toDouble(),
            'lon': (coords['lon'] as num).toDouble(),
            'score': spot['score'] ?? 0,
            'grade': spot['grade'] ?? '',
            'depth_ft': spot['depth_ft'],
            'reasons': spot['reasons'],
            'analysis': spot['captain_steve_analysis'],
          });
        }
      }
    }
    return picks;
  }

  Future<void> _loadUserSpots() async {
    final spots = await _oceanService.getUserSpots();
    setState(() => _userSpots = spots);
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _isLoadingPoint = true;
      _pointData = null;
    });

    try {
      final data = await _oceanService.getPointData(point.latitude, point.longitude);
      if (mounted) {
        setState(() {
          _pointData = data;
          _isLoadingPoint = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPoint = false;
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedPoint = null;
      _pointData = null;
    });
  }

  List<Polyline> _buildSSHContours() {
    final features = _sshData?['features'] as List<dynamic>? ?? [];
    final polylines = <Polyline>[];

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final properties = feature['properties'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) continue;

      final colorStr = properties?['color'] as String? ?? '#0000FF';
      final color = _parseColor(colorStr);

      final points = coords.map((coord) {
        if (coord is List && coord.length >= 2) {
          return LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          );
        }
        return null;
      }).whereType<LatLng>().toList();

      if (points.length >= 2) {
        polylines.add(Polyline(
          points: points,
          color: color.withOpacity(0.7),
          strokeWidth: 2,
        ));
      }
    }
    return polylines;
  }

  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hex = colorStr.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return Colors.blue;
  }

  void _showStevePickInfo(Map<String, dynamic> pick) {
    final theme = Theme.of(context);
    final score = pick['score'] as int? ?? 0;
    final grade = pick['grade'] ?? '';
    final zone = pick['zone'] ?? 'Unknown';
    final depth = pick['depth_ft'];
    final analysis = pick['analysis'] as String?;
    final reasons = pick['reasons'] as List<dynamic>?;

    final color = score >= 75
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Captain Steve's Pick",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${zone.toString().toUpperCase()} Zone • Grade: $grade',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location & Depth
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.location_on, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                '${pick['lat'].toStringAsFixed(2)}N\n${pick['lon'].abs().toStringAsFixed(2)}W',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (depth != null)
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(Icons.straighten, size: 20),
                                const SizedBox(height: 4),
                                Text(
                                  '${depth}ft\nDepth',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Reasons
                  if (reasons != null && reasons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Why This Spot:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(r.toString())),
                        ],
                      ),
                    )),
                  ],

                  // Captain Steve's Analysis
                  if (analysis != null && analysis.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text("Steve's Take:", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      analysis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate to Spot'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _mapController.move(
                          LatLng(pick['lat'], pick['lon']),
                          10,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSpotInfo(Map<String, dynamic> spot) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spot['name'] ?? 'Saved Spot',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final id = spot['id'] as int?;
                        if (id != null) {
                          await _oceanService.deleteSpot(id);
                          _loadUserSpots();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(spot['latitude'] as num?)?.toStringAsFixed(4) ?? '--'}N, '
                  '${((spot['longitude'] as num?)?.abs() ?? 0).toStringAsFixed(4)}W',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (spot['notes'] != null && spot['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(spot['notes'], style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text('Go to Spot'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController.move(
                        LatLng(
                          (spot['latitude'] as num).toDouble(),
                          (spot['longitude'] as num).toDouble(),
                        ),
                        10,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCurrentSpot() async {
    if (_selectedPoint == null) return;

    final nameController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Save Fishing Spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Spot Name',
                  hintText: 'e.g., My Secret Spot',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Good for tuna in summer',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && nameController.text.isNotEmpty) {
      setState(() => _isSavingSpot = true);
      final success = await _oceanService.saveSpot(
        name: nameController.text,
        lat: _selectedPoint!.latitude,
        lon: _selectedPoint!.longitude,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );
      if (success) {
        await _loadUserSpots();
        _clearSelection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spot saved!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save spot')),
          );
        }
      }
      setState(() => _isSavingSpot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Safe area + Tab bar at top
          Container(
            color: theme.colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.waves, size: 20), text: 'Offshore'),
                    Tab(icon: Icon(Icons.water, size: 20), text: 'Inshore'),
                    Tab(icon: Icon(Icons.schedule, size: 20), text: 'Strike Times'),
                    Tab(icon: Icon(Icons.anchor, size: 20), text: 'Inlets'),
                  ],
                ),
              ),
            ),
          ),
          // Content area
          Expanded(
            child: _buildTabContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_selectedMode) {
      case 1:
        return const InshoreMap();
      case 3:
        return const InletMap();
      case 2:
        return _buildStrikeTimesContent(theme);
      default:
        return _buildOffshoreContent(theme);
    }
  }

  Widget _buildStrikeTimesContent(ThemeData theme) {
    return Stack(
      children: [
        // Map background
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: 5,
            maxZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.skeetercast.app',
            ),
          ],
        ),
        // Strike times info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildStrikeTimesBar(theme),
        ),
      ],
    );
  }

  Widget _buildOffshoreContent(ThemeData theme) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            minZoom: 5,
            maxZoom: 12,
            onTap: _onMapTap,
          ),
          children: [
            // Base map layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.skeetercast.app',
            ),

            // SST layer
            if (_showSST)
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate: _oceanService.getTileUrl('sst'),
                  userAgentPackageName: 'com.skeetercast.app',
                  tileProvider: NetworkTileProvider(),
                ),
              ),

            // Chlorophyll layer
            if (_showChlorophyll)
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate: _oceanService.getTileUrl('chlorophyll'),
                  userAgentPackageName: 'com.skeetercast.app',
                  tileProvider: NetworkTileProvider(),
                ),
              ),

            // SSH Contours layer
            if (_showSSH && _sshData != null)
              PolylineLayer(
                polylines: _buildSSHContours(),
              ),

            // Steve's Picks
            if (_showStevePicks && _stevePicks.isNotEmpty)
              MarkerLayer(
                markers: _stevePicks.map((pick) {
                  final score = pick['score'] as int? ?? 0;
                  final color = score >= 75
                      ? Colors.green
                      : score >= 60
                          ? Colors.orange
                          : Colors.red;
                  return Marker(
                    point: LatLng(pick['lat'], pick['lon']),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showStevePickInfo(pick),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // User saved spots
            if (_showMySpots && _userSpots.isNotEmpty)
              MarkerLayer(
                markers: _userSpots.map((spot) {
                  return Marker(
                    point: LatLng(
                      (spot['latitude'] as num).toDouble(),
                      (spot['longitude'] as num).toDouble(),
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showSpotInfo(spot),
                      child: const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Selected point marker
            if (_selectedPoint != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint!,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Layer controls
        Positioned(
          top: 8,
          right: 8,
          child: _buildLayerControls(theme),
        ),

        // Map controls
        Positioned(
          bottom: _selectedPoint != null ? 220 : 100,
          right: 8,
          child: _buildMapControls(theme),
        ),

        // Point data panel
        if (_selectedPoint != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPointDataPanel(theme),
          ),

        // Bottom info bar (when no point selected)
        if (_selectedPoint == null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomInfoBar(theme),
          ),

        // Loading indicator
        if (_isLoadingData)
          Positioned(
            top: 60,
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
                    const Text('Loading fishing data...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLayerControls(ThemeData theme) {
    if (_selectedMode == 2) {
      // Strike times mode - no layers
      return const SizedBox.shrink();
    }

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
            icon: Icons.thermostat,
            label: 'MUR SST',
            color: Colors.red,
            isActive: _showSST,
            onTap: () => setState(() => _showSST = !_showSST),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.grass,
            label: 'Chloro',
            color: Colors.green,
            isActive: _showChlorophyll,
            onTap: () => setState(() => _showChlorophyll = !_showChlorophyll),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.waves,
            label: 'SSH Anomaly',
            color: Colors.purple,
            isActive: _showSSH,
            onTap: () => setState(() => _showSSH = !_showSSH),
          ),
          const Divider(height: 1),
          _buildLayerToggle(
            theme,
            icon: Icons.anchor,
            label: "Steve's Picks",
            color: Colors.teal,
            isActive: _showStevePicks,
            onTap: () => setState(() => _showStevePicks = !_showStevePicks),
          ),
          _buildLayerToggle(
            theme,
            icon: Icons.star,
            label: 'My Spots',
            color: Colors.orange,
            isActive: _showMySpots,
            onTap: () => setState(() => _showMySpots = !_showMySpots),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerToggle(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? color : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
          heroTag: 'zoom_in',
          onPressed: () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'zoom_out',
          onPressed: () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            );
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'my_location',
          onPressed: () {
            _mapController.move(_defaultCenter, _defaultZoom);
          },
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  Widget _buildPointDataPanel(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ocean Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedPoint!.latitude.toStringAsFixed(4)}N, ${_selectedPoint!.longitude.abs().toStringAsFixed(4)}W',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  ),
                ],
              ),
            ),
            // Data content
            if (_isLoadingPoint)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_pointData != null)
              _buildPointDataContent(theme)
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No ocean data available at this location',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Save Spot button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isSavingSpot
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star_border),
                  label: const Text('Save This Spot'),
                  onPressed: _isSavingSpot ? null : _saveCurrentSpot,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointDataContent(ThemeData theme) {
    // Data is nested under 'data' key from API
    final rawData = _pointData!;
    final data = rawData['data'] as Map<String, dynamic>? ?? rawData;

    // Extract nested values with correct field names from API
    final sst = data['sst'] as Map<String, dynamic>?;
    final chloro = data['chlorophyll'] as Map<String, dynamic>?;
    final waves = data['waves'] as Map<String, dynamic>?;
    final currents = data['currents'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDataCard(
                  theme,
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: sst != null
                      ? '${(sst['temperature_f'] as num?)?.toStringAsFixed(1) ?? '--'}°F'
                      : '--',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDataCard(
                  theme,
                  icon: Icons.grass,
                  label: 'Chlorophyll',
                  value: chloro != null
                      ? '${(chloro['chlorophyll_mg_m3'] as num?)?.toStringAsFixed(2) ?? '--'} mg/m³'
                      : '--',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDataCard(
                  theme,
                  icon: Icons.waves,
                  label: 'Waves',
                  value: waves != null
                      ? '${(waves['wave_height_ft'] as num?)?.toStringAsFixed(1) ?? '--'} ft'
                      : '--',
                  subtitle: waves != null
                      ? '${(waves['wave_period_sec'] as num?)?.toStringAsFixed(0) ?? '--'}s @ ${(waves['wave_direction_deg'] as num?)?.toStringAsFixed(0) ?? '--'}°'
                      : null,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDataCard(
                  theme,
                  icon: Icons.navigation,
                  label: 'Currents',
                  value: currents != null
                      ? '${(currents['speed_knots'] as num?)?.toStringAsFixed(1) ?? '--'} kt'
                      : '--',
                  subtitle: currents != null
                      ? '${(currents['direction_deg'] as num?)?.toStringAsFixed(0) ?? '--'}°'
                      : null,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoBar(ThemeData theme) {
    if (_selectedMode == 2) {
      // Strike Times mode
      return _buildStrikeTimesBar(theme);
    }

    // Fishing mode - show species summary
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.touch_app, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap anywhere on the ocean to see conditions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_speciesScores != null)
                TextButton(
                  onPressed: () => _showSpeciesScores(context),
                  child: const Text('Species'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrikeTimesBar(ThemeData theme) {
    final data = _strikeTimesData;
    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surface,
        child: const Text('Loading strike times...'),
      );
    }

    final today = data['today'] as Map<String, dynamic>?;
    final score = today?['fishing_score'] ?? 0;
    final phaseEmoji = today?['phase_emoji'] ?? '🌙';
    final phaseName = today?['phase_name'] ?? 'Unknown';
    final majorPeriods = today?['major_periods'] as List<dynamic>? ?? [];

    Color scoreColor;
    String scoreLabel;
    if (score >= 8) {
      scoreColor = Colors.green;
      scoreLabel = 'Fish On!';
    } else if (score >= 6) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 4) {
      scoreColor = Colors.yellow.shade700;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Slow';
    }

    // Format best times from major periods
    String bestTimes = '';
    if (majorPeriods.isNotEmpty) {
      bestTimes = majorPeriods.take(2).map((p) => p['start'] ?? '').join(', ');
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: scoreColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          scoreLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(phaseEmoji, style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                    Text(
                      phaseName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (bestTimes.isNotEmpty)
                      Text(
                        'Peak: $bestTimes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _showWeeklyStrikeTimes(context),
                child: const Text('View Week'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeeklyStrikeTimes(BuildContext context) {
    final week = _strikeTimesData?['week'] as List<dynamic>? ?? [];
    if (week.isEmpty) return;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('🎣', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        'Strike Times - 7 Day Forecast',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Week list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: week.length,
                    itemBuilder: (ctx, index) {
                      final day = week[index] as Map<String, dynamic>;
                      return _buildDayCard(theme, day, index == 0);
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

  Widget _buildDayCard(ThemeData theme, Map<String, dynamic> day, bool isToday) {
    final dayName = day['day_name'] ?? '';
    final date = day['date'] ?? '';
    final score = day['fishing_score'] ?? 0;
    final phaseEmoji = day['phase_emoji'] ?? '🌙';
    final phaseName = day['phase_name'] ?? '';
    final majorPeriods = day['major_periods'] as List<dynamic>? ?? [];
    final minorPeriods = day['minor_periods'] as List<dynamic>? ?? [];

    Color scoreColor;
    if (score >= 8) {
      scoreColor = Colors.green;
    } else if (score >= 6) {
      scoreColor = Colors.orange;
    } else if (score >= 4) {
      scoreColor = Colors.yellow.shade700;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Score badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isToday ? 'Today' : dayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                dayName,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(phaseEmoji, style: const TextStyle(fontSize: 24)),
                    Text(
                      phaseName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Major periods
            if (majorPeriods.isNotEmpty) ...[
              Text(
                'MAJOR (Best Fishing)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: majorPeriods.map((p) {
                  return Chip(
                    label: Text('${p['start']} - ${p['end']}'),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            // Minor periods
            if (minorPeriods.isNotEmpty) ...[
              Text(
                'MINOR (Good Fishing)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: minorPeriods.map((p) {
                  return Chip(
                    label: Text('${p['start']} - ${p['end']}'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSpeciesScores(BuildContext context) {
    final scores = _speciesScores?['species_scores'] as Map<String, dynamic>?;
    if (scores == null) return;

    final sortedScores = scores.entries.toList()
      ..sort((a, b) {
        final aScore = (a.value as Map)['score'] ?? 0;
        final bScore = (b.value as Map)['score'] ?? 0;
        return (bScore as int).compareTo(aScore as int);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
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
                  child: Text(
                    'Species Scores',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedScores.length,
                    itemBuilder: (ctx, index) {
                      final entry = sortedScores[index];
                      final data = entry.value as Map<String, dynamic>;
                      final name = data['species_name'] ?? entry.key;
                      final score = data['score'] ?? 0;
                      final assessment = data['assessment'] ?? '';

                      Color scoreColor;
                      if (score >= 70) {
                        scoreColor = Colors.green;
                      } else if (score >= 50) {
                        scoreColor = Colors.orange;
                      } else {
                        scoreColor = Colors.red;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scoreColor,
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: assessment.isNotEmpty
                            ? Text(
                                assessment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
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
