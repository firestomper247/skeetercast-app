import 'package:flutter/material.dart';
import '../services/forecast_service.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final ForecastService _forecastService = ForecastService();
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final cities = await _forecastService.getSavedCities();
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cities';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCities,
          ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add city search/add dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add city coming soon')),
          );
        },
        child: const Icon(Icons.add),
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
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadCities, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    if (_cities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No saved cities', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first city',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadCities,
      child: ListView.builder(
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          final city = _cities[index];
          return _CityCard(city: city);
        },
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final Map<String, dynamic> city;
  
  const _CityCard({required this.city});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = city['name'] ?? 'Unknown';
    final temp = city['temp'] ?? '--';
    final conditions = city['conditions'] ?? 'No data';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.wb_sunny,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(name, style: theme.textTheme.titleMedium),
        subtitle: Text(conditions),
        trailing: Text(
          '$temp°',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: () {
          // TODO: Navigate to city detail
        },
      ),
    );
  }
}
