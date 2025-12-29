import 'package:flutter/material.dart';
import '../services/forecast_service.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final ForecastService _forecastService = ForecastService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _forecast;
  bool _isLoading = false;
  String? _error;
  String? _currentCity;

  Future<void> _searchCity(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentCity = city;
    });

    try {
      final forecast = await _forecastService.getCityForecast(city);
      setState(() {
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load forecast';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cities'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _searchCity(_searchController.text),
                ),
              ),
              onSubmitted: _searchCity,
            ),
          ),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    if (_forecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Search for a city', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter a city name to get the weather forecast',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _currentCity ?? 'Unknown',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_forecast!['response'] != null)
                    Text(
                      _forecast!['response'],
                      style: theme.textTheme.bodyLarge,
                    )
                  else if (_forecast!['summary'] != null)
                    Text(
                      _forecast!['summary'],
                      style: theme.textTheme.bodyLarge,
                    )
                  else
                    Text(
                      'No forecast data available',
                      style: theme.textTheme.bodyLarge,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
