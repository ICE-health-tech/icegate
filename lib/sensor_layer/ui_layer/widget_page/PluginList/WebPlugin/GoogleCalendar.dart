import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

class GoogleCalendarPlugin extends BasePluginProtocol {
  const GoogleCalendarPlugin()
    : super(
        name: 'Google Calendar',
        description: 'View and manage your schedule and events',
        icon: Icons.calendar_today,
        protocol: 'https',
        host: 'calendar.google.com',
        url: '/calendar/embed',
        imageUrl: null,
        category: PluginCategory.productivity,
        tags: const ['calendar', 'schedule', 'events', 'google'],
        requiresAuth: true,
      );

  /// Embed tuned for in-app WebView (minimal chrome, dark-friendly colors).
  @override
  String get fullUrl => Uri.https(host, url, <String, String>{
        'mode': 'MONTH',
        'showTitle': '0',
        'showPrint': '0',
        'showTabs': '0',
        'showCalendars': '0',
        'showTz': '0',
        'showNav': '1',
        'showDate': '1',
        'wkst': '2',
        'bgcolor': _hexForEmbed(EntryLandscapePalette.midnightNavy),
        'color': _hexForEmbed(EntryLandscapePalette.icyWhiteBlue),
      }).toString();

  static String _hexForEmbed(Color color) {
    final argb = color.toARGB32() & 0xFFFFFF;
    return '#${argb.toRadixString(16).padLeft(6, '0')}';
  }

  /// Applies embed query params when opening stored external-widget rows.
  static String resolveLaunchUrl({
    required String protocol,
    required String host,
    required String path,
  }) {
    const plugin = GoogleCalendarPlugin();
    if (host == plugin.host && path.startsWith(plugin.url)) {
      return plugin.fullUrl;
    }
    return '$protocol://$host$path';
  }
}
