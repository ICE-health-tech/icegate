import 'package:uuid/uuid.dart';

class SSHHostModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final String user;
  String? password;
  String? remoteFilePath;
  final DateTime lastUsed;
  String? aiMode;
  String? aiPromptPrefix;

  SSHHostModel({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.user,
    this.password,
    this.remoteFilePath,
    DateTime? lastUsed,
    this.aiMode,
    this.aiPromptPrefix,
  }) : id = id ?? const Uuid().v4(),
       lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson({bool includePassword = false, bool includeHost = false}) {
    return {
      'id': id,
      'name': name,
      if (includeHost) 'host': host,
      'port': port,
      'user': user,
      if (includePassword) 'password': password,
      if (includePassword) 'remoteFilePath': remoteFilePath,
      'lastUsed': lastUsed.toIso8601String(),
      'aiMode': aiMode,
      'aiPromptPrefix': aiPromptPrefix,
    };
  }

  factory SSHHostModel.fromJson(Map<String, dynamic> json) {
    return SSHHostModel(
      id: json['id'],
      name: json['name'],
      host: json['host'] ?? '',
      port: json['port'] ?? 22,
      user: json['user'],
      password: json['password'],
      remoteFilePath: json['remoteFilePath'],
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      aiMode: json['aiMode'],
      aiPromptPrefix: json['aiPromptPrefix'],
    );
  }
}
