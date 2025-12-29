import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section (Auth)
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildAccountCard(context, authService),

          const SizedBox(height: 24),

          // Subscription Section
          Text(
            'Subscription',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildSubscriptionCard(context, authService),

          const SizedBox(height: 24),

          // Appearance Section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
              ),
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('About SkeeterCast'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'SkeeterCast',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(
                        Icons.sailing,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      children: [
                        const Text(
                          'Your AI-powered fishing and weather companion for North Carolina waters.',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open terms URL
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open privacy URL
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Version info
          Center(
            child: Text(
              'SkeeterCast v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, AuthService authService) {
    if (authService.isLoggedIn) {
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              title: Text(authService.email ?? 'User'),
              subtitle: Text('Tier: ${_formatTier(authService.tier)}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authService.logout();
                }
              },
            ),
          ],
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.login,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Sign In'),
        subtitle: const Text('Access premium features'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, AuthService authService) {
    final tier = authService.tier ?? 'free';
    final isSubscribed = tier != 'free';

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isSubscribed ? Icons.star : Icons.star_border,
              color: isSubscribed
                  ? Colors.amber
                  : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              isSubscribed ? 'Current Plan: ${_formatTier(tier)}' : 'Free Plan',
            ),
            subtitle: Text(
              isSubscribed
                  ? 'Manage your subscription'
                  : 'Upgrade to unlock all features',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!authService.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in first'),
                  ),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
          if (!isSubscribed) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Features:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _featureRow(context, 'Captain Steve AI Chat'),
                  _featureRow(context, 'Ocean Data Layers (SST, Chlorophyll)'),
                  _featureRow(context, 'Full Radar Suite'),
                  _featureRow(context, 'Strike Times Calendar'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatTier(String? tier) {
    if (tier == null) return 'Free';
    switch (tier.toLowerCase()) {
      case 'plus':
        return 'Plus';
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      case 'admin':
        return 'Admin';
      default:
        return 'Free';
    }
  }
}
