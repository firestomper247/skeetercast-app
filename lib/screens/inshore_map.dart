import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/ocean_service.dart';
import '../services/captain_steve_service.dart';

/// Inshore fishing map widget
/// Shows NC sounds/estuaries with fishing layers and conditions

/// Comprehensive NC Artificial Reef descriptions from NC Division of Marine Fisheries
/// Data source: https://www.deq.nc.gov/about/divisions/marine-fisheries
const Map<String, Map<String, dynamic>> _inshoreReefData = {
  // === CONFIRMED ESTUARINE REEFS (Region: Sounds and Rivers) ===
  'AR-191': {
    'name': 'Black Walnut Point Reef',
    'location': 'Chowan River entrance, 2.6 nm from Chowan River Entrance Light',
    'waterBody': 'Chowan River',
    'region': 'Albemarle Sound',
    'depth': '8-12 ft',
    'materials': 'No material deployed yet (permitted site)',
    'targetSpecies': ['Striped bass', 'White perch', 'Catfish', 'Largemouth bass'],
    'description': 'Permitted estuarine reef site at the mouth of the Chowan River. Once materials are deployed, will provide habitat for freshwater and brackish species.',
    'tips': 'Best during striped bass spawning runs in spring. Try live bait or cut bait near structure.',
    'isInshore': true,
  },
  'AR-291': {
    'name': 'Bayview Reef',
    'location': '100 ft offshore Town of Bayview, near the mouth of Bath Creek',
    'waterBody': 'Pamlico River',
    'region': 'Pamlico Sound',
    'depth': '6-10 ft',
    'materials': 'Reef balls, concrete rubble',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Striped bass', 'Gray trout'],
    'description': 'Shallow estuarine reef near historic Bath, NC. Excellent year-round inshore fishing for multiple species.',
    'tips': 'Fish incoming tide with soft plastics or live shrimp. Great for kayak anglers.',
    'isInshore': true,
  },
  'AR-292': {
    'name': 'Quilley Point Reef',
    'location': '0.8 nm from Pungo River Daybeacon #5',
    'waterBody': 'Pungo River',
    'region': 'Pamlico Sound',
    'depth': '8-12 ft',
    'materials': 'Reef balls, granite aggregate',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Striped bass'],
    'description': 'Protected estuarine reef in the Pungo River. Provides shelter from wind and waves while offering excellent structure fishing.',
    'tips': 'Work the edges with soft plastics during moving water. Early morning and late evening best.',
    'isInshore': true,
  },
  'AR-296': {
    'name': 'Hatteras Island Business Association Reef',
    'location': '1.4 nm from Frisco Channel Light #6, 0.5 nm from Quilley Point',
    'waterBody': 'Pamlico Sound',
    'region': 'Cape Hatteras',
    'depth': '8-14 ft',
    'materials': 'Granite aggregate, reef balls',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Bluefish', 'Spanish mackerel'],
    'description': 'Popular sound-side reef near Frisco. Easy access from Hatteras Island boat ramps.',
    'tips': 'Great for popping corks with live shrimp. Watch for bird activity indicating baitfish schools.',
    'isInshore': true,
  },
  'AR-298': {
    'name': 'Ocracoke Reef',
    'location': '1.5 nm from Big Foot Slough Channel Light #13',
    'waterBody': 'Pamlico Sound',
    'region': 'Ocracoke',
    'depth': '8-15 ft',
    'materials': 'Reef balls, concrete structures',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Cobia', 'Spanish mackerel'],
    'description': 'Sound-side reef accessible from Ocracoke Island. Productive year-round for inshore species.',
    'tips': 'Target redfish on falling tide. Spanish mackerel and bluefish in summer months.',
    'isInshore': true,
  },
  'AR-392': {
    'name': 'New Bern Reef',
    'location': '1.8 nm from Union Point Park, New Bern',
    'waterBody': 'Neuse River',
    'region': 'Neuse River',
    'depth': '10-18 ft',
    'materials': 'Reef balls, concrete rubble, vessels',
    'targetSpecies': ['Striped bass', 'Speckled trout', 'Red drum', 'Catfish', 'Flounder'],
    'description': 'River reef near historic New Bern. Mix of brackish and freshwater species depending on season.',
    'tips': 'Striped bass run excellent in spring. Use soft plastics jigged near bottom.',
    'isInshore': true,
  },
  'AR-396': {
    'name': 'Oriental Reef',
    'location': '901 yards SE of Whitehurst Point near Oriental',
    'waterBody': 'Neuse River',
    'region': 'Pamlico Sound',
    'depth': '8-12 ft',
    'materials': 'Reef balls, aggregate',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Gray trout'],
    'description': 'Popular reef near the sailing capital of NC. Protected waters make for comfortable fishing.',
    'tips': 'Fish the morning bite with topwater lures. Popping corks effective all day.',
    'isInshore': true,
  },
  'AR-398': {
    'name': 'New River Estuarine Reef',
    'location': 'South of Town Point in the New River, 0.4 nm on 115° magnetic',
    'waterBody': 'New River',
    'region': 'New River',
    'depth': '8-15 ft',
    'materials': 'Reef balls, concrete structures',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Sheepshead', 'Black drum'],
    'description': 'Estuarine reef in the New River providing excellent inshore fishing near Camp Lejeune.',
    'tips': 'Sheepshead love fiddler crabs. Work tide changes for best action.',
    'isInshore': true,
  },

  // === INSHORE REEFS WITH MISSING/NULL REGION DATA (filled from NC DMF records) ===
  'AR-380': {
    'name': 'Spooner\'s Creek Reef',
    'location': 'Bogue Sound at mouth of Spooner\'s Creek, 0.5 miles from shore, Morehead City',
    'waterBody': 'Bogue Sound',
    'region': 'Crystal Coast',
    'depth': '5-8 ft',
    'coordinates': '34° 43.110\' N, 76° 48.020\' W',
    'materials': '96 reef balls (2 ft high, 3 ft wide, 900 lbs each) - deployed August 2018',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Sheepshead', 'Black drum', 'Pinfish'],
    'description': 'Shallow estuarine reef specifically designed for small boat and kayak access. Shallow enough for snorkeling. Reef balls quickly colonized by barnacles, sponges, and shellfish attracting baitfish and gamefish.',
    'tips': 'Excellent kayak fishing spot. Sight-cast to tailing redfish on low tide. Live shrimp under popping cork is deadly here.',
    'isInshore': true,
    'kayakFriendly': true,
    'snorkelable': true,
  },
  'AR-381': {
    'name': 'White Oak River Reef',
    'location': 'Bogue Sound area, near White Oak River entrance',
    'waterBody': 'Bogue Sound / White Oak River',
    'region': 'Crystal Coast',
    'depth': '6-10 ft',
    'coordinates': '34° 40.419\' N, 77° 6.509\' W',
    'materials': 'Reef balls - deployed 2018 (funded by Sport Fish Restoration grant)',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Sheepshead', 'Black drum'],
    'description': 'Companion reef to AR-380, built as part of the same estuarine reef project for small boat access.',
    'tips': 'Protected from ocean swells. Great for wade fishing at low tide. Target structure edges.',
    'isInshore': true,
    'kayakFriendly': true,
  },
  'AR-165': {
    'name': 'Roanoke Sound Reef',
    'location': 'Roanoke Sound, west of Nags Head',
    'waterBody': 'Roanoke Sound',
    'region': 'Outer Banks',
    'depth': '6-12 ft',
    'coordinates': '35° 41.672\' N, 75° 26.313\' W',
    'materials': 'Reef balls, granite aggregate',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Striped bass', 'Puppy drum'],
    'description': 'Sound-side reef behind the Outer Banks. Protected waters between Roanoke Island and the barrier islands.',
    'tips': 'Excellent fall fishing for big speckled trout. Work the tide changes around structure.',
    'isInshore': true,
  },
  'AR-197': {
    'name': 'Pamlico Sound Reef',
    'location': 'Pamlico Sound, north of Roanoke Island',
    'waterBody': 'Pamlico Sound',
    'region': 'Albemarle Sound',
    'depth': '8-15 ft',
    'coordinates': '35° 57.160\' N, 75° 42.368\' W',
    'materials': 'Golf ball-sized granite (4 acres), provides oyster substrate and fish habitat',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Striped bass', 'Gray trout'],
    'description': 'Large sound reef providing both oyster restoration habitat and fishing structure. Granite substrate excellent for oyster growth.',
    'tips': 'Drift fish the edges with soft plastics. Striped bass stack up here in winter.',
    'isInshore': true,
  },
  'AR-491': {
    'name': 'Cape Fear River Reef',
    'location': 'ICW/Cape Fear River area near Snow\'s Cut',
    'waterBody': 'Cape Fear River / ICW',
    'region': 'Cape Fear',
    'depth': '10-20 ft',
    'coordinates': '34° 2.852\' N, 77° 55.330\' W',
    'materials': 'Reef balls, concrete structures',
    'targetSpecies': ['Red drum', 'Flounder', 'Speckled trout', 'Black drum', 'Sheepshead', 'Striped bass'],
    'description': 'River/ICW reef in the Cape Fear region. Tidal influences create excellent ambush points for predatory fish.',
    'tips': 'Strong tidal currents - fish slack tide periods. Cut bait works well for black drum.',
    'isInshore': true,
  },
  'AR-293': {
    'name': 'Mouse Harbor Reef',
    'location': 'Mouse Harbor near Pamlico Point',
    'waterBody': 'Pamlico Sound',
    'region': 'Pamlico Sound',
    'depth': '8-12 ft',
    'materials': '200 concrete reef balls, 100 3D-printed reef units (high-density field) - deployed 2023',
    'targetSpecies': ['Speckled trout', 'Red drum', 'Flounder', 'Cobia', 'Spanish mackerel'],
    'description': 'Newly constructed 15-acre reef using innovative 3D-printed reef structures alongside traditional reef balls.',
    'tips': 'New reef still developing fish population. Excellent structure for sight-casting redfish.',
    'isInshore': true,
  },
};

