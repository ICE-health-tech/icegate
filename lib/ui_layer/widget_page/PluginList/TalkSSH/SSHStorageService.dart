import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SSHHostModel.dart';

class SSHStorageService {
  static const String _hostsKey = 'ssh_hosts_list';
  static const String _passwordPrefix = 'ssh_pass_';
  
  final _secureStorage = const FlutterSecureStorage();

  /// Save a host to history. Password is saved in SecureStorage.
  Future<void> saveHost(SSHHostModel host) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Get existing hosts
    List<SSHHostModel> hosts = await loadHosts();
    
    // 2. Update or Add
    final index = hosts.indexWhere((h) => h.id == host.id || (h.host == host.host && h.user == host.user));
    if (index != -1) {
      hosts[index] = host;
    } else {
      hosts.add(host);
    }

    // 3. Save hosts list to SharedPreferences (without passwords)
    final hostsJson = hosts.map((h) => h.toJson(includePassword: false)).toList();
    await prefs.setString(_hostsKey, jsonEncode(hostsJson));

    // 4. Save password to SecureStorage if it exists
    if (host.password != null) {
      await _secureStorage.write(
        key: '$_passwordPrefix${host.id}',
        value: host.password,
      );
    }
  }

  /// Load all saved hosts from history
  Future<List<SSHHostModel>> loadHosts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? hostsString = prefs.getString(_hostsKey);
    
    if (hostsString == null) return [];
    
    final List<dynamic> decoded = jsonDecode(hostsString);
    List<SSHHostModel> hosts = decoded.map((item) => SSHHostModel.fromJson(item)).toList();
    
    // Fetch passwords from SecureStorage
    for (var host in hosts) {
      host.password = await _secureStorage.read(key: '$_passwordPrefix${host.id}');
    }
    
    return hosts;
  }

  /// Delete a host and its password
  Future<void> deleteHost(String hostId) async {
    final prefs = await SharedPreferences.getInstance();
    List<SSHHostModel> hosts = await loadHosts();
    
    hosts.removeWhere((h) => h.id == hostId);
    
    final hostsJson = hosts.map((h) => h.toJson(includePassword: false)).toList();
    await prefs.setString(_hostsKey, jsonEncode(hostsJson));
    
    await _secureStorage.delete(key: '$_passwordPrefix$hostId');
  }
}
