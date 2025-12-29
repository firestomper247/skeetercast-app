import 'package:flutter/material.dart';
import '../services/ocean_service.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> {
  final OceanService _oceanService = OceanService();
  Map<String, dynamic>? _conditions;
  List<Map<String, dynamic>> _speciesScores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final results = await Future.wait([
        _oceanService.getConditions(),
        _oceanService.getSpeciesScores(),
      ]);
      
      setState(() {
        _conditions = results[0] as Map<String, dynamic>?;
        _speciesScores = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load fishing data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(theme),
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
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConditionsCard(theme),
          const SizedBox(height: 16),
          Text('Species Scores', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._speciesScores.map((species) => _SpeciesCard(species: species)),
          if (_speciesScores.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No species data available',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionsCard(ThemeData theme) {
    final sst = _conditions?['sst'] ?? '--';
    final waveHeight = _conditions?['wave_height'] ?? '--';
    final windSpeed = _conditions?['wind_speed'] ?? '--';
    final visibility = _conditions?['visibility'] ?? '--';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ocean Conditions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ConditionItem(label: 'SST', value: '$sst°F', icon: Icons.thermostat),
                _ConditionItem(label: 'Waves', value: '$waveHeight ft', icon: Icons.waves),
                _ConditionItem(label: 'Wind', value: '$windSpeed mph', icon: Icons.air),
                _ConditionItem(label: 'Vis', value: '$visibility mi', icon: Icons.visibility),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _ConditionItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final Map<String, dynamic> species;
  
  const _SpeciesCard({required this.species});
  
  @override
  Widget build(BuildContext context) {
    final name = species['name'] ?? 'Unknown';
    final score = species['score'] ?? 0;
    final reason = species['reason'] ?? '';
    
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scoreColor,
          child: Text(
            '$score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name),
        subtitle: reason.isNotEmpty ? Text(reason) : null,
      ),
    );
  }
}