/// Get fishing tips and info for a specific reef
Map<String, dynamic>? getReefInfo(String? reefId) {
  if (reefId == null) return null;
  return _inshoreReefData[reefId];
}

class InshoreMap extends StatefulWidget {
  const InshoreMap({super.key});

  @override
  State<InshoreMap> createState() => _InshoreMapState();
}

class _InshoreMapState extends State<InshoreMap> {
  final OceanService _oceanService = OceanService();
  final CaptainSteveService _steveService = CaptainSteveService();
  final MapController _mapController = MapController();

  // Inshore center (Beaufort/Core Sound area)
  static const LatLng _inshoreCenter = LatLng(34.72, -76.67);
  static const double _inshoreZoom = 11.0;

  // Map bounds for NC inshore waters
  static final _maxBounds = LatLngBounds(
    const LatLng(33.5, -78.7),
    const LatLng(36.6, -75.4),
  );

  // Base layer
  bool _useSatellite = true;

  // Layer toggles
  bool _showOysterBeds = true;
  bool _showArtificialReefs = true;
  bool _showSeagrass = false;
  bool _showBoatRamps = true;
  bool _showUserSpots = true;

  // Layer data (GeoJSON features)
  List<Map<String, dynamic>> _oysterBeds = [];
  List<Map<String, dynamic>> _artificialReefs = [];
  List<Map<String, dynamic>> _seagrass = [];
  List<Map<String, dynamic>> _boatRamps = [];
  List<Map<String, dynamic>> _userSpots = [];

