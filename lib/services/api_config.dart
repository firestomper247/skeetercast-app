/// SkeeterCast API Configuration
/// All backend endpoints for the mobile app

class ApiConfig {
  // Base URLs for all SkeeterCast services (via Cloudflare tunnel)
  static const String authBase = 'https://auth.skeetercast.com';
  static const String oceanBase = 'https://ocean.skeetercast.com';
  static const String steveBase = 'https://steve.skeetercast.com';
  static const String radarBase = 'https://radar.skeetercast.com';
  static const String mapsBase = 'https://maps.skeetercast.com';
  static const String mainSite = 'https://skeetercast.com';

  // Auth endpoints
  static const String login = '$authBase/api/login';
  static const String register = '$authBase/api/register';
  static const String refreshToken = '$authBase/api/refresh';
  static const String userProfile = '$authBase/api/profile';
  static const String changePassword = '$authBase/api/change-password';
  static const String resendVerification = '$authBase/api/resend-verification';
  static const String deleteAccount = '$authBase/api/account';
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

  // Forecast endpoints (full weather data)
  static String forecastByCity(String city) => '$mainSite/api/forecast/city/$city';
  static String forecastByZipcode(String zip) => '$mainSite/api/forecast/zipcode/$zip';
  static String forecastByCoords(double lat, double lon) =>
      '$mainSite/api/forecast/coords?lat=$lat&lon=$lon';
  static String warningsByLocation(double lat, double lon) =>
      '$radarBase/api/warnings/location?lat=$lat&lon=$lon';

  // Saved Cities endpoints
  static const String savedCities = '$authBase/api/saved-cities';
  static String deleteSavedCity(int cityId) => '$authBase/api/saved-cities/$cityId';

  // Buddies/Friends endpoints
  static const String friends = '$authBase/api/friends';
  static const String friendsPending = '$authBase/api/friends/pending';
  static const String friendsRequest = '$authBase/api/friends/request';
  static String friendsAccept(int requestId) => '$authBase/api/friends/accept/$requestId';
  static String friendsReject(int requestId) => '$authBase/api/friends/reject/$requestId';
  static String friendsDelete(int friendId) => '$authBase/api/friends/$friendId';

  // Messages endpoints
  static String messages(int friendId) => '$authBase/api/messages/$friendId';
  static String messagesLocation(int friendId) => '$authBase/api/messages/$friendId/location';
  static String messagesHookup(int friendId) => '$authBase/api/messages/$friendId/hookup';
  static const String messagesUnread = '$authBase/api/messages/unread';

  // Field Report/Observations endpoints
  static const String observations = '$authBase/api/observations';
  static const String observationsQuick = '$authBase/api/observations/quick';
  static const String observationsMine = '$authBase/api/observations/mine';

  // Device Token endpoints (push notifications)
  static const String deviceToken = '$authBase/api/device-token';
  static String deleteDeviceToken(String token) => '$authBase/api/device-token/$token';

  // User Fishing Spots endpoints
  static const String userSpots = '$authBase/api/spots';
  static String deleteSpot(int spotId) => '$authBase/api/spots/$spotId';

  // SSH Anomaly Contours (GeoJSON) - shows warm/cold eddies
  static const String sshContours = '$oceanBase/api/ocean/ssh-anomaly';

  // Offshore forecast (weather + waves)
  static String offshoreForecast(double lat, double lon) =>
      '$oceanBase/api/ocean/offshore-forecast?lat=${lat.toStringAsFixed(4)}&lon=${lon.toStringAsFixed(4)}';

  // Inshore endpoints
  static String inshoreConditions(double lat, double lon) =>
      '$mainSite/api/inshore/conditions?lat=$lat&lon=$lon';
  static const String inshoreOysterBeds = '$mainSite/data/inshore/oyster-sanctuaries.geojson';
  static const String inshoreArtificialReefs = '$mainSite/data/inshore/artificial-reefs.geojson';
  static const String inshoreSeagrass = '$mainSite/data/inshore/sav-beds.geojson';
  static const String inshoreBoatRamps = '$mainSite/data/inshore/boat-ramps.geojson';
  static const String inshoreShellBottom = '$mainSite/data/inshore/shell-bottom.geojson';

  // Inlet endpoints
  static const String inletBase = 'https://inlet.skeetercast.com';
  static const String inletsConfig = '$mainSite/data/inlets_config.json';
  static const String inletTides = '$mainSite/data/nc_inlet_tides.json';
  static const String inletWinds = '$mainSite/data/inlet_winds.json';
  static const String waveData = '$mainSite/data/skeeterwave.json';
  static String channelSurvey(String inletId) => '$mainSite/data/channel_surveys/$inletId.json';
  static const String channelSurveySummary = '$mainSite/data/channel_surveys/summary.json';

  // Static content
  static const String weatherVideo = '$mainSite/videos/weather_latest.mp4';
  static const String captainSteveChat = '$mainSite/captain-steve';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}
