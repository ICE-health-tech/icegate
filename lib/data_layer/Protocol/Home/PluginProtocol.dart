import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

/// Plugin categories for organization and filtering
enum PluginCategory {
  productivity,
  development,
  communication,
  tracking,
  entertainment,
  finance,
  fitness,
  social,
  other,
}

/// Base protocol for all plugins - combines definition and instance data
/// This provides a unified interface for both plugin templates and instances
abstract class PluginProtocol {
  // Definition data (template) - describes what the plugin is
  String get name;
  String get description;
  IconData get icon;
  String get protocol;
  String get host;
  String get url;
  String? get imageUrl;

  // Instance data (runtime) - describes a specific plugin instance
  String get alias;
  String get dateAdded;
  String get widgetID;

  // Category and metadata for enhanced functionality
  PluginCategory get category;
  List<String> get tags;
  bool get isActive;

  /// Factory method to create a new instance from this plugin definition
  /// This allows easy conversion from template to actual widget instance
  PluginProtocol createInstance({
    String? customAlias,
    required String widgetID,
    required String dateAdded,
  });

  /// Convert this plugin to a database model for persistence
  InternalWidgetData toDatabase();

  /// Get the full URL for this plugin
  String get fullUrl => '$protocol://$host$url';
}
