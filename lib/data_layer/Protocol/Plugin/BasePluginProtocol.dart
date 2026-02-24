import 'package:flutter/material.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:ice_shield/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

/// Base class for plugin definitions (templates)
/// This represents a plugin template that can be instantiated multiple times
/// Each plugin should extend this class and provide its metadata
abstract class BasePluginProtocol {
  final String name;
  final String description;
  final IconData icon;
  final String protocol;
  final String host;
  final String url;
  final String? imageUrl;
  final PluginCategory category;
  final List<String> tags;
  final bool requiresAuth;

  const BasePluginProtocol({
    required this.name,
    required this.description,
    required this.icon,
    required this.protocol,
    required this.host,
    required this.url,
    this.imageUrl,
    this.category = PluginCategory.other,
    this.tags = const [],
    this.requiresAuth = false,
  });

  /// Create a plugin instance from this definition
  /// This is the factory method that converts a template into an actual widget instance
  InternalWidgetProtocol createInstance({
    String? customAlias,
    String? customWidgetID,
  }) {
    return InternalWidgetProtocol(
      name: name,
      url: url,
      imageUrl: imageUrl,
      alias: customAlias ?? name,
      widgetID: customWidgetID ?? IDGen.generateUuid(),
      dateAdded: DateTime.now().toString(),
      description: description,
      icon: icon,
      protocol: protocol,
      host: host,
      category: category,
      tags: tags,
      requiresAuth: requiresAuth,
    );
  }

  /// Get the full URL for this plugin
  String get fullUrl => '$protocol://$host$url';
}
