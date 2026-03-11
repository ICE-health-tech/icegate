import '../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
// import 'CarTracker.dart';
import 'IOTTracker/IOTTracker.dart';
import '../../../orchestration_layer/Action/WebView/LiveMapPlugin.dart';
import 'WebPlugin/GoogleCalendar.dart';
import 'WebPlugin/Gmail.dart';
import 'WebPlugin/Trello.dart';
import 'Notion/Notion.dart';
import 'WebPlugin/Spotify.dart';
import 'WebPlugin/GitHub.dart';
import 'WebPlugin/Weather.dart';
import 'WebPlugin/CryptoTracker.dart';
import 'TalkSSH/TalkSSH.dart';

/// Registry of all available plugins
class AvailablePlugins {
  static const List<BasePluginProtocol> all = [
    // CarTrackerPlugin(),
    IOTTrackerPlugin(),
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
