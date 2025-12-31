import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';

class ReportConditionsScreen extends StatefulWidget {
  const ReportConditionsScreen({super.key});

  @override
  State<ReportConditionsScreen> createState() => _ReportConditionsScreenState();
}

class _ReportConditionsScreenState extends State<ReportConditionsScreen> {
  final ReportService _service = ReportService();

  bool _isQuickMode = true;
  bool _loading = false;
  bool _success = false;
  String? _error;
  Position? _position;
  bool _isOffshore = false;

  // Form fields
  String? _skyCondition;
  int? _airTemp;
  String? _windSpeed;
  String? _windDirection;
  int? _waterTemp;
  String? _waveHeight;
  String? _wavePeriod;
  String? _waterClarity;
  String? _fishingSuccess;
  String? _species;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied. Please enable in settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _position = position;
        // Simple offshore check: east of -79° lon and in NC waters
        _isOffshore = position.longitude > -79 &&
            position.latitude > 33 &&
            position.latitude < 37;
      });
    } catch (e) {
      setState(() => _error = 'Could not get location. Please enable GPS.');
    }
  }

  Future<void> _submitQuickReport() async {
    if (_position == null) {
      setState(() => _error = 'Location required');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      setState(() => _error = 'Please log in to submit reports');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.submitQuickReport(
      _position!.latitude,
      _position!.longitude,
    );

    setState(() => _loading = false);

    if (result.success) {
      setState(() => _success = true);
      // Show success for 2 seconds, then reset form
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _resetForm();
    } else {
      setState(() => _error = result.message);
    }
  }

  void _resetForm() {
    setState(() {
      _success = false;
      _skyCondition = null;
      _airTemp = null;
      _windSpeed = null;
      _windDirection = null;
      _waterTemp = null;
      _waveHeight = null;
      _wavePeriod = null;
      _waterClarity = null;
      _fishingSuccess = null;
      _species = null;
      _commentController.clear();
    });
  }

  Future<void> _submitDetailedReport() async {
    if (_position == null) {
      setState(() => _error = 'Location required');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      setState(() => _error = 'Please log in to submit reports');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final report = FieldReport(
      lat: _position!.latitude,
      lon: _position!.longitude,
      skyCondition: _skyCondition,
      airTemp: _airTemp,
      windSpeed: _windSpeed,
      windDirection: _windDirection,
      waterTemp: _waterTemp,
      waveHeight: _waveHeight,
      wavePeriod: _wavePeriod,
      waterClarity: _waterClarity,
      fishingSuccess: _fishingSuccess,
      species: _species,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
    );

    final result = await _service.submitDetailedReport(report);

    setState(() => _loading = false);

    if (result.success) {
      setState(() => _success = true);
      // Show success for 2 seconds, then reset form
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _resetForm();
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Conditions'),
      ),
      body: _success
          ? _buildSuccessView(theme)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location display
                  _buildLocationCard(theme),
                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Mode switch
                  _buildModeSwitch(theme),
                  const SizedBox(height: 20),

                  // Quick mode or detailed form
                  if (_isQuickMode)
                    _buildQuickMode(theme)
                  else
                    _buildDetailedForm(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 64, color: Colors.green.shade600),
          ),
          const SizedBox(height: 24),
          Text(
            'Thanks for your report!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: _position != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_position!.latitude.toStringAsFixed(4)}°N, ${_position!.longitude.abs().toStringAsFixed(4)}°W',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _isOffshore ? 'Offshore' : 'Nearshore/Inshore',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    )
                  : const Text('Getting location...'),
            ),
            if (_position == null)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _isQuickMode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isQuickMode ? theme.colorScheme.primary : Colors.grey[300],
              foregroundColor: _isQuickMode ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Quick Report'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _isQuickMode = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isQuickMode ? theme.colorScheme.primary : Colors.grey[300],
              foregroundColor: !_isQuickMode ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Detailed'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMode(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading || _position == null ? null : _submitQuickReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, size: 24),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Conditions Match',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'One-tap confirmation that our forecast is accurate',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailedForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sky & Air Section
        _buildSectionHeader('Sky & Air'),
        _buildDropdownRow('Sky', _skyCondition, ReportOptions.skyConditions,
            (v) => setState(() => _skyCondition = v)),
        _buildTempRow('Air Temp', _airTemp, (v) => setState(() => _airTemp = v)),
        _buildWindRow(),

        // Water Section (only if offshore)
        if (_isOffshore) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('Water Conditions'),
          _buildTempRow('Water Temp', _waterTemp, (v) => setState(() => _waterTemp = v)),
          _buildWaveRow(),
          _buildDropdownRow('Clarity', _waterClarity, ReportOptions.waterClarities,
              (v) => setState(() => _waterClarity = v)),
        ],

        // Fishing Section
        const SizedBox(height: 16),
        _buildSectionHeader('Fishing'),
        _buildDropdownRow('Success', _fishingSuccess, ReportOptions.fishingSuccesses,
            (v) => setState(() => _fishingSuccess = v)),
        _buildDropdownRow('Species', _species, ReportOptions.speciesList,
            (v) => setState(() => _species = v)),

        // Notes
        const SizedBox(height: 16),
        _buildSectionHeader('Notes (optional)'),
        TextField(
          controller: _commentController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Any additional observations...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // Submit button
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading || _position == null ? null : _submitDetailedReport,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTempRow(String label, int? value, Function(int?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Select...'),
              items: ReportOptions.temperatures.map((t) => DropdownMenuItem(value: t, child: Text('$t°F'))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text('Waves', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _waveHeight,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Height'),
              items: ReportOptions.waveHeights.map((h) => DropdownMenuItem(value: h, child: Text('$h ft'))).toList(),
              onChanged: (v) => setState(() => _waveHeight = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _wavePeriod,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Period'),
              items: ReportOptions.wavePeriods.map((p) => DropdownMenuItem(value: p, child: Text('$p sec'))).toList(),
              onChanged: (v) => setState(() => _wavePeriod = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text('Wind', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _windSpeed,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Speed'),
              items: ReportOptions.windSpeeds.map((s) => DropdownMenuItem(value: s, child: Text('$s mph'))).toList(),
              onChanged: (v) => setState(() => _windSpeed = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _windDirection,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Dir'),
              items: ReportOptions.directions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _windDirection = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              hint: const Text('Select...'),
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
