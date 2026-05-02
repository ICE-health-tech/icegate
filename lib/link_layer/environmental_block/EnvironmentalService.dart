import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentalData {
  final double temperature;
  final int weatherCode;
  final int aqi;
  final double pm25;
  final double pm10;

  EnvironmentalData({
    required this.temperature,
    required this.weatherCode,
    required this.aqi,
    required this.pm25,
    required this.pm10,
  });

  String get weatherDescription {
    // Basic mapping based on WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 57) return 'Drizzle';
    if (weatherCode <= 67) return 'Rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Rain showers';
    if (weatherCode <= 86) return 'Snow showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String get aqiStatus {
    if (aqi <= 50) return 'Excellent';
    if (aqi <= 100) return 'Good';
    if (aqi <= 150) return 'Lightly Polluted';
    if (aqi <= 200) return 'Moderately Polluted';
    if (aqi <= 300) return 'Heavily Polluted';
    return 'Severely Polluted';
  }
}

class EnvironmentalService {
  /// Fetch weather and air quality data for the given coordinates.
  static Future<EnvironmentalData?> fetchEnvironmentalData(double lat, double lon) async {
    try {
      // 1. Fetch Weather from Open-Meteo
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
      );
      
      // 2. Fetch Air Quality from WAQI (AQICN)
      final waqiToken = dotenv.env['WAQI_TOKEN'] ?? "";
      final aqiUrl = Uri.parse(
        'https://api.waqi.info/feed/geo:$lat;$lon/?token=$waqiToken',
      );

      debugPrint('🌍 [Env] Fetching Weather from: $weatherUrl');
      debugPrint('🌍 [Env] Fetching AQI from: $aqiUrl');
      debugPrint('🌍 [Env] WAQI Token present: ${waqiToken.isNotEmpty}');

      // Run both requests in parallel
      final results = await Future.wait([
        http.get(weatherUrl).catchError((e) {
          debugPrint('🌍 [Env] Weather Request Error: $e');
          return http.Response('{"error": "$e"}', 500);
        }),
        http.get(aqiUrl).catchError((e) {
          debugPrint('🌍 [Env] AQI Request Error: $e');
          return http.Response('{"error": "$e"}', 500);
        }),
      ]).timeout(const Duration(seconds: 10));

      final weatherRes = results[0];
      final aqiRes = results[1];

      debugPrint('🌍 [Env] Weather Response Code: ${weatherRes.statusCode}');
      debugPrint('🌍 [Env] AQI Response Code: ${aqiRes.statusCode}');

      double temp = 0.0;
      int weatherCode = 0;
      int aqiValue = 0;
      double pm25 = 0.0;
      double pm10 = 0.0;
      bool hasWeatherData = false;
      bool hasAqiData = false;

      // Process Weather
      if (weatherRes.statusCode == 200) {
        try {
          final weatherJson = json.decode(weatherRes.body);
          temp = weatherJson['current']?['temperature_2m']?.toDouble() ?? 0.0;
          weatherCode = weatherJson['current']?['weather_code']?.toInt() ?? 0;
          hasWeatherData = true;
          debugPrint('🌍 [Env] Weather Data: $temp°C, code: $weatherCode');
        } catch (e) {
          debugPrint('🌍 [Env] Error parsing Weather JSON: $e. Body: ${weatherRes.body}');
        }
      } else {
        debugPrint('🌍 [Env] Weather Failed: ${weatherRes.body}');
      }

      // Process AQI
      if (aqiRes.statusCode == 200) {
        try {
          final aqiJson = json.decode(aqiRes.body);
          if (aqiJson['status'] == 'ok') {
            final data = aqiJson['data'];
            final iaqi = data['iaqi'] ?? {};
            aqiValue = data['aqi']?.toInt() ?? 0;
            pm25 = iaqi['pm25']?['v']?.toDouble() ?? 0.0;
            pm10 = iaqi['pm10']?['v']?.toDouble() ?? 0.0;
            hasAqiData = true;
            debugPrint('🌍 [Env] AQI Data: $aqiValue, PM2.5: $pm25, PM10: $pm10');
          } else {
            debugPrint('🌍 [Env] AQI API Status NOT OK: ${aqiJson['status']}. Body: ${aqiRes.body}');
          }
        } catch (e) {
          debugPrint('🌍 [Env] Error parsing AQI JSON: $e. Body: ${aqiRes.body}');
        }
      } else {
        debugPrint('🌍 [Env] AQI Failed with status ${aqiRes.statusCode}: ${aqiRes.body}');
      }

      // Return data if we have at least one source
      if (hasWeatherData || hasAqiData) {
        return EnvironmentalData(
          temperature: temp,
          weatherCode: weatherCode,
          aqi: aqiValue,
          pm25: pm25,
          pm10: pm10,
        );
      }
      
      debugPrint('🌍 [Env] Failed to fetch both Weather and AQI data.');
    } catch (e) {
      debugPrint('🌍 [Env] Critical error in fetchEnvironmentalData: $e');
    }
    return null;
  }
}
