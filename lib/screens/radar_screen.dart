import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/radar_service.dart';
import '../services/api_config.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final RadarService _radarService = RadarService();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _alerts = [];
  bool _showRadar = false;  // Disabled by default - tiles not available yet
  bool _showSatellite = false;
  
  // Default to NC Outer Banks area
  static const LatLng _defaultCenter = LatLng(35.5, -75.5);
  static const double _defaultZoom = 7.0;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final response = await _radarService.getActiveWarnings();
    if (response != null && response['warnings'] is List) {
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(response['warnings']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_defaultCenter, _defaultZoom);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 4,
              maxZoom: 12,
            ),
            children: [
              // Base map layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skeetercast.app',
              ),
              // Radar overlay
              if (_showRadar)
                TileLayer(
                  urlTemplate: '${ApiConfig.radarBase}/tiles/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.skeetercast.app',
                ),
            ],
          ),
          // Layer controls
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LayerToggle(
                      label: 'Radar',
                      value: _showRadar,
                      onChanged: (v) => setState(() => _showRadar = v),
                    ),
                    _LayerToggle(
                      label: 'Satellite',
                      value: _showSatellite,
                      onChanged: (v) => setState(() => _showSatellite = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Alerts banner
          if (_alerts.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_alerts.length} Active Alert${_alerts.length > 1 ? 's' : ''}',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Show alerts detail
                      },
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _LayerToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
