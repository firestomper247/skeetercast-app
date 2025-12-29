/// SkeeterCast API Configuration
/// All backend endpoints for the mobile app

class ApiConfig {
  // Base URLs for all SkeeterCast services
  static const String forecastBase = 'https://forecast.skeetercast.com';
  static const String oceanBase = 'https://ocean.skeetercast.com';
  static const String aiBase = 'https://ai.skeetercast.com';
  static const String radarBase = 'https://radar.skeetercast.com';
  static const String authBase = 'https://auth.skeetercast.com';
  static const String inletBase = 'https://inlet.skeetercast.com';
  static const String mapsBase = 'https://maps.skeetercast.com';
  static const String mainSite = 'https://skeetercast.com';
  
  // Auth endpoints
  static const String login = '$authBase/api/login';
  static const String register = '$authBase/api/register';
  static const String refreshToken = '$authBase/api/refresh';
  static const String userProfile = '$authBase/api/user';
  
  // Forecast endpoints
  static const String cityForecast = '$forecastBase/api/forecast';
  static const String savedCities = '$forecastBase/api/cities';
  
  // Ocean/Fishing endpoints
  static const String oceanConditions = '$oceanBase/api/conditions';
  static const String speciesScores = '$oceanBase/api/species';
  static const String sstData = '$oceanBase/api/sst';
  static const String tides = '$oceanBase/api/tides';
  
  // Captain Steve endpoints
  static const String weatherVideo = '$mainSite/videos/weather_latest.mp4';
  static const String steveRecommendations = '$aiBase/api/recommendations';
  static const String fishingPicks = '$aiBase/api/picks';
  
  // Radar endpoints
  static const String radarTiles = '$radarBase/tiles';
  static const String alerts = '$radarBase/api/alerts';
  
  // Inlet endpoints  
  static const String inletConditions = '$inletBase/api/conditions';
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}
