import 'api_service.dart';
import 'api_config.dart';

/// Service for Field Reports / Observations
class ReportService {
  final ApiService _api = ApiService();

  /// Submit a quick report (conditions match forecast)
  Future<ReportResult> submitQuickReport(double lat, double lon) async {
    try {
      final response = await _api.post(
        ApiConfig.observationsQuick,
        data: {'lat': lat, 'lon': lon},
      );
      return ReportResult(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Report submitted',
      );
    } catch (e) {
      return ReportResult(success: false, message: 'Failed to submit report');
    }
  }

  /// Submit a detailed field report
  Future<ReportResult> submitDetailedReport(FieldReport report) async {
    try {
      final response = await _api.post(
        ApiConfig.observations,
        data: report.toJson(),
      );
      return ReportResult(
        success: response.data['success'] == true,
        message: response.data['message'] ?? 'Report submitted',
      );
    } catch (e) {
      return ReportResult(success: false, message: 'Failed to submit report');
    }
  }

  /// Get my submitted reports
  Future<List<FieldReport>> getMyReports() async {
    try {
      final response = await _api.get(ApiConfig.observationsMine);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['observations'] as List)
            .map((r) => FieldReport.fromJson(r))
            .toList();
      }
    } catch (e) {
      // Error fetching reports
    }
    return [];
  }
}

// ==================== MODELS ====================

class FieldReport {
  final double lat;
  final double lon;
  final String? skyCondition;
  final int? airTemp;
  final String? windSpeed;
  final String? windDirection;
  final int? waterTemp;
  final String? waveHeight;
  final String? wavePeriod;
  final String? waveDirection;
  final String? waterClarity;
  final String? fishingSuccess;
  final String? species;
  final int? fishCount;
  final String? comment;
  final DateTime? createdAt;

  FieldReport({
    required this.lat,
    required this.lon,
    this.skyCondition,
    this.airTemp,
    this.windSpeed,
    this.windDirection,
    this.waterTemp,
    this.waveHeight,
    this.wavePeriod,
    this.waveDirection,
    this.waterClarity,
    this.fishingSuccess,
    this.species,
    this.fishCount,
    this.comment,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      if (skyCondition != null) 'sky_condition': skyCondition,
      if (airTemp != null) 'air_temp': airTemp,
      if (windSpeed != null) 'wind_speed': windSpeed,
      if (windDirection != null) 'wind_direction': windDirection,
      if (waterTemp != null) 'water_temp': waterTemp,
      if (waveHeight != null) 'wave_height': waveHeight,
      if (wavePeriod != null) 'wave_period': wavePeriod,
      if (waveDirection != null) 'wave_direction': waveDirection,
      if (waterClarity != null) 'water_clarity': waterClarity,
      if (fishingSuccess != null) 'fishing_success': fishingSuccess,
      if (species != null) 'species': species,
      if (fishCount != null) 'fish_count': fishCount,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }

  factory FieldReport.fromJson(Map<String, dynamic> json) {
    return FieldReport(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      skyCondition: json['sky_condition'],
      airTemp: json['air_temp'],
      windSpeed: json['wind_speed'],
      windDirection: json['wind_direction'],
      waterTemp: json['water_temp'],
      waveHeight: json['wave_height'],
      wavePeriod: json['wave_period'],
      waveDirection: json['wave_direction'],
      waterClarity: json['water_clarity'],
      fishingSuccess: json['fishing_success'],
      species: json['species'],
      fishCount: json['fish_count'],
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class ReportResult {
  final bool success;
  final String message;

  ReportResult({required this.success, required this.message});
}

// ==================== OPTIONS ====================

class ReportOptions {
  static const List<String> skyConditions = [
    'Sunny',
    'Partly Cloudy',
    'Cloudy',
    'Overcast',
    'Rain',
    'Storms',
  ];

  static const List<String> windSpeeds = [
    'Calm',
    '1-5',
    '5-10',
    '10-15',
    '15-20',
    '20-25',
    '25-30',
    '30+',
  ];

  static const List<String> directions = [
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'
  ];

  static const List<String> waveHeights = [
    '< 1', '1-2', '2-3', '3-4', '4-5', '5-6', '6-8', '8-10', '10+'
  ];

  static const List<String> wavePeriods = [
    '< 5', '5-7', '7-9', '9-11', '11-13', '13-15', '15+'
  ];

  static const List<String> waterClarities = [
    'Crystal Clear',
    'Blue/Clear',
    'Green',
    'Murky',
    'Dirty',
  ];

  static const List<String> fishingSuccesses = [
    'None',
    'Slow',
    'Fair',
    'Good',
    'Excellent',
  ];

  static const List<String> speciesList = [
    'Mahi',
    'Tuna',
    'Wahoo',
    'Marlin',
    'Sailfish',
    'King Mackerel',
    'Cobia',
    'Grouper',
    'Snapper',
    'Red Drum',
    'Speckled Trout',
    'Flounder',
    'Striped Bass',
    'Other',
  ];

  static List<int> get temperatures => List.generate(50, (i) => 50 + i); // 50-99°F
}
