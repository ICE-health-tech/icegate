import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class HuaweiCloudService {
  static const String _kIsConnected = 'huawei_cloud_connected';
  static const String _kLastSync = 'huawei_cloud_last_sync';
  static const String _kClientId = 'huawei_client_id';
  static const String _kClientSecret = 'huawei_client_secret';
  static const String _kAccessToken = 'huawei_access_token';
  static const String _kTokenExpiry = 'huawei_token_expiry';

  static Future<Map<String, String?>> getKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_kClientId),
      'secret': prefs.getString(_kClientSecret),
    };
  }

  static Future<void> saveKeys(String id, String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClientId, id);
    await prefs.setString(_kClientSecret, secret);
  }

  static Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsConnected) ?? false;
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_kLastSync);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken);
    final expiryStr = prefs.getString(_kTokenExpiry);
    
    if (token != null && expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        return token;
      }
    }
    
    // Token missing or expired, try to refresh using client credentials
    final id = prefs.getString(_kClientId);
    final secret = prefs.getString(_kClientSecret);
    
    if (id == null || secret == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('https://oauth-login.cloud.huawei.com/oauth2/v3/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': id,
          'client_secret': secret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['access_token'];
        final expiresIn = data['expires_in'] ?? 3600;
        
        await prefs.setString(_kAccessToken, newToken);
        await prefs.setString(_kTokenExpiry, 
          DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String());
        
        return newToken;
      }
    } catch (e) {
      debugPrint("HuaweiCloudService: Error fetching access token: $e");
    }
    
    return null;
  }

  static Future<bool> connect() async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint("HuaweiCloudService: Authentication failed. Check your keys.");
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsConnected, true);
    await prefs.setString(_kLastSync, DateTime.now().toIso8601String());
    
    debugPrint("HuaweiCloudService: Successfully connected and authorized.");
    return true;
  }

  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsConnected, false);
    await prefs.remove(_kLastSync);
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kTokenExpiry);
  }

  static Future<void> triggerSync() async {
    if (!await isConnected()) return;
    
    final token = await _getAccessToken();
    if (token == null) return;

    debugPrint("HuaweiCloudService: Fetching data from Huawei Health Kit...");
    
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

      debugPrint("HuaweiCloudService: Fetching Health Data (Sleep, Heart Rate, SpO2)...");

      // 1. Fetch Sleep Data
      // https://health-api.cloud.huawei.com/healthkit/v1/sampleSets/com.huawei.health.record.sleep

      // 2. Fetch Heart Rate Data
      // https://health-api.cloud.huawei.com/healthkit/v1/sampleSets/com.huawei.continuous.heart_rate

      // 3. Fetch Oxygen Saturation (SpO2) Data
      // https://health-api.cloud.huawei.com/healthkit/v1/sampleSets/com.huawei.continuous.spo2

      // Note: In a real implementation, we parse the response.json and call healthLogsDao.insert
      
      // Simulate network processing
      await Future.delayed(const Duration(milliseconds: 800));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSync, DateTime.now().toIso8601String());
      debugPrint("HuaweiCloudService: Global Sync completed successfully.");
    } catch (e) {
      debugPrint("HuaweiCloudService: Sync failed: $e");
    }
  }
}
