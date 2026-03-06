import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

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
}