  // Conditions
  Map<String, dynamic>? _conditions;
  bool _conditionsLoading = true;

  // UI state
  bool _showLayerMenu = false;
  bool _isLoadingLayers = true;

  // Layer colors
  static const _oysterColor = Color(0xFFFF9800);
  static const _reefColor = Color(0xFFF44336);
  static const _seagrassColor = Color(0xFF4CAF50);
  static const _boatRampColor = Color(0xFF2196F3);
  static const _userSpotColor = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadConditions(_inshoreCenter.latitude, _inshoreCenter.longitude),
      _loadLayers(),
      _loadUserSpots(),
    ]);
  }

  Future<void> _loadConditions(double lat, double lon) async {
    setState(() => _conditionsLoading = true);
    try {
      final data = await _oceanService.getInshoreConditions(lat, lon);
      if (mounted) {
        setState(() {
          _conditions = data;
          _conditionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _conditionsLoading = false);
    }
  }

  Future<void> _loadLayers() async {
    setState(() => _isLoadingLayers = true);
    try {
      final results = await Future.wait([
        _oceanService.getInshoreLayer('oysterBeds'),
        _oceanService.getInshoreLayer('artificialReefs'),
        _oceanService.getInshoreLayer('seagrass'),
        _oceanService.getInshoreLayer('boatRamps'),
      ]);

      if (mounted) {
        setState(() {
          _oysterBeds = _extractFeatures(results[0]);
          // Filter to only show TRUE inshore reefs (not ocean reefs)
          _artificialReefs = _filterInshoreReefs(_extractFeatures(results[1]));
          _seagrass = _extractFeatures(results[2]);
          _boatRamps = _extractFeatures(results[3]);
          _isLoadingLayers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLayers = false);
    }
  }

  Future<void> _loadUserSpots() async {
    try {
      final spots = await _oceanService.getUserSpots();
      if (mounted) {
        // Filter for inshore spots
        setState(() {
          _userSpots = spots.where((s) {
            final lat = s['latitude'] as double? ?? 0;
            final lon = s['longitude'] as double? ?? 0;
            // NC inshore bounds
            return lat > 33.5 && lat < 36.6 && lon > -78.7 && lon < -75.4;
          }).toList();
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  List<Map<String, dynamic>> _extractFeatures(Map<String, dynamic>? geojson) {
    if (geojson == null) return [];
    final features = geojson['features'] as List<dynamic>? ?? [];
    return features.cast<Map<String, dynamic>>();
  }

  /// Filter artificial reefs to only show TRUE inshore/estuarine reefs
  /// Ocean reefs should NOT appear on the inshore map
  List<Map<String, dynamic>> _filterInshoreReefs(List<Map<String, dynamic>> allReefs) {
    return allReefs.where((feature) {
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final reefId = props['REEF__'] as String?;
      final region = props['REGION'] as String?;

      // Include if region is "Sounds and Rivers" (confirmed estuarine)
      if (region == 'Sounds and Rivers') return true;

      // Include if we have it in our inshore reef database (manually verified)
      if (reefId != null && _inshoreReefData.containsKey(reefId)) return true;

      // Exclude all other reefs (ocean reefs like Cape Hatteras, Cape Lookout, etc.)
      return false;
    }).toList();
  }

  void _onMapMoved() {
    final center = _mapController.camera.center;
    _loadConditions(center.latitude, center.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _inshoreCenter,
            initialZoom: _inshoreZoom,
            minZoom: 8,
            maxZoom: 18,
            cameraConstraint: CameraConstraint.contain(bounds: _maxBounds),
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                // Debounce condition updates
                Future.delayed(const Duration(milliseconds: 500), _onMapMoved);
              }
            },
          ),
          children: [
            // Base layer
            TileLayer(
              urlTemplate: _useSatellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.skeetercast.app',
            ),

            // Seagrass polygons (render first, below markers)
            if (_showSeagrass && _seagrass.isNotEmpty)
              PolygonLayer(
                polygons: _buildPolygons(_seagrass, _seagrassColor),
              ),

            // Oyster beds
            if (_showOysterBeds && _oysterBeds.isNotEmpty)
              MarkerLayer(markers: _buildMarkers(_oysterBeds, _oysterColor, Icons.circle, 'Oyster Sanctuary')),

            // Artificial reefs
            if (_showArtificialReefs && _artificialReefs.isNotEmpty)
              MarkerLayer(markers: _buildMarkers(_artificialReefs, _reefColor, Icons.waves, 'Artificial Reef')),

            // Boat ramps
            if (_showBoatRamps && _boatRamps.isNotEmpty)
              MarkerLayer(markers: _buildMarkers(_boatRamps, _boatRampColor, Icons.directions_boat, 'Boat Ramp')),

            // User spots
            if (_showUserSpots && _userSpots.isNotEmpty)
              MarkerLayer(markers: _buildUserSpotMarkers()),

            // Attribution
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('Esri'),
                TextSourceAttribution('NC DEQ'),
              ],
            ),
          ],
        ),

        // Top bar with layer toggle
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          child: _buildTopBar(theme),
        ),

        // Layer menu
        if (_showLayerMenu)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 8,
            child: _buildLayerMenu(theme),
          ),

        // Map controls
        Positioned(
          bottom: 180,
          right: 8,
          child: _buildMapControls(theme),
        ),

        // Conditions bar at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildConditionsBar(theme),
        ),

        // Loading indicator
        if (_isLoadingLayers)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Loading layers...'),
                  ],
                ),
              ),
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
          const Icon(Icons.water, color: Color(0xFF00BCD4)),
          const SizedBox(width: 8),
          Text(
            'Inshore Map',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Base layer toggle
          IconButton(
            icon: Icon(_useSatellite ? Icons.satellite_alt : Icons.map),
            tooltip: _useSatellite ? 'Switch to Streets' : 'Switch to Satellite',
            onPressed: () => setState(() => _useSatellite = !_useSatellite),
          ),
          // Layers button
          IconButton(
            icon: Icon(_showLayerMenu ? Icons.close : Icons.layers),
            onPressed: () => setState(() => _showLayerMenu = !_showLayerMenu),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerMenu(ThemeData theme) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layers', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildLayerToggle(theme, 'Oyster Sanctuaries', _oysterColor, _showOysterBeds, (v) => setState(() => _showOysterBeds = v)),
          _buildLayerToggle(theme, 'Artificial Reefs', _reefColor, _showArtificialReefs, (v) => setState(() => _showArtificialReefs = v)),
          _buildLayerToggle(theme, 'Seagrass/SAV', _seagrassColor, _showSeagrass, (v) => setState(() => _showSeagrass = v)),
          _buildLayerToggle(theme, 'Boat Ramps', _boatRampColor, _showBoatRamps, (v) => setState(() => _showBoatRamps = v)),
          _buildLayerToggle(theme, 'My Spots', _userSpotColor, _showUserSpots, (v) => setState(() => _showUserSpots = v)),
        ],
      ),
    );
  }

  Widget _buildLayerToggle(ThemeData theme, String label, Color color, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
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
          heroTag: 'inshore_zoom_in',
          onPressed: () {
            final newZoom = (_mapController.camera.zoom + 1).clamp(8.0, 18.0);
            _mapController.move(_mapController.camera.center, newZoom);
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'inshore_zoom_out',
          onPressed: () {
            final newZoom = (_mapController.camera.zoom - 1).clamp(8.0, 18.0);
            _mapController.move(_mapController.camera.center, newZoom);
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'inshore_center',
          onPressed: () => _mapController.move(_inshoreCenter, _inshoreZoom),
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  Widget _buildConditionsBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _conditionsLoading
              ? const Center(child: Text('Loading conditions...'))
              : _conditions == null
                  ? const Center(child: Text('Conditions unavailable'))
                  : _buildConditionsContent(theme),
        ),
      ),
    );
  }

  Widget _buildConditionsContent(ThemeData theme) {
    final waterTemp = _conditions?['waterTemp']?['temperature_f'] ?? 0;
    final tide = _conditions?['tide'] ?? {};
    final tideDir = tide['direction'] ?? 'unknown';
    final tideHours = tide['hoursToNext'] ?? 0;
    final tideNext = tide['nextType'] ?? '';
    final weather = _conditions?['weather'] ?? {};
    final windSpeed = weather['wind_speed_mph'] ?? 0;
    final windDir = weather['wind_direction'] ?? 'N';
    final moon = _conditions?['moon'] ?? {};
    final moonPhase = moon['phase'] ?? 'Unknown';
    final moonEmoji = moon['emoji'] ?? '🌙';
    final moonIllum = moon['illumination'] ?? 0;
    final chop = _conditions?['chop'] ?? {};
    final chopLevel = chop['level'] ?? 'Unknown';
    final chopColor = _parseChopColor(chop['color']);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildConditionItem(theme, '🌡️', '${waterTemp}°F', 'Water'),
          _buildConditionDivider(),
          _buildConditionItem(theme, tideDir == 'incoming' ? '🔼' : '🔽', tideDir, '${tideHours}h to $tideNext'),
          _buildConditionDivider(),
          _buildConditionItem(theme, '💨', '$windSpeed mph $windDir', 'Wind'),
          _buildConditionDivider(),
          _buildConditionItem(theme, moonEmoji, '$moonIllum%', moonPhase),
          _buildConditionDivider(),
          _buildConditionItem(theme, '🌊', chopLevel, 'Chop', valueColor: chopColor),
        ],
      ),
    );
  }

  Widget _buildConditionItem(ThemeData theme, String icon, String value, String label, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3));
  }

  Color _parseChopColor(String? colorStr) {
    if (colorStr == null) return Colors.grey;
    if (colorStr.startsWith('#')) {
      try {
        return Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  List<Marker> _buildMarkers(List<Map<String, dynamic>> features, Color color, IconData icon, String typeLabel) {
    final markers = <Marker>[];

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      if (geometry == null) continue;

      final type = geometry['type'] as String?;
      List<double>? coords;

      if (type == 'Point') {
        final c = geometry['coordinates'] as List<dynamic>?;
        if (c != null && c.length >= 2) {
          coords = [(c[0] as num).toDouble(), (c[1] as num).toDouble()];
        }
      } else if (type == 'Polygon' || type == 'MultiPolygon') {
        // Use centroid for polygon features
        coords = _getPolygonCentroid(geometry);
      }

      if (coords == null) continue;

      final lat = coords[1];
      final lon = coords[0];
      final name = props['REEF_NAME'] ?? props['LOCATION'] ?? props['BAA_NAME'] ?? props['name'] ?? typeLabel;

      // Add coordinates to props for Captain Steve
      final propsWithCoords = Map<String, dynamic>.from(props);
      propsWithCoords['_lat'] = lat;
      propsWithCoords['_lon'] = lon;

      markers.add(Marker(
        point: LatLng(lat, lon),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showFeatureInfo(name, typeLabel, propsWithCoords, color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ));
    }
    return markers;
  }

  List<double>? _getPolygonCentroid(Map<String, dynamic> geometry) {
    try {
      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) return null;

      List<dynamic> ring;
      if (geometry['type'] == 'MultiPolygon') {
        ring = (coords[0] as List<dynamic>)[0] as List<dynamic>;
      } else {
        ring = coords[0] as List<dynamic>;
      }

      double sumLon = 0, sumLat = 0;
      for (final point in ring) {
        sumLon += (point[0] as num).toDouble();
        sumLat += (point[1] as num).toDouble();
      }
      return [sumLon / ring.length, sumLat / ring.length];
    } catch (e) {
      return null;
    }
  }

  List<Polygon> _buildPolygons(List<Map<String, dynamic>> features, Color color) {
    final polygons = <Polygon>[];

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      final type = geometry['type'] as String?;
      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null) continue;

      if (type == 'Polygon') {
        final ring = coords[0] as List<dynamic>;
        final points = ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        polygons.add(Polygon(
          points: points,
          color: color.withOpacity(0.3),
          borderColor: color,
          borderStrokeWidth: 2,
        ));
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          final ring = (poly as List<dynamic>)[0] as List<dynamic>;
          final points = ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
          polygons.add(Polygon(
            points: points,
            color: color.withOpacity(0.3),
            borderColor: color,
            borderStrokeWidth: 2,
          ));
        }
      }
    }
    return polygons;
  }

  List<Marker> _buildUserSpotMarkers() {
    return _userSpots.map((spot) {
      final lat = spot['latitude'] as double? ?? 0;
      final lon = spot['longitude'] as double? ?? 0;
      final name = spot['name'] ?? 'My Spot';

      return Marker(
        point: LatLng(lat, lon),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showUserSpotInfo(spot),
          child: Container(
            decoration: BoxDecoration(
              color: _userSpotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  void _showFeatureInfo(String name, String typeLabel, Map<String, dynamic> props, Color color) {
    final theme = Theme.of(context);
    final reefNumber = props['REEF__'] as String?;

    // Check if we have detailed reef data
    final reefInfo = getReefInfo(reefNumber);

    if (reefInfo != null && typeLabel.contains('Reef')) {
      // Show detailed reef information sheet
      _showReefInfoSheet(reefNumber!, reefInfo, color);
    } else {
      // Show generic feature info (for boat ramps, oyster beds, etc.)
      _showGenericFeatureInfo(name, typeLabel, props, color);
    }
  }

  void _showReefInfoSheet(String reefId, Map<String, dynamic> reefInfo, Color color) {
    final theme = Theme.of(context);
    final name = reefInfo['name'] as String? ?? reefId;
    final location = reefInfo['location'] as String? ?? 'NC Inshore Waters';
    final waterBody = reefInfo['waterBody'] as String? ?? '';
    final region = reefInfo['region'] as String? ?? '';
    final depth = reefInfo['depth'] as String? ?? '';
    final materials = reefInfo['materials'] as String? ?? '';
    final description = reefInfo['description'] as String? ?? '';
    final tips = reefInfo['tips'] as String? ?? '';
    final targetSpecies = (reefInfo['targetSpecies'] as List<dynamic>?)?.cast<String>() ?? [];
    final isKayakFriendly = reefInfo['kayakFriendly'] == true;
    final isSnorkelable = reefInfo['snorkelable'] == true;
    final coordinates = reefInfo['coordinates'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: const Icon(Icons.waves, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reefId,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // Badges
                      if (isKayakFriendly || isSnorkelable)
                        Row(
                          children: [
                            if (isKayakFriendly)
                              Tooltip(
                                message: 'Kayak Friendly',
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('🛶', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            if (isSnorkelable) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: 'Snorkeling Depth',
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('🤿', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ],
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
                        // Location info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              if (waterBody.isNotEmpty || region.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  [waterBody, region].where((s) => s.isNotEmpty).join(' • '),
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                              if (coordinates != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'GPS: $coordinates',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Depth & Materials
                        Row(
                          children: [
                            if (depth.isNotEmpty)
                              Expanded(
                                child: _buildInfoCard(theme, '🌊', 'Depth', depth),
                              ),
                            if (depth.isNotEmpty && materials.isNotEmpty) const SizedBox(width: 12),
                            if (materials.isNotEmpty)
                              Expanded(
                                flex: 2,
                                child: _buildInfoCard(theme, '🪨', 'Structure', materials),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Target Species
                        if (targetSpecies.isNotEmpty) ...[
                          Text(
                            'Target Species',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: targetSpecies.map((species) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BCD4).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
                                ),
                                child: Text(
                                  species,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF00838F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        if (description.isNotEmpty) ...[
                          Text(
                            'About This Reef',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Fishing Tips
                        if (tips.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
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
                                    const Text('💡', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Fishing Tips',
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tips,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Current conditions
                        if (_conditions != null) ...[
                          Text(
                            'Current Conditions',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildCurrentConditionsCard(theme),
                          const SizedBox(height: 16),
                        ],

                        // Data source
                        Text(
                          'Data: NC Division of Marine Fisheries Artificial Reef Program',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(ThemeData theme, String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditionsCard(ThemeData theme) {
    final waterTemp = _conditions?['waterTemp']?['temperature_f'] ?? 0;
    final tide = _conditions?['tide'] ?? {};
    final tideDir = tide['direction'] ?? 'unknown';
    final weather = _conditions?['weather'] ?? {};
    final windSpeed = weather['wind_speed_mph'] ?? 0;
    final windDir = weather['wind_direction'] ?? 'N';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('🌡️', style: TextStyle(fontSize: 20)),
              Text('${waterTemp}°F', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('Water', style: theme.textTheme.labelSmall),
            ],
          ),
          Column(
            children: [
              Text(tideDir == 'incoming' ? '🔼' : '🔽', style: const TextStyle(fontSize: 20)),
              Text(tideDir, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('Tide', style: theme.textTheme.labelSmall),
            ],
          ),
          Column(
            children: [
              const Text('💨', style: TextStyle(fontSize: 20)),
              Text('$windSpeed mph', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(windDir, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenericFeatureInfo(String name, String typeLabel, Map<String, dynamic> props, Color color) {
    final theme = Theme.of(context);
    final reefNumber = props['REEF__'] as String?;
    final region = props['REGION'] as String?;
    final genLoc = props['GEN_LOC'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: const Icon(Icons.place, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reefNumber != null ? '$reefNumber - $name' : name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(typeLabel, style: theme.textTheme.bodySmall?.copyWith(color: color)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (reefNumber != null) _buildInfoRow('Reef #', reefNumber),
              if (region != null) _buildInfoRow('Region', region),
              if (genLoc != null) _buildInfoRow('Location', genLoc),
              if (props['Gen_Location'] != null) _buildInfoRow('Area', props['Gen_Location']),
              if (props['WATER_ACCE'] != null) _buildInfoRow('Water Access', props['WATER_ACCE']),
              if (props['CITY'] != null) _buildInfoRow('City', props['CITY']),
              if (props['COUNTY'] != null) _buildInfoRow('County', props['COUNTY']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _askCaptainSteve(name, typeLabel, props);
                  },
                  icon: const Icon(Icons.sailing),
                  label: const Text('Ask Captain Steve'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showUserSpotInfo(Map<String, dynamic> spot) {
    final theme = Theme.of(context);
    final name = spot['name'] ?? 'My Spot';
    final notes = spot['notes'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: _userSpotColor, shape: BoxShape.circle),
                    child: const Icon(Icons.star, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('My Saved Spot', style: TextStyle(color: _userSpotColor)),
                      ],
                    ),
                  ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(notes, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _askCaptainSteve(name, 'my saved spot', null);
                  },
                  icon: const Icon(Icons.sailing),
                  label: const Text('Ask Captain Steve'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _askCaptainSteve(String spotName, String spotType, [Map<String, dynamic>? props]) {
    // Generate context-aware question
    final now = DateTime.now();
    final month = _getMonthName(now.month);
    final timeOfDay = now.hour < 12 ? 'morning' : now.hour < 17 ? 'afternoon' : 'evening';

    String conditionText = '';
    if (_conditions != null) {
      final waterTemp = _conditions?['waterTemp']?['temperature_f'] ?? 0;
      final tide = _conditions?['tide'] ?? {};
      final tideDir = tide['direction'] ?? 'unknown';
      final weather = _conditions?['weather'] ?? {};
      final windSpeed = weather['wind_speed_mph'] ?? 0;
      final windDir = weather['wind_direction'] ?? 'N';
      final chop = _conditions?['chop'] ?? {};
      final chopLevel = chop['level'] ?? '';
      conditionText = ' Current conditions: water temp ${waterTemp}F, $tideDir tide, wind $windSpeed mph from $windDir${chopLevel.isNotEmpty ? ', $chopLevel chop' : ''}.';
    }

    // Extract reef-specific info
    final reefNumber = props?['REEF__'] as String?;
    final region = props?['REGION'] as String?;
    final genLoc = props?['GEN_LOC'] as String?;

    String question;
    if (spotType.contains('Oyster')) {
      final location = props?['LOCATION'] ?? props?['Gen_Location'] ?? spotName;
      question = "I'm fishing near $location oyster sanctuary in NC protected inshore waters this $timeOfDay in $month.$conditionText What species should I target here and what tactics work best around oyster beds?";
    } else if (spotType.contains('Reef')) {
      // Don't mention "reef" or any location - Haiku extracts and looks up locations
      // Just ask about inshore structure fishing generically
      question = "I want to fish around hard bottom structure in shallow NC sound waters (5-15 feet deep, protected from ocean swells) this $timeOfDay in $month.$conditionText What species like redfish, speckled trout, flounder, or drum should I target and what tactics work best?";
    } else if (spotType.contains('Boat Ramp')) {
      final city = props?['CITY'] as String?;
      final county = props?['COUNTY'] as String?;
      final locInfo = city != null ? ' near $city${county != null ? ', $county County' : ''}' : '';
      question = "I'm launching from $spotName boat ramp$locInfo in NC this $timeOfDay in $month.$conditionText What inshore species should I target nearby and where should I go?";
    } else if (spotType.contains('Seagrass')) {
      question = "I'm fishing over seagrass beds in NC inshore waters this $timeOfDay in $month.$conditionText What species should I target in the grass and what presentations work best?";
    } else {
      question = "I'm at my saved spot '$spotName' in NC inshore waters this $timeOfDay in $month.$conditionText Give me a quick fishing report - what should I target and how?";
    }

    _showSteveChat(question, spotName, reefNumber);
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  void _showSteveChat(String question, String spotName, [String? reefNumber]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _SteveChatSheet(
          question: question,
          spotName: reefNumber != null ? '$reefNumber - $spotName' : spotName,
          steveService: _steveService,
        );
      },
    );
  }
}

/// Captain Steve chat sheet widget
class _SteveChatSheet extends StatefulWidget {
  final String question;
  final String spotName;
  final CaptainSteveService steveService;

  const _SteveChatSheet({
    required this.question,
    required this.spotName,
    required this.steveService,
  });

  @override
  State<_SteveChatSheet> createState() => _SteveChatSheetState();
}

class _SteveChatSheetState extends State<_SteveChatSheet> {
  bool _isLoading = true;
  String? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    _askSteve();
  }

  Future<void> _askSteve() async {
    try {
      final result = await widget.steveService.chat(widget.question);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result != null && result['success'] == true) {
            _response = result['response'] as String?;
          } else if (result?['requires_auth'] == true) {
            _error = 'Sign in to ask Captain Steve for fishing advice!';
          } else if (result?['requires_upgrade'] == true) {
            _error = 'Upgrade to Plus or higher to chat with Captain Steve!';
          } else {
            _error = result?['error'] ?? 'Captain Steve is taking a break. Try again later!';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not reach Captain Steve. Check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🎣', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Captain Steve',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'About: ${widget.spotName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Captain Steve is checking the conditions...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _response ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}
