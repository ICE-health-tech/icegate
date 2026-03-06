import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';

class CryptoTrackerPlugin extends BasePluginProtocol {
  const CryptoTrackerPlugin()
    : super(
        name: 'Crypto Tracker',
        description: 'Monitor cryptocurrency prices and portfolio',
        icon: Icons.currency_bitcoin,
        protocol: 'https',
        host: 'coinmarketcap.com',
        url: '/',
        imageUrl: null,
        category: PluginCategory.finance,
        tags: const ['crypto', 'bitcoin', 'portfolio', 'trading'],
        requiresAuth: false,
      );
}
