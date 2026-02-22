//  --- DATA CLASS (InternalWidgetData) ---
// This part is assumed to be correct based on the protocol requirements
// import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';

import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'PluginProtocol.dart';

class InternalWidgetProtocol implements PluginProtocol {
  // Existing fields
  final String _url;
  final String _name;
  final String? _imageUrl;
  final String _dateAdded;
  final int _widgetID;
  final String _alias;

  // NEW: Enhanced metadata fields
  final String _description;
  final IconData _icon;
  final String _protocol;
  final String _host;
  final PluginCategory _category;
  final List<String> _tags;
  final bool _isActive;
  final bool _requiresAuth;

  // Getters for existing fields
  @override
  String get url => _url;

  @override
  String get name => _name;

  @override
  String? get imageUrl => _imageUrl;

  @override
  String get dateAdded => _dateAdded;

  @override
  String get alias => _alias;

  @override
  int get widgetID => _widgetID;

  // Getters for new fields
  @override
  String get description => _description;

  @override
  IconData get icon => _icon;

  @override
  String get protocol => _protocol;

  @override
  String get host => _host;

  @override
  PluginCategory get category => _category;

  @override
  List<String> get tags => _tags;

  @override
  bool get isActive => _isActive;

  bool get requiresAuth => _requiresAuth;

  @override
  String get fullUrl => '$_protocol://$_host$_url';

  InternalWidgetProtocol({
    required String url,
    required String name,
    required String alias,
    required String dateAdded,
    required int widgetID,
    String? imageUrl,
    // NEW: Enhanced parameters with defaults for backward compatibility
    String description = '',
    IconData icon = Icons.widgets,
    String protocol = 'https',
    String host = '',
    PluginCategory category = PluginCategory.other,
    List<String> tags = const [],
    bool isActive = false,
    bool requiresAuth = false,
  }) : _url = url,
       _name = name,
       _imageUrl = imageUrl,
       _dateAdded = dateAdded,
       _widgetID = widgetID,
       _alias = alias,
       _description = description,
       _icon = icon,
       _protocol = protocol,
       _host = host,
       _category = category,
       _tags = tags,
       _isActive = isActive,
       _requiresAuth = requiresAuth;

  @override
  InternalWidgetProtocol createInstance({
    String? customAlias,
    required int widgetID,
    required String dateAdded,
  }) {
    return InternalWidgetProtocol(
      url: _url,
      name: _name,
      alias: customAlias ?? _alias,
      dateAdded: dateAdded,
      widgetID: widgetID,
      imageUrl: _imageUrl,
      description: _description,
      icon: _icon,
      protocol: _protocol,
      host: _host,
      category: _category,
      tags: _tags,
      isActive: _isActive,
      requiresAuth: _requiresAuth,
    );
  }

  @override
  InternalWidgetData toDatabase() {
    return InternalWidgetData(
      id: IDGen.generateUuid(),
      url: _url,
      name: _name,
      imageUrl: _imageUrl ?? 'Unknown',
      dateAdded: _dateAdded,
      widgetID: _widgetID,
      alias: _alias,
    );
  }

  /// Static adapter method for backward compatibility
  static InternalWidgetProtocol adapterList(InternalWidgetData data) {
    return InternalWidgetProtocol(
      widgetID: data.widgetID ?? 0,

      // Use null-coalescing (??) instead of (!) for all table fields
      name: data.name ?? 'Untitled',
      url: data.url ?? '/',
      alias: data.alias ?? '',

      // SAFE CHECK: This prevents the specific "Null check" crash
      imageUrl: (data.imageUrl != null && data.imageUrl!.isNotEmpty)
          ? data.imageUrl!
          : 'assets/internalwidget/default.png',

      dateAdded: data.dateAdded ?? DateTime.now().toIso8601String(),
     
      // Use defaults for new fields when adapting from database
      description: 'Unknown',
      icon: getIconFromName(data.name ?? ''),
      protocol: 'https',
      host: 'Unknown',
      category: PluginCategory.other,
      tags: const [],
      isActive: false,
      requiresAuth: false,
    );
  }

  static IconData getIconFromName(String name) {
    final lower = name.toLowerCase();

    // Strict matching for 'UI'
    if (lower == 'ui' ||
        lower.contains(' ui ') ||
        lower.startsWith('ui ') ||
        lower.endsWith(' ui') ||
        lower.contains('user interface') ||
        lower.contains('design')) {
      return Icons.design_services;
    }

    if (lower.contains('health') ||
        lower.contains('heart') ||
        lower.contains('fit')) {
      return Icons.favorite;
    }
    if (lower.contains('finance') ||
        lower.contains('money') ||
        lower.contains('wallet') ||
        lower.contains('bank')) {
      return Icons.account_balance_wallet;
    }
    if (lower.contains('social') ||
        lower.contains('chat') ||
        lower.contains('friend')) {
      return Icons.people;
    }
    if (lower.contains('calendar') ||
        lower.contains('schedule') ||
        lower.contains('date')) {
      return Icons.calendar_month;
    }
    if (lower.contains('map') ||
        lower.contains('gps') ||
        lower.contains('location')) {
      return Icons.map;
    }
    if (lower.contains('music') ||
        lower.contains('song') ||
        lower.contains('audio')) {
      return Icons.music_note;
    }
    if (lower.contains('weather') ||
        lower.contains('forecast') ||
        lower.contains('sun')) {
      return Icons.wb_sunny;
    }
    if (lower.contains('widget') || lower.contains('component')) {
      return Icons.widgets;
    }
    if (lower.contains('setting') || lower.contains('config')) {
      return Icons.settings;
    }
    if (lower.contains('news') || lower.contains('article')) {
      return Icons.newspaper;
    }
    if (lower.contains('shop') || lower.contains('cart')) {
      return Icons.shopping_cart;
    }
    if (lower.contains('video') || lower.contains('movie')) return Icons.movie;

    return Icons.dashboard_customize; // Default fallback
  }
}
