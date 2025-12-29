import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _showWebView = false;
  String? _webViewUrl;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    final tier = authService.tier ?? 'free';

    if (_showWebView && _webViewUrl != null) {
      return _buildWebView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current plan banner
            _buildCurrentPlanBanner(context, tier),
            const SizedBox(height: 24),

            // Plan options
            Text(
              'Choose Your Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Plus plan
            _buildPlanCard(
              context,
              tier: 'plus',
              currentTier: tier,
              name: 'Plus',
              price: '\$6.99',
              period: '/month',
              features: [
                'Full Radar Suite (20+ products)',
                'All Weather Models (GFS, NAM, ECMWF)',
                'Extended Forecasts',
              ],
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // Premium plan
            _buildPlanCard(
              context,
              tier: 'premium',
              currentTier: tier,
              name: 'Premium',
              price: '\$12.99',
              period: '/month',
              features: [
                'Everything in Plus',
                'Fishing Layers (SST, Chlorophyll, Currents)',
                'Strike Times Calendar',
                'Inlet Conditions',
                'My Fishing Spots',
              ],
              color: Colors.purple,
              recommended: true,
            ),
            const SizedBox(height: 12),

            // Pro plan
            _buildPlanCard(
              context,
              tier: 'pro',
              currentTier: tier,
              name: 'Pro',
              price: '\$22.99',
              period: '/month',
              features: [
                'Everything in Premium',
                'Captain Steve AI Chat',
                'Personalized Fishing Picks',
                'Priority Support',
              ],
              color: Colors.amber,
            ),
            const SizedBox(height: 24),

            // Manage billing button (for subscribed users)
            if (tier != 'free') ...[
              OutlinedButton.icon(
                onPressed: () => _openBillingPortal(context),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Manage Billing'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Terms text
            Text(
              'Subscriptions renew automatically. You can cancel anytime from the billing portal.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBanner(BuildContext context, String tier) {
    final theme = Theme.of(context);
    final isSubscribed = tier != 'free';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSubscribed
              ? [Colors.amber.shade700, Colors.amber.shade500]
              : [Colors.grey.shade600, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isSubscribed ? Icons.star : Icons.star_border,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSubscribed ? 'Current Plan' : 'Free Plan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  _formatTier(tier),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String tier,
    required String currentTier,
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    bool recommended = false,
  }) {
    final theme = Theme.of(context);
    final isCurrentPlan = currentTier == tier;
    final isUpgrade = _tierRank(tier) > _tierRank(currentTier);

    return Card(
      elevation: recommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: recommended
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          if (recommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Text(
                'RECOMMENDED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.diamond, color: color),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      period,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: isCurrentPlan
                      ? OutlinedButton(
                          onPressed: null,
                          child: const Text('Current Plan'),
                        )
                      : FilledButton(
                          onPressed: () => _selectPlan(context, tier),
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                          ),
                          child: Text(isUpgrade ? 'Upgrade' : 'Select'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _tierRank(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return 0;
      case 'plus':
        return 1;
      case 'premium':
        return 2;
      case 'pro':
        return 3;
      case 'admin':
        return 4;
      default:
        return 0;
    }
  }

  String _formatTier(String tier) {
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

  Future<void> _selectPlan(BuildContext context, String tier) async {
    // Map tier to Stripe price ID
    final priceId = _getPriceId(tier);
    if (priceId == null) return;

    // Open Stripe checkout in WebView
    final checkoutUrl = '${ApiConfig.mainSite}/subscribe?tier=$tier';

    setState(() {
      _webViewUrl = checkoutUrl;
      _showWebView = true;
    });
  }

  Future<void> _openBillingPortal(BuildContext context) async {
    final portalUrl = '${ApiConfig.mainSite}/account/billing';

    setState(() {
      _webViewUrl = portalUrl;
      _showWebView = true;
    });
  }

  String? _getPriceId(String tier) {
    switch (tier.toLowerCase()) {
      case 'plus':
        return 'price_1SdQIi4DAW9jMl21XbOB5EyX';
      case 'premium':
        return 'price_1SdQIi4DAW9jMl21eTiDj9FL';
      case 'pro':
        return 'price_1SdQIj4DAW9jMl21oWxK77x7';
      default:
        return null;
    }
  }

  Widget _buildWebView(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Handle success/cancel redirects
            if (request.url.contains('success=true')) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription successful!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Refresh user profile to get new tier
              Provider.of<AuthService>(context, listen: false)
                  .fetchUserProfile();
              return NavigationDecision.prevent;
            }
            if (request.url.contains('canceled=true')) {
              setState(() {
                _showWebView = false;
                _webViewUrl = null;
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_webViewUrl!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _showWebView = false;
              _webViewUrl = null;
            });
          },
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
