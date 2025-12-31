import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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

            _buildSection(theme, '1. Acceptance of Terms', '''
By downloading, installing, or using the SkeeterCast mobile application ("App") and related services ("Service"), you agree to be bound by these Terms of Service ("Terms").

If you do not agree to these Terms, do not use the App. Your continued use constitutes acceptance of any updates to these Terms.'''),

            _buildSection(theme, '2. Description of Service', '''
SkeeterCast provides:
- Weather forecasting for North Carolina and surrounding areas
- Radar and satellite imagery
- Ocean data (sea surface temperature, currents, chlorophyll)
- AI-powered fishing recommendations (Captain Steve)
- Inlet conditions and tide information
- Field report sharing
- Social features (Fishing Buddies)

The Service includes both free and premium subscription tiers.'''),

            _buildSection(theme, '3. User Accounts', '''
Account Requirements:
- You must be at least 13 years old to create an account
- You must provide accurate, current information
- You are responsible for maintaining account security
- You are responsible for all activity under your account
- One account per person; no shared accounts

Account Termination:
We may suspend or terminate accounts that violate these Terms, engage in fraud, or abuse the Service.'''),

            _buildSection(theme, '4. Acceptable Use', '''
You agree NOT to:
- Use the App for any illegal purpose
- Redistribute, resell, or commercially exploit content
- Use automated systems (bots, scrapers) to access the Service
- Reverse engineer, decompile, or modify the App
- Interfere with or disrupt the Service
- Attempt unauthorized access to systems or accounts
- Harass, abuse, or harm other users
- Submit false or misleading field reports
- Impersonate others or misrepresent affiliation
- Circumvent subscription or payment systems'''),

            _buildSection(theme, '5. Weather Data Disclaimer', '''
CRITICAL SAFETY NOTICE:

Weather forecasts are PREDICTIONS and may be inaccurate. SkeeterCast aggregates data from public sources including NOAA, NWS, NASA, and other providers.

DO NOT rely solely on SkeeterCast for:
- Life-threatening weather decisions
- Marine navigation or boating safety
- Aviation decisions
- Emergency evacuation decisions
- Any safety-critical operations

ALWAYS consult official sources (National Weather Service, NOAA, Coast Guard) for critical weather and safety decisions.

Captain Steve AI recommendations are for informational purposes only and do not guarantee fishing success or safety.'''),

            _buildSection(theme, '6. Location Services', '''
The App uses location services to provide personalized forecasts and features. By enabling location:
- You consent to collection of location data as described in our Privacy Policy
- You understand location accuracy varies by device and conditions
- You can disable location services anytime in device settings

Background location (if enabled) is used only for weather alerts for your saved locations.'''),

            _buildSection(theme, '7. Push Notifications', '''
By enabling push notifications, you consent to receive:
- Weather alerts and warnings
- Fishing condition updates
- Buddy messages
- Service announcements

You can disable notifications anytime. Critical weather alerts may be sent regardless of preferences where permitted by law.'''),

            _buildSection(theme, '8. Subscriptions & Payments', '''
Free Tier:
- Basic weather forecasts
- Limited features

Premium Subscriptions:
- Billed monthly or annually through app stores
- Auto-renew unless cancelled before renewal date
- No refunds for partial subscription periods
- Prices may change with 30 days notice

Cancellation:
- Cancel anytime through App Store or Google Play
- Access continues until end of billing period
- No refunds for unused time

In-App Purchases:
- All purchases are final
- Managed by Apple App Store or Google Play
- Subject to their respective terms and refund policies'''),

            _buildSection(theme, '9. Intellectual Property', '''
All content, trademarks, logos, and intellectual property in the App are owned by SkeeterCast or our licensors.

You may NOT:
- Copy, modify, or distribute App content
- Use our trademarks without permission
- Remove copyright or proprietary notices

Weather data from government sources (NOAA, NWS) is public domain but our presentation and analysis are proprietary.'''),

            _buildSection(theme, '10. User Content', '''
Field Reports & Observations:
- You retain ownership of content you submit
- You grant us a license to use, display, and share your reports
- Reports may be visible to other users
- We may remove inappropriate or false content

You represent that your content:
- Is accurate and not misleading
- Does not violate others' rights
- Does not contain illegal or harmful material'''),

            _buildSection(theme, '11. Limitation of Liability', '''
TO THE MAXIMUM EXTENT PERMITTED BY LAW:

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.

WE DO NOT WARRANT:
- Accuracy of weather data or forecasts
- Uninterrupted or error-free service
- Fitness for any particular purpose

WE ARE NOT LIABLE FOR:
- Decisions made based on App information
- Property damage, personal injury, or death
- Lost profits, data loss, or indirect damages
- Third-party actions or content

TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT PAID FOR THE SERVICE IN THE PAST 12 MONTHS.

Some jurisdictions do not allow limitation of liability, so some limitations may not apply to you.'''),

            _buildSection(theme, '12. Indemnification', '''
You agree to indemnify and hold harmless SkeeterCast, its officers, directors, employees, and agents from any claims, damages, losses, or expenses arising from:
- Your use of the App
- Your violation of these Terms
- Your violation of any third-party rights
- Your user content'''),

            _buildSection(theme, '13. Third-Party Services', '''
The App may integrate with third-party services:
- Apple App Store / Google Play (distribution)
- Stripe / PayPal (payments)
- Google Maps (mapping)
- NOAA / NWS (weather data)

These services have their own terms and privacy policies. We are not responsible for third-party services.'''),

            _buildSection(theme, '14. Modifications to Service', '''
We reserve the right to:
- Modify or discontinue features at any time
- Change subscription pricing with notice
- Update these Terms periodically
- Suspend service for maintenance

Material changes will be communicated via in-app notice or email.'''),

            _buildSection(theme, '15. Dispute Resolution', '''
Governing Law:
These Terms are governed by the laws of North Carolina, United States.

Dispute Resolution:
- Informal Resolution: Contact us first to resolve disputes
- Binding Arbitration: Disputes not resolved informally shall be settled by binding arbitration
- Class Action Waiver: You waive the right to participate in class actions
- Small Claims: Either party may bring claims in small claims court

Time Limit: Claims must be brought within one (1) year.'''),

            _buildSection(theme, '16. App Store Terms', '''
If you downloaded the App from Apple App Store:
- Apple is not responsible for the App or its content
- Apple has no obligation to provide support
- Any claims are between you and SkeeterCast
- Apple is a third-party beneficiary of these Terms

If you downloaded from Google Play:
- Google Play terms also apply
- Google is not responsible for the App'''),

            _buildSection(theme, '17. Export Compliance', '''
The App may be subject to U.S. export laws. You agree not to export or re-export the App in violation of applicable laws.'''),

            _buildSection(theme, '18. Severability', '''
If any provision of these Terms is found unenforceable, the remaining provisions remain in full effect. The unenforceable provision will be modified to the minimum extent necessary.'''),

            _buildSection(theme, '19. Entire Agreement', '''
These Terms, together with our Privacy Policy, constitute the entire agreement between you and SkeeterCast regarding the App.'''),

            _buildSection(theme, '20. Contact Information', '''
Questions about these Terms?

Email: support@skeetercast.com

SkeeterCast
North Carolina, United States'''),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'By using SkeeterCast, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and our Privacy Policy.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

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
