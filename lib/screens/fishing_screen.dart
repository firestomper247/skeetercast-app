import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_config.dart';
import '../services/captain_steve_service.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> {
  final CaptainSteveService _steveService = CaptainSteveService();
  final Dio _dio = Dio();

  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _speciesScores;
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
      // Fetch ocean health and species scores in parallel
      final healthFuture = _dio.get(ApiConfig.oceanHealth);
      final scoresFuture = _steveService.getSpeciesScores();

      final results = await Future.wait([healthFuture, scoresFuture]);

      setState(() {
        _healthData = (results[0] as Response).data;
        _speciesScores = results[1] as Map<String, dynamic>?;
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
          _buildDataSourcesCard(theme),
          const SizedBox(height: 16),
          if (_speciesScores != null) ...[
            Text('Species Scores', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildSpeciesScoresCard(theme),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Species scores unavailable', style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSourcesCard(ThemeData theme) {
    if (_healthData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text('Ocean data unavailable', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final dataSources = _healthData!['data_sources'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waves, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Ocean Data Status', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (dataSources != null) ...[
              _DataSourceRow(
                label: 'SST',
                available: dataSources['sst']?['available'] ?? false,
                count: dataSources['sst']?['count'] ?? 0,
              ),
              _DataSourceRow(
                label: 'Chlorophyll',
                available: dataSources['chlorophyll']?['available'] ?? false,
                count: dataSources['chlorophyll']?['count'] ?? 0,
              ),
              _DataSourceRow(
                label: 'Currents',
                available: dataSources['currents']?['available'] ?? false,
                count: dataSources['currents']?['count'] ?? 0,
              ),
              _DataSourceRow(
                label: 'Waves',
                available: dataSources['waves']?['available'] ?? false,
                count: dataSources['waves']?['count'] ?? 0,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesScoresCard(ThemeData theme) {
    final scores = _speciesScores!['species_scores'] as List<dynamic>? ?? [];

    if (scores.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No species data available', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    // Sort by score descending and take top 10
    final sortedScores = List<Map<String, dynamic>>.from(scores);
    sortedScores.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    final topScores = sortedScores.take(10).toList();

    return Column(
      children: topScores.map((species) => _SpeciesCard(species: species)).toList(),
    );
  }
}

class _DataSourceRow extends StatelessWidget {
  final String label;
  final bool available;
  final int count;

  const _DataSourceRow({
    required this.label,
    required this.available,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: available ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            available ? '${_formatCount(count)} pts' : 'Unavailable',
            style: TextStyle(
              color: available ? Colors.grey : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}

class _SpeciesCard extends StatelessWidget {
  final Map<String, dynamic> species;

  const _SpeciesCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final name = species['name'] ?? 'Unknown';
    final score = species['score'] ?? 0;
    final reason = species['reason'] ?? species['assessment'] ?? '';

    Color scoreColor;
    if (score >= 70) {
      scoreColor = Colors.green;
    } else if (score >= 50) {
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
        subtitle: reason.isNotEmpty ? Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
      ),
    );
  }
}
