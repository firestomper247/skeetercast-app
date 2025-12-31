import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/offline_service.dart';
import 'services/map_cache_service.dart';
import 'screens/radar_screen.dart';
import 'screens/cities_screen.dart';
import 'screens/fishing_screen.dart';
import 'screens/captain_steve_screen.dart';
import 'screens/buddies_screen.dart';
import 'screens/report_conditions_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline caching (Hive, connectivity monitoring)
  await OfflineService.instance.initialize();

  // Initialize map tile caching
  await MapCacheService.instance.initialize();

  // Initialize notifications (includes Firebase init)
  await NotificationService.instance.initialize();

  // Subscribe to broadcast topic for system announcements
  await NotificationService.instance.subscribeToTopic('announcements');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: OfflineService.instance),
      ],
      child: const SkeeterCastApp(),
    ),
  );
}

class SkeeterCastApp extends StatelessWidget {
  const SkeeterCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SkeeterCast',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CitiesScreen(),
    RadarScreen(),
    FishingScreen(),
    CaptainSteveScreen(),
    BuddiesScreen(),
    ReportConditionsScreen(),
    SettingsScreen(),
  ];

  // Navigation items for both rail and bar
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.location_city_outlined, Icons.location_city, 'Cities'),
    _NavItem(Icons.radar_outlined, Icons.radar, 'Radar'),
    _NavItem(Icons.phishing_outlined, Icons.phishing, 'Fishing'),
    _NavItem(Icons.person_outline, Icons.person, 'Steve'),
    _NavItem(Icons.group_outlined, Icons.group, 'Buddies'),
    _NavItem(Icons.edit_note_outlined, Icons.edit_note, 'Report'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final isExpanded = Responsive.isExpanded(context);
    final theme = Theme.of(context);

    // Offline banner
    Widget offlineBanner = Consumer<OfflineService>(
      builder: (context, offlineService, _) {
        if (offlineService.isOnline && offlineService.pendingActionsCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: offlineService.isOnline ? Colors.green : Colors.orange,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  offlineService.isOnline ? Icons.sync : Icons.cloud_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offlineService.isOnline
                        ? 'Syncing ${offlineService.pendingActionsCount} pending items...'
                        : 'Offline Mode - ${offlineService.pendingActionsCount} items pending',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                if (!offlineService.isOnline)
                  TextButton(
                    onPressed: () => offlineService.syncNow(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    // Build NavigationRail for tablets/foldables
    if (isTablet) {
      return Scaffold(
        body: Column(
          children: [
            offlineBanner,
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    extended: isExpanded, // Show labels on large screens
                    minExtendedWidth: 180,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.asset(
                        'assets/images/logo_full.png',
                        height: isExpanded ? 60 : 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    destinations: _navItems.map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    )).toList(),
                    backgroundColor: theme.colorScheme.surface,
                    indicatorColor: theme.colorScheme.primaryContainer,
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Build bottom NavigationBar for phones
    return Scaffold(
      body: Column(
        children: [
          offlineBanner,
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navItems.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
        )).toList(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
      ),
    );
  }
}

// Helper class for navigation items
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem(this.icon, this.selectedIcon, this.label);
}
