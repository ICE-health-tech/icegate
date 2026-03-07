import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';

class WeatherPlugin extends BasePluginProtocol {
  const WeatherPlugin()
    : super(
        name: 'Weather',
        description: 'Check current weather and forecast',
        icon: Icons.wb_sunny,
        protocol: 'https',
        host: 'weather.com',
        url: '/',
        imageUrl: null,
        category: PluginCategory.other,
        tags: const ['weather', 'forecast', 'climate'],
        requiresAuth: false,
      );
}
