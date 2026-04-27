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
      // 1. Fetch Weather from Open-Meteo (Still reliable for temp)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
      );
      
      // 2. Fetch Air Quality from WAQI (AQICN) - Better for Vietnam/Hanoi
      final waqiToken = dotenv.env['WAQI_TOKEN'] ?? "";
      final aqiUrl = Uri.parse(
        'https://api.waqi.info/feed/geo:$lat;$lon/?token=$waqiToken',
      );

      debugPrint('🌍 [Env] Fetching for: $lat, $lon');
      debugPrint('🌍 [Env] Token: ${waqiToken.isNotEmpty ? "SET (ends with ...${waqiToken.substring(waqiToken.length > 5 ? waqiToken.length - 5 : 0)})" : "MISSING"}');

      final responses = await Future.wait([
        http.get(weatherUrl),
        http.get(aqiUrl),
      ]).timeout(const Duration(seconds: 10));

      debugPrint('🌍 [Env] Weather Status: ${responses[0].statusCode}');
      debugPrint('🌍 [Env] AQI Status: ${responses[1].statusCode}');

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final weatherJson = json.decode(responses[0].body);
        final aqiJson = json.decode(responses[1].body);

        if (aqiJson['status'] == 'ok') {
          final data = aqiJson['data'];
          final iaqi = data['iaqi'] ?? {};
          
          final temp = weatherJson['current']?['temperature_2m']?.toDouble() ?? 0.0;
          final code = weatherJson['current']?['weather_code']?.toInt() ?? 0;
          final aqiValue = data['aqi']?.toInt() ?? 0;

          debugPrint('🌍 [Env] Success: Temp $temp, AQI $aqiValue');
          
          return EnvironmentalData(
            temperature: temp,
            weatherCode: code,
            aqi: aqiValue,
            pm25: iaqi['pm25']?['v']?.toDouble() ?? 0.0,
            pm10: iaqi['pm10']?['v']?.toDouble() ?? 0.0,
          );
        } else {
          debugPrint('🌍 [Env] AQI Status NOT OK: ${aqiJson['status']} - ${aqiJson['data']}');
        }
      } else {
        debugPrint('Failed to fetch environmental data: ${responses[0].statusCode} / ${responses[1].statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching environmental data: $e');
    }
    return null;
  }
}
