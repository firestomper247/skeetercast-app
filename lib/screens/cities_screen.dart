import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/forecast_service.dart';
import '../services/auth_service.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> with SingleTickerProviderStateMixin {
  final ForecastService _forecastService = ForecastService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _forecastData;
  List<Map<String, dynamic>> _savedCities = [];
  List<dynamic> _alerts = [];
  String? _steveForecast;

  bool _isLoading = false;
  bool _isLoadingSteve = false;
  bool _isSavingCity = false;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load saved cities after frame is built (auth may not be ready yet)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCities();
      // Listen for auth changes
      Provider.of<AuthService>(context, listen: false).addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    // Reload saved cities when auth state changes
    _loadSavedCities();
  }

  @override
  void dispose() {
    Provider.of<AuthService>(context, listen: false).removeListener(_onAuthChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCities() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) return;

    final cities = await _forecastService.getSavedCities();
    setState(() => _savedCities = cities);

    // Auto-load primary city
    if (cities.isNotEmpty && _forecastData == null) {
      final primary = cities.firstWhere(
        (c) => c['is_primary'] == true,
        orElse: () => cities.first,
      );
      _loadSavedCity(primary);
    }
  }

  Future<void> _loadSavedCity(Map<String, dynamic> city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? data;
      if (city['zipcode'] != null && city['zipcode'].toString().isNotEmpty) {
        data = await _forecastService.getForecastByZipcode(city['zipcode'].toString());
      } else if (city['lat'] != null && city['lon'] != null) {
        // Use city name as fallback
        data = await _forecastService.getForecastByCity(city['city_name'] ?? '');
      }

      if (data != null) {
        setState(() {
          _forecastData = data;
          _isLoading = false;
        });
        _fetchAlerts(data['lat'], data['lon']);
        _fetchSteveForecast(city['city_name'] ?? data['city'], data);
      } else {
        setState(() {
          _error = 'Failed to load forecast';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading forecast';
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _alerts = [];
      _steveForecast = null;
    });

    try {
      final data = await _forecastService.searchLocation(query);
      if (data != null && data['has_forecast'] == true) {
        setState(() {
          _forecastData = data;
          _isLoading = false;
        });
        _fetchAlerts(data['lat'], data['lon']);
        _fetchSteveForecast(data['city'], data);
      } else {
        final isZip = RegExp(r'^\d{5}$').hasMatch(query.trim());
        setState(() {
          _error = isZip
              ? "Zipcode '$query' not found in NC. Try: 28401, 27601, 28205"
              : "City '$query' not found. Try: Wilmington, Raleigh, Charlotte";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error searching for location';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAlerts(double? lat, double? lon) async {
    if (lat == null || lon == null) return;
    final alerts = await _forecastService.getAlerts(lat, lon);
    setState(() => _alerts = alerts);
  }

  Future<void> _fetchSteveForecast(String? city, Map<String, dynamic> data) async {
    if (city == null) return;
    setState(() => _isLoadingSteve = true);
    final forecast = await _forecastService.getSteveForecast(city, data);
    setState(() {
      _steveForecast = forecast ?? "Steve is taking a break. Check back soon!";
      _isLoadingSteve = false;
    });
  }

  int _getMaxCities(String? tier) {
    if (['plus', 'premium', 'pro', 'admin'].contains(tier)) return 5;
    return 1;
  }

  bool _isCurrentCitySaved() {
    if (_forecastData == null) return false;
    final zip = _forecastData!['zipcode']?.toString();
    final lat = _forecastData!['lat'];
    final lon = _forecastData!['lon'];

    return _savedCities.any((c) {
      if (c['zipcode'] == zip && zip != null && zip.isNotEmpty) return true;
      if (c['lat'] != null && lat != null) {
        final latDiff = (c['lat'] - lat).abs();
        final lonDiff = (c['lon'] - lon).abs();
        if (latDiff < 0.01 && lonDiff < 0.01) return true;
      }
      return false;
    });
  }

  Future<void> _saveCurrentCity() async {
    if (_forecastData == null) return;
    setState(() => _isSavingCity = true);

    final success = await _forecastService.saveCity(
      cityName: _forecastData!['city'] ?? 'Unknown',
      zipcode: _forecastData!['zipcode']?.toString(),
      state: _forecastData!['state'] ?? 'NC',
      lat: _forecastData!['lat'] ?? 0.0,
      lon: _forecastData!['lon'] ?? 0.0,
      isPrimary: _savedCities.isEmpty,
    );

    if (success) {
      await _loadSavedCities();
    }
    setState(() => _isSavingCity = false);
  }

  Future<void> _removeSavedCity(int cityId) async {
    final success = await _forecastService.removeSavedCity(cityId);
    if (success) {
      setState(() {
        _savedCities.removeWhere((c) => c['id'] == cityId);
      });
    }
  }

  String _getWeatherIcon(String? conditions, {bool isNight = false}) {
    final desc = (conditions ?? '').toLowerCase();
    if (desc.contains('thunder') || desc.contains('storm')) return '⛈️';
    if (desc.contains('rain')) return '🌧️';
    if (desc.contains('snow')) return '❄️';
    if (desc.contains('fog')) return '🌫️';
    if (desc.contains('wind')) return '💨';

    // Handle day vs night for clear/sunny/cloudy
    if (desc.contains('clear') || desc.contains('sunny') || desc.contains('fair')) {
      return isNight ? '🌙' : '☀️';
    }
    if (desc.contains('partly')) {
      return isNight ? '☁️' : '⛅';
    }
    if (desc.contains('cloud')) return '☁️';

    return isNight ? '🌙' : '🌤️';
  }

  bool _isNightTime(String? timeStr) {
    if (timeStr == null) return false;
    try {
      final dt = DateTime.parse(timeStr);
      final hour = dt.hour;
      // Consider night between 7 PM and 6 AM
      return hour >= 19 || hour < 6;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cities'),
        centerTitle: true,
        bottom: _forecastData != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Forecast'),
                  Tab(text: 'Hourly'),
                  Tab(text: '5-Day'),
                  Tab(text: 'Steve'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city or zipcode...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _search(_searchController.text),
                ),
              ),
              onSubmitted: _search,
            ),
          ),

          // Saved Cities Bar
          if (authService.isLoggedIn) _buildSavedCitiesBar(theme, authService),

          // Weather Alerts
          if (_alerts.isNotEmpty) _buildAlertsSection(theme),

          // Main Content
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCitiesBar(ThemeData theme, AuthService authService) {
    final maxCities = _getMaxCities(authService.tier);
    final canSave = _forecastData != null &&
        !_isCurrentCitySaved() &&
        _savedCities.length < maxCities;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Saved: ', style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            ..._savedCities.map((city) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(city['city_name'] ?? 'Unknown'),
                avatar: city['is_primary'] == true
                    ? const Icon(Icons.star, size: 16)
                    : null,
                onPressed: () => _loadSavedCity(city),
                onDeleted: () => _removeSavedCity(city['id']),
                deleteIconColor: theme.colorScheme.error,
              ),
            )),
            if (canSave)
              ActionChip(
                label: _isSavingCity
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('+ Save'),
                onPressed: _isSavingCity ? null : _saveCurrentCity,
              ),
            if (_savedCities.length >= maxCities && authService.tier == 'free')
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upgrade to save more cities!')),
                  );
                },
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: _alerts.take(2).map((alert) {
          final event = alert['event'] ?? 'Weather Alert';
          final isWarning = event.toLowerCase().contains('warning');
          final color = isWarning ? Colors.red : Colors.orange;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isWarning ? Icons.warning : Icons.info, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (alert['headline'] != null)
                        Text(
                          alert['headline'],
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_forecastData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Search for a city', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter a city name or NC zipcode',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildForecastTab(theme),
        _buildHourlyTab(theme),
        _buildFiveDayTab(theme),
        _buildSteveTab(theme),
      ],
    );
  }

  Widget _buildForecastTab(ThemeData theme) {
    final hourly = (_forecastData!['hourly'] as List<dynamic>?) ?? [];
    final current = hourly.isNotEmpty ? hourly[0] : null;
    final obs = _forecastData!['current_observation'];

    final temp = (obs?['temperature_f'] ?? current?['temperature_f'] ?? 0).round();
    final conditions = current?['short_forecast'] ?? 'Unknown';
    final humidity = obs?['humidity_pct'] ?? current?['humidity_pct'];
    final windSpeed = obs?['wind_speed_mph'] != null
        ? '${obs['wind_speed_mph']} mph'
        : current?['wind_speed'] ?? 'N/A';
    final windDir = current?['wind_direction'] ?? '';
    final dewpoint = current?['dewpoint_f']?.round();
    final precip = current?['precip_probability'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Conditions Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  _forecastData!['city'] ?? 'Unknown',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getWeatherIcon(conditions),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$temp°F',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  conditions,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                // Details Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailChip('💧 ${humidity ?? 'N/A'}%', 'Humidity'),
                    _buildDetailChip('💨 $windDir $windSpeed', 'Wind'),
                    _buildDetailChip('🌡️ ${dewpoint ?? 'N/A'}°', 'Dewpoint'),
                    _buildDetailChip('☔ $precip%', 'Precip'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Forecast Periods
          ...(_forecastData!['forecast'] as List<dynamic>? ?? [])
              .take(4)
              .map((period) => _buildForecastPeriodCard(theme, period)),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildForecastPeriodCard(ThemeData theme, Map<String, dynamic> period) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          _getWeatherIcon(period['short_forecast']),
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(period['name'] ?? 'Unknown'),
        subtitle: Text(period['short_forecast'] ?? ''),
        trailing: Text(
          '${period['temperature_f'] ?? '?'}°F',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHourlyTab(ThemeData theme) {
    final hourly = (_forecastData!['hourly'] as List<dynamic>?) ?? [];

    if (hourly.isEmpty) {
      return const Center(child: Text('No hourly data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hourly.length.clamp(0, 24),
      itemBuilder: (context, index) {
        final hour = hourly[index];
        final time = hour['time'] ?? hour['start_time'] ?? '';
        final temp = hour['temperature_f']?.round() ?? '?';
        var conditions = hour['short_forecast'] ?? '';
        final precip = hour['precip_probability'] ?? 0;
        final isNight = _isNightTime(time);

        // Fix "Sunny" to "Clear" at night
        if (isNight) {
          conditions = conditions
              .replaceAll('Sunny', 'Clear')
              .replaceAll('sunny', 'clear');
        }

        return Card(
          child: ListTile(
            leading: Text(
              _getWeatherIcon(conditions, isNight: isNight),
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(_formatTime(time)),
            subtitle: Text('$conditions${precip > 0 ? ' - $precip% rain' : ''}'),
            trailing: Text('$temp°', style: theme.textTheme.titleLarge),
          ),
        );
      },
    );
  }

  String _formatTime(String time) {
    try {
      final dt = DateTime.parse(time);
      final hour = dt.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:00 $ampm';
    } catch (e) {
      return time;
    }
  }

  Widget _buildFiveDayTab(ThemeData theme) {
    final forecast = (_forecastData!['forecast'] as List<dynamic>?) ?? [];

    if (forecast.isEmpty) {
      return const Center(child: Text('No forecast data available'));
    }

    // Build day/night pairs
    final List<Map<String, dynamic>> dayPairs = [];
    for (int i = 0; i < forecast.length; i++) {
      final period = forecast[i];
      if (period['is_daytime'] == true) {
        // Find the following night period
        Map<String, dynamic>? nightPeriod;
        if (i + 1 < forecast.length && forecast[i + 1]['is_daytime'] == false) {
          nightPeriod = forecast[i + 1];
        }
        dayPairs.add({
          'day': period,
          'night': nightPeriod,
        });
        if (dayPairs.length >= 5) break;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayPairs.length,
      itemBuilder: (context, index) {
        final pair = dayPairs[index];
        final day = pair['day'] as Map<String, dynamic>;
        final night = pair['night'] as Map<String, dynamic>?;

        final name = day['name'] ?? 'Day ${index + 1}';
        final high = day['temperature_f'] ?? '?';
        final low = night?['temperature_f'] ?? '--';
        final conditions = day['short_forecast'] ?? '';
        final detailed = day['detailed_forecast'] ?? '';
        final nightDetailed = night?['detailed_forecast'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Text(_getWeatherIcon(conditions), style: const TextStyle(fontSize: 32)),
            title: Text(name, style: theme.textTheme.titleMedium),
            subtitle: Row(
              children: [
                Text('H: $high°', style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(width: 12),
                Text('L: $low°', style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                )),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conditions,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day:', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(detailed, style: theme.textTheme.bodyMedium),
                    if (nightDetailed.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Night:', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(nightDetailed, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSteveTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Captain Steve Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🎣', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Captain Steve's Take",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI-powered weather for anglers',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Steve's Forecast
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingSteve
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Text(
                      _steveForecast ?? 'Loading Steve\'s forecast...',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
