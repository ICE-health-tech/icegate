import 'package:flutter/material.dart';
import '../../../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';

class SpotifyPlugin extends BasePluginProtocol {
  const SpotifyPlugin()
    : super(
        name: 'Spotify',
        description: 'Control your music and playlists',
        icon: Icons.music_note,
        protocol: 'https',
        host: 'open.spotify.com',
        url: '/',
        imageUrl: null,
        category: PluginCategory.entertainment,
        tags: const ['music', 'streaming', 'audio'],
        requiresAuth: true,
      );
}
