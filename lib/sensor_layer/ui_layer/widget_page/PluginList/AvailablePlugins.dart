import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
// import 'CarTracker.dart';
// import 'IOTTracker/IOTTracker.dart';
import 'package:ice_gate/orchestration_layer/Action/WebView/LiveMapPlugin.dart';
import 'WebPlugin/GoogleCalendar.dart';
import 'WebPlugin/Gmail.dart';
import 'WebPlugin/Trello.dart';
import 'Notion/Notion.dart';
import 'WebPlugin/Spotify.dart';
import 'WebPlugin/GitHub.dart';
import 'WebPlugin/Weather.dart';
import 'WebPlugin/CryptoTracker.dart';
import 'TalkSSH/TalkSSH.dart';

class _InternalPlugin extends BasePluginProtocol {
  const _InternalPlugin({
    required super.name,
    required super.url,
    required super.icon,
    super.description = '',
    super.category = PluginCategory.other,
  }) : super(protocol: 'internal', host: 'app');
}

/// Registry of all available plugins
class AvailablePlugins {
  static const List<BasePluginProtocol> internal = [
    _InternalPlugin(
      name: 'Health',
      url: '/health',
      icon: Icons.favorite_rounded,
      category: PluginCategory.fitness,
    ),
    _InternalPlugin(
      name: 'Finance',
      url: '/finance',
      icon: Icons.account_balance_wallet_rounded,
      category: PluginCategory.finance,
    ),
    _InternalPlugin(
      name: 'Projects',
      url: '/projects',
      icon: Icons.rocket_launch_rounded,
      category: PluginCategory.productivity,
    ),
    _InternalPlugin(
      name: 'Focus',
      url: '/health/focus',
      icon: Icons.timer_rounded,
      category: PluginCategory.productivity,
    ),
    _InternalPlugin(
      name: 'Social',
      url: '/social',
      icon: Icons.people_alt_rounded,
      category: PluginCategory.social,
    ),
    _InternalPlugin(
      name: 'Music',
      url: '/social/skills',
      icon: Icons.music_note_rounded,
      category: PluginCategory.social,
    ),
    _InternalPlugin(
      name: 'Profile',
      url: '/profile',
      icon: Icons.person_rounded,
      category: PluginCategory.other,
    ),
    _InternalPlugin(
      name: 'Notes',
      url: '/projects/editor',
      icon: Icons.edit_note_rounded,
      category: PluginCategory.productivity,
    ),
    _InternalPlugin(
      name: 'Location Tracker',
      url: '/gps',
      icon: Icons.location_on_rounded,
      category: PluginCategory.other,
    ),
    _InternalPlugin(
      name: 'Block Reminder',
      url: '/health/block-reminder',
      icon: Icons.timer_rounded,
      category: PluginCategory.productivity,
    ),
    _InternalPlugin(
      name: 'Settings',
      url: '/settings',
      icon: Icons.settings_rounded,
      category: PluginCategory.other,
    ),
    _InternalPlugin(
      name: 'UPLINK',
      url: '/widgets/ssh',
      icon: Icons.terminal_rounded,
      category: PluginCategory.other,
    ),
    _InternalPlugin(
      name: 'Social Blocker',
      url: '/social/blocker',
      icon: Icons.shield_moon_rounded,
      category: PluginCategory.productivity,
    ),
  ];

  static const List<BasePluginProtocol> all = [
    // CarTrackerPlugin(),
    // IOTTrackerPlugin(),
    // OSMMapPlugin(),
    LiveMapPlugin(),
    GoogleCalendarPlugin(),
    GmailPlugin(),
    TrelloPlugin(),
    NotionPlugin(),
    SpotifyPlugin(),
    GitHubPlugin(),
    WeatherPlugin(),
    CryptoTrackerPlugin(),
    TalkSSHPlugin(),
    // MapPlugin(),
  ];

  /// Get plugins by category
  static List<BasePluginProtocol> getByCategory(PluginCategory category) {
    return all.where((p) => p.category == category).toList();
  }

  /// Search plugins by name, description, or tags
  static List<BasePluginProtocol> search(String query) {
    final lowerQuery = query.toLowerCase();
    return all.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          p.description.toLowerCase().contains(lowerQuery) ||
          p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get plugin by name
  static BasePluginProtocol? getByName(String name) {
    try {
      return all.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all categories that have at least one plugin
  static List<PluginCategory> getAvailableCategories() {
    return all.map((p) => p.category).toSet().toList();
  }
}
