import 'package:flutter/material.dart';
import '../config/tier_config.dart';

/// Shows a lock icon on tier-gated features
class TierLockBadge extends StatelessWidget {
  final String minTier;
  final double size;

  const TierLockBadge({
    super.key,
    required this.minTier,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final info = getTierInfo(minTier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: size, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            info?.name ?? 'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: size - 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen upgrade prompt for locked pages/features
class UpgradePromptScreen extends StatelessWidget {
  final String featureName;
  final String minTier;
  final String? description;
  final IconData? icon;

  const UpgradePromptScreen({
    super.key,
    required this.featureName,
    required this.minTier,
    this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = getTierInfo(minTier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.lock_outline,
                size: 64,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              featureName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTierColor(minTier).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getTierColor(minTier)),
              ),
              child: Text(
                'Requires ${info?.name ?? "Premium"} tier',
                style: TextStyle(
                  color: _getTierColor(minTier),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description ?? 'Upgrade your subscription to unlock this feature.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                _showUpgradeInfo(context, minTier);
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Learn About Upgrading'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'plus':
        return const Color(0xFF4CAF50);
      case 'premium':
        return const Color(0xFFFF9800);
      case 'pro':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  void _showUpgradeInfo(BuildContext context, String tier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UpgradeInfoSheet(targetTier: tier),
    );
  }
}

/// Bottom sheet with upgrade tier information
class UpgradeInfoSheet extends StatelessWidget {
  final String targetTier;

  const UpgradeInfoSheet({super.key, required this.targetTier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upgrade Your Experience',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the plan that fits your fishing needs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Plus Tier
              _buildTierCard(
                context,
                tier: 'plus',
                name: 'Plus',
                icon: '➕',
                color: const Color(0xFF4CAF50),
                features: [
                  'All radar layers & satellite',
                  'Weather models (HRRR, GFS, NAM)',
                  'Captain Steve AI Chat (5/day)',
                  'Save up to 5 cities',
                ],
                isRecommended: targetTier == 'plus',
              ),
              const SizedBox(height: 16),

              // Premium Tier
              _buildTierCard(
                context,
                tier: 'premium',
                name: 'Premium',
                icon: '⭐',
                color: const Color(0xFFFF9800),
                features: [
                  'Everything in Plus',
                  'Offshore fishing map with SST, chlorophyll',
                  'Inlet conditions & wave forecasts',
                  'Inshore fishing conditions',
                  'Strike times & save spots',
                  'Captain Steve Chat (15/day)',
                ],
                isRecommended: targetTier == 'premium',
              ),
              const SizedBox(height: 16),

              // Pro Tier
              _buildTierCard(
                context,
                tier: 'pro',
                name: 'Pro',
                icon: '🏆',
                color: const Color(0xFFE91E63),
                features: [
                  'Everything in Premium',
                  "Captain Steve's AI Fishing Picks",
                  'AI spot analysis',
                  'Unlimited Captain Steve chat',
                  'Priority support',
                ],
                isRecommended: targetTier == 'pro',
              ),
              const SizedBox(height: 24),

              Text(
                'Visit skeetercast.com to upgrade',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String tier,
    required String name,
    required String icon,
    required Color color,
    required List<String> features,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? color : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper widget that shows upgrade prompt if user doesn't have access
class TierGatedWidget extends StatelessWidget {
  final String? userTier;
  final Feature feature;
  final Widget child;
  final Widget? lockedChild;

  const TierGatedWidget({
    super.key,
    required this.userTier,
    required this.feature,
    required this.child,
    this.lockedChild,
  });

  @override
  Widget build(BuildContext context) {
    if (canAccessFeature(userTier, feature)) {
      return child;
    }

    return lockedChild ?? UpgradePromptScreen(
      featureName: feature.name,
      minTier: feature.minTier,
    );
  }
}
