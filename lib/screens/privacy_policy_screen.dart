import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: December 30, 2025',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildSection(theme, '1. Information We Collect', '''
Account Information:
- Username and email address
- Password (encrypted and securely stored)
- Account creation and login timestamps

Device Information:
- Device type, model, and operating system
- Unique device identifiers (for app functionality)
- App version and crash reports

Location Data:
- GPS coordinates (only when you grant permission)
- Approximate location for localized weather forecasts
- Location data for field reports (optional)

We only collect location data when the app is in use, unless you enable background location for weather alerts.

Usage Data:
- Features accessed and interaction patterns
- Search queries and saved locations
- Preferences and settings'''),

            _buildSection(theme, '2. How We Use Your Information', '''
We use collected information to:
- Provide accurate, localized weather forecasts
- Power Captain Steve AI recommendations
- Process field reports and observations
- Enable the Fishing Buddies feature
- Send push notifications for weather alerts
- Improve our forecasting algorithms
- Process payments for premium subscriptions
- Prevent fraud and ensure security
- Comply with legal obligations'''),

            _buildSection(theme, '3. Location Services', '''
SkeeterCast uses your location to provide:
- Local weather forecasts and conditions
- Nearby inlet and fishing spot information
- Radar and satellite imagery for your area
- Weather alerts for your location
- Field report geotagging (optional)

Location Permission Options:
- "While Using": Location accessed only when app is open
- "Always": Required for background weather alerts
- "Never": Basic functionality without personalization

You can change location permissions anytime in your device settings. Denying location access limits personalized features but does not prevent app use.'''),

            _buildSection(theme, '4. Push Notifications', '''
We may send push notifications for:
- Severe weather alerts for saved locations
- Storm and hurricane warnings
- Fishing condition updates
- Buddy messages and friend requests
- Subscription and account updates

You can disable notifications anytime in:
- App Settings > Notifications
- Device Settings > SkeeterCast > Notifications

We do not send marketing notifications without consent.'''),

            _buildSection(theme, '5. Data Storage & Security', '''
Security Measures:
- Passwords hashed using industry-standard encryption
- Data transmitted via HTTPS/TLS encryption
- Secure token-based authentication (JWT)
- Regular security audits and updates

Data Storage:
- Data stored on secure servers in the United States
- Regular encrypted backups
- Access limited to authorized personnel

No system is 100% secure. We implement industry-standard measures but cannot guarantee absolute security.'''),

            _buildSection(theme, '6. Data Sharing & Disclosure', '''
WE DO NOT SELL YOUR PERSONAL INFORMATION.

We may share data with:
- Service Providers: Payment processors (Stripe), cloud hosting, analytics (under strict agreements)
- Legal Requirements: When required by law, court order, or government request
- Business Transfers: In case of merger, acquisition, or asset sale
- With Your Consent: When you explicitly authorize sharing

Third-Party Services:
- Stripe/PayPal for payments (separate privacy policies)
- Google Maps for mapping features
- Weather data from NOAA, NWS, NASA (public sources)'''),

            _buildSection(theme, '7. Your Rights', '''
You have the right to:

Access: Request a copy of your personal data
Correction: Update incorrect information
Deletion: Request account and data deletion
Export: Download your data in portable format
Opt-Out: Unsubscribe from notifications and emails

To exercise these rights:
- Email: support@skeetercast.com
- In-App: Settings > Account > Delete Account

California Residents (CCPA):
- Know what personal information is collected
- Know if information is sold (we don't sell data)
- Request deletion of personal information
- Non-discrimination for exercising rights

EU Residents (GDPR):
- All above rights plus data portability
- Right to restrict processing
- Right to object to processing'''),

            _buildSection(theme, '8. Data Retention', '''
- Active Accounts: Data retained while account is active
- Deleted Accounts: Data purged within 30 days
- Payment Records: Retained 7 years (legal requirement)
- Anonymized Analytics: May be retained indefinitely
- Field Reports: Retained for community benefit (anonymized)'''),

            _buildSection(theme, '9. Children\'s Privacy', '''
SkeeterCast is not directed at children under 13. We do not knowingly collect personal information from children under 13.

If you believe a child has provided us personal information, contact us immediately at support@skeetercast.com and we will delete it.'''),

            _buildSection(theme, '10. Third-Party Links', '''
Our app may contain links to third-party websites or services. We are not responsible for their privacy practices. We encourage you to review their privacy policies.'''),

            _buildSection(theme, '11. Analytics & Crash Reporting', '''
We use analytics to improve the app:
- Crash reports to fix bugs
- Usage patterns to improve features
- Performance metrics

Analytics data is aggregated and anonymized where possible. You can opt out of analytics in app settings.'''),

            _buildSection(theme, '12. Changes to Privacy Policy', '''
We may update this policy periodically. Changes will be posted with a new "Last Updated" date.

For significant changes, we will notify you via:
- In-app notification
- Email (if provided)
- App store update notes

Continued use after changes constitutes acceptance.'''),

            _buildSection(theme, '13. Contact Us', '''
Questions about privacy?

Email: support@skeetercast.com
Support: support@skeetercast.com

SkeeterCast
North Carolina, United States'''),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 SkeeterCast. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
