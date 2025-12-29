import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/captain_steve_service.dart';

class CaptainSteveScreen extends StatelessWidget {
  const CaptainSteveScreen({super.key});

  Future<void> _openChat() async {
    final uri = Uri.parse(CaptainSteveService.chatUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captain Steve'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sailing,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Captain Steve',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI Fishing & Weather Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ask Captain Steve about weather forecasts, fishing conditions, best times to fish, and get personalized recommendations.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Captain Steve'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
