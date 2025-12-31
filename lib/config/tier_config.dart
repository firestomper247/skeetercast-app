/// SkeeterCast Tier Configuration
/// Matches website tier requirements exactly
///
/// TIER HIERARCHY (lowest to highest):
/// free < plus < premium < pro < admin

// Valid tier values (matches database)
class Tiers {
  static const String free = 'free';
  static const String plus = 'plus';
  static const String premium = 'premium';
  static const String pro = 'pro';
  static const String admin = 'admin';
}

// Tier display info
class TierInfo {
  final String name;
  final String color;
  final String icon;
  final String description;

  const TierInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.description,
  });
}

const Map<String, TierInfo> tierInfo = {
  'free': TierInfo(
    name: 'Free',
    color: '#888888',
    icon: '🆓',
    description: 'Basic access to explore SkeeterCast',
  ),
  'plus': TierInfo(
    name: 'Plus',
    color: '#4CAF50',
    icon: '➕',
    description: 'Full weather intelligence - all radar & models',
  ),
  'premium': TierInfo(
    name: 'Premium',
    color: '#FF9800',
    icon: '⭐',
    description: 'Complete fishing intelligence - ocean data, inlets & more',
  ),
  'pro': TierInfo(
    name: 'Pro',
    color: '#E91E63',
    icon: '🏆',
    description: 'AI-powered fishing edge with Captain Steve picks',
  ),
  'admin': TierInfo(
    name: 'Admin',
    color: '#9C27B0',
    icon: '👑',
    description: 'Full administrative access',
  ),
};

// Captain Steve chat limits per tier
const Map<String, Map<String, int>> captainSteveLimits = {
  'free': {'daily': 0, 'monthly': 0},
  'plus': {'daily': 5, 'monthly': 30},
  'premium': {'daily': 15, 'monthly': 60},
  'pro': {'daily': 999, 'monthly': 999}, // Effectively unlimited
  'admin': {'daily': 999, 'monthly': 999},
};

// Saved cities limits per tier
const Map<String, int> savedCitiesLimits = {
  'free': 1,
  'plus': 5,
  'premium': 5,
  'pro': 5,
  'admin': 99,
};

// Feature definitions with minimum tier requirements
class Feature {
  final String id;
  final String name;
  final String minTier;
  final String category;

  const Feature({
    required this.id,
    required this.name,
    required this.minTier,
    required this.category,
  });
}

class Features {
  // ═══════════════════════════════════════════════════════════════
  // RADAR PAGE FEATURES
  // ═══════════════════════════════════════════════════════════════
  static const radarComposite = Feature(
    id: 'radar_composite',
    name: 'Composite Reflectivity',
    minTier: 'plus',
    category: 'radar',
  );
  static const radarVelocity = Feature(
    id: 'radar_velocity',
    name: 'Storm Velocity',
    minTier: 'plus',
    category: 'radar',
  );
  static const radarEchoTops = Feature(
    id: 'radar_echo_tops',
    name: 'Echo Tops',
    minTier: 'plus',
    category: 'radar',
  );
  static const radarPrecipType = Feature(
    id: 'radar_precip_type',
    name: 'Precipitation Type',
    minTier: 'plus',
    category: 'radar',
  );
  static const radarSatellite = Feature(
    id: 'radar_satellite',
    name: 'Satellite Imagery',
    minTier: 'plus',
    category: 'radar',
  );
  static const radarLightning = Feature(
    id: 'radar_lightning',
    name: 'Lightning Data',
    minTier: 'plus',
    category: 'radar',
  );

  // ═══════════════════════════════════════════════════════════════
  // FISHING PAGE FEATURES
  // ═══════════════════════════════════════════════════════════════
  static const fishingViewMap = Feature(
    id: 'fishing_view_map',
    name: 'View Fishing Map',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingSstLayer = Feature(
    id: 'fishing_sst_layer',
    name: 'SST Layer',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingChlorophyllLayer = Feature(
    id: 'fishing_chlorophyll_layer',
    name: 'Chlorophyll Layer',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingSshLayer = Feature(
    id: 'fishing_ssh_layer',
    name: 'SSH Anomaly Layer',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingClickData = Feature(
    id: 'fishing_click_data',
    name: 'Click for Point Data',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingMySpots = Feature(
    id: 'fishing_my_spots',
    name: 'Save My Spots',
    minTier: 'premium',
    category: 'fishing',
  );
  static const fishingCaptainStevePicks = Feature(
    id: 'fishing_captain_steve',
    name: "Captain Steve AI Picks",
    minTier: 'pro',
    category: 'fishing',
  );
  static const strikeTimes = Feature(
    id: 'strike_times',
    name: 'Strike Times',
    minTier: 'premium',
    category: 'fishing',
  );

  // ═══════════════════════════════════════════════════════════════
  // INLET PAGE FEATURES
  // ═══════════════════════════════════════════════════════════════
  static const inletConditions = Feature(
    id: 'inlet_conditions',
    name: 'Inlet Conditions',
    minTier: 'premium',
    category: 'inlet',
  );

  // ═══════════════════════════════════════════════════════════════
  // INSHORE PAGE FEATURES
  // ═══════════════════════════════════════════════════════════════
  static const inshorePage = Feature(
    id: 'inshore_page',
    name: 'Inshore Conditions',
    minTier: 'premium',
    category: 'inshore',
  );

  // ═══════════════════════════════════════════════════════════════
  // CAPTAIN STEVE PAGE
  // ═══════════════════════════════════════════════════════════════
  static const captainStevePage = Feature(
    id: 'captain_steve_page',
    name: 'Captain Steve AI Chat',
    minTier: 'plus',
    category: 'captain_steve',
  );
}

// Tier hierarchy for comparison
const Map<String, int> tierLevels = {
  'free': 0,
  'plus': 1,
  'premium': 2,
  'pro': 3,
  'admin': 99,
};

/// Check if a user's tier has access to a feature
bool hasAccess(String? userTier, String featureMinTier) {
  // Admin always has access
  if (userTier == 'admin') return true;

  final userLevel = tierLevels[userTier] ?? 0;
  final requiredLevel = tierLevels[featureMinTier] ?? 0;

  return userLevel >= requiredLevel;
}

/// Check if user can access a specific feature
bool canAccessFeature(String? userTier, Feature feature) {
  return hasAccess(userTier, feature.minTier);
}

/// Get max saved cities for tier
int getMaxCities(String? tier) {
  return savedCitiesLimits[tier] ?? 1;
}

/// Get Captain Steve chat limits for tier
Map<String, int> getSteveLimits(String? tier) {
  return captainSteveLimits[tier] ?? captainSteveLimits['free']!;
}

/// Get tier display info
TierInfo? getTierInfo(String? tier) {
  return tierInfo[tier];
}

/// Get the tier name needed to unlock a feature
String getRequiredTierName(String minTier) {
  return tierInfo[minTier]?.name ?? 'Premium';
}
