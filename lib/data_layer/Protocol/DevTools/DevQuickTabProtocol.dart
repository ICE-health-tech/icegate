import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

/// Saved browser tab for dev-tool quick access.
class DevQuickTabProtocol {
  const DevQuickTabProtocol({
    required this.id,
    required this.title,
    required this.fullUrl,
    this.remoteUrl = '',
    this.sortOrder = 0,
    this.isPinned = false,
    this.username = '',
    this.password = '',
    this.passkey = '',
    this.loginType = 'html_form',
  });

  final String id;
  final String title;
  /// Homelab / LAN URL.
  final String fullUrl;
  /// Public or VPN URL when off-LAN.
  final String remoteUrl;
  final int sortOrder;
  final bool isPinned;
  final String username;
  final String password;
  final String passkey;
  final String loginType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fullUrl': fullUrl,
    'remoteUrl': remoteUrl,
    'sortOrder': sortOrder,
    'isPinned': isPinned,
    'username': username,
    'password': password,
    'passkey': passkey,
    'loginType': loginType,
  };

  factory DevQuickTabProtocol.fromJson(Map<String, dynamic> json) {
    return DevQuickTabProtocol(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fullUrl: json['fullUrl'] as String? ?? '',
      remoteUrl: json['remoteUrl'] as String? ?? '',
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : 0,
      isPinned: json['isPinned'] as bool? ?? false,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      passkey: json['passkey'] as String? ?? '',
      loginType: json['loginType'] as String? ?? 'html_form',
    );
  }

  factory DevQuickTabProtocol.fromPlugin(BasePluginProtocol plugin) {
    return DevQuickTabProtocol(
      id: IDGen.generateUuid(),
      title: plugin.name,
      fullUrl: plugin.fullUrl,
    );
  }

  DevQuickTabProtocol copyWith({
    String? id,
    String? title,
    String? fullUrl,
    String? remoteUrl,
    int? sortOrder,
    bool? isPinned,
    String? username,
    String? password,
    String? passkey,
    String? loginType,
  }) {
    return DevQuickTabProtocol(
      id: id ?? this.id,
      title: title ?? this.title,
      fullUrl: fullUrl ?? this.fullUrl,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isPinned: isPinned ?? this.isPinned,
      username: username ?? this.username,
      password: password ?? this.password,
      passkey: passkey ?? this.passkey,
      loginType: loginType ?? this.loginType,
    );
  }

  bool get hasAnyUrl =>
      fullUrl.trim().isNotEmpty || remoteUrl.trim().isNotEmpty;

  Iterable<String> get allUrls sync* {
    if (fullUrl.trim().isNotEmpty) yield fullUrl.trim();
    if (remoteUrl.trim().isNotEmpty) yield remoteUrl.trim();
  }

  Iterable<String> get allHosts sync* {
    for (final url in allUrls) {
      final host = Uri.tryParse(url)?.host ?? '';
      if (host.isNotEmpty) yield host;
    }
  }

  String get listSubtitle {
    final local = fullUrl.trim();
    final remote = remoteUrl.trim();
    if (local.isNotEmpty && remote.isNotEmpty) {
      return '$local\n↳ $remote';
    }
    return local.isNotEmpty ? local : remote;
  }
}
