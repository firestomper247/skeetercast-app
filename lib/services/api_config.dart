/// SkeeterCast API Configuration
/// All backend endpoints for the mobile app

class ApiConfig {
  // Base URLs for all SkeeterCast services (via Cloudflare tunnel)
  static const String authBase = 'https://auth.skeetercast.com';
  static const String oceanBase = 'https://ocean.skeetercast.com';
  static const String steveBase = 'https://ai.skeetercast.com';
  static const String radarBase = 'https://radar.skeetercast.com';
  static const String mapsBase = 'https://maps.skeetercast.com';
  static const String mainSite = 'https://skeetercast.com';

  // Auth endpoints
  static const String login = '$authBase/api/login';
  static const String register = '$authBase/api/register';
  static const String refreshToken = '$authBase/api/refresh';
  static const String userProfile = '$authBase/api/profile';
  static const String authHealth = '$authBase/api/health';

  // Ocean/Fishing endpoints
  static const String oceanHealth = '$oceanBase/api/ocean/health';
  static const String latestSST = '$oceanBase/api/ocean/latest-sst';
  static const String latestChlorophyll = '$oceanBase/api/ocean/latest-chlorophyll';
  static const String latestCurrents = '$oceanBase/api/ocean/latest-currents';
  static const String latestWaves = '$oceanBase/api/ocean/latest-waves';
  static const String oceanPointData = '$oceanBase/api/ocean/point-data';
  static const String oceanDataAge = '$oceanBase/api/ocean/data-age';
  static const String oceanTiles = '$oceanBase/api/ocean/tiles';

  // Captain Steve endpoints
  static const String steveRecommendations = '$steveBase/api/captain-steve/recommendations';
  static const String steveSpeciesScores = '$steveBase/api/captain-steve/species-scores';
  static const String steveChat = '$steveBase/api/captain-steve/chat';
  static const String steveStrikeTimes = '$steveBase/api/captain-steve/strike-times';
  static const String steveDataQuality = '$steveBase/api/captain-steve/data-quality';
  static const String steveCityForecast = '$steveBase/api/captain-steve/city-forecast';

  // Radar endpoints
  static const String radarHealth = '$radarBase/health';
  static const String radarFrames = '$radarBase/api/radar/frames';
  static const String satelliteLatest = '$radarBase/api/satellite';
  static const String lightning = '$radarBase/api/lightning/last';
  static const String warnings = '$radarBase/api/warnings/active';

  // Maps endpoints
  static const String mapsHealth = '$mapsBase/api/health';

  // Static content
  static const String weatherVideo = '$mainSite/videos/weather_latest.mp4';
  static const String captainSteveChat = '$mainSite/captain-steve';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}
