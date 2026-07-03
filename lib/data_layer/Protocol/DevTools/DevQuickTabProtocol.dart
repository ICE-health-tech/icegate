import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

/// Saved browser tab for dev-tool quick access.
class DevQuickTabProtocol {
  const DevQuickTabProtocol({
    required this.id,
    required this.title,
    required this.fullUrl,
    this.sortOrder = 0,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String fullUrl;
  final int sortOrder;
  final bool isPinned;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fullUrl': fullUrl,
    'sortOrder': sortOrder,
    'isPinned': isPinned,
  };

  factory DevQuickTabProtocol.fromJson(Map<String, dynamic> json) {
    return DevQuickTabProtocol(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fullUrl: json['fullUrl'] as String? ?? '',
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : 0,
      isPinned: json['isPinned'] as bool? ?? false,
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
    int? sortOrder,
    bool? isPinned,
  }) {
    return DevQuickTabProtocol(
      id: id ?? this.id,
      title: title ?? this.title,
      fullUrl: fullUrl ?? this.fullUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
