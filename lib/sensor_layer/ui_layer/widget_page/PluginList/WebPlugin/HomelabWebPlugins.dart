import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';

/// Homelab / dev infra web plugins (OPNsense, cloud consoles, n8n).
class HomelabWebPlugin extends BasePluginProtocol {
  const HomelabWebPlugin({
    required super.name,
    required super.description,
    required super.icon,
    required super.protocol,
    required super.host,
    required super.url,
    super.category = PluginCategory.development,
    super.tags = const ['homelab', 'dev'],
  });
}

abstract final class HomelabWebPlugins {
  static const opnsense = HomelabWebPlugin(
    name: 'OPNsense',
    description: 'Firewall & routing dashboard',
    icon: Icons.router_rounded,
    protocol: 'https',
    host: '192.168.1.1',
    url: '/',
  );

  static const supabase = HomelabWebPlugin(
    name: 'Supabase',
    description: 'Database & auth console',
    icon: Icons.storage_rounded,
    protocol: 'https',
    host: 'supabase.com',
    url: '/dashboard',
  );

  static const northflank = HomelabWebPlugin(
    name: 'Northflank',
    description: 'Container deployment console',
    icon: Icons.cloud_rounded,
    protocol: 'https',
    host: 'app.northflank.com',
    url: '/',
  );

  static const n8n = HomelabWebPlugin(
    name: 'n8n',
    description: 'Workflow automation',
    icon: Icons.hub_outlined,
    protocol: 'https',
    host: 'n8n.io',
    url: '/',
    tags: ['homelab', 'dev', 'automation'],
  );

  static const List<BasePluginProtocol> catalog = [
    opnsense,
    supabase,
    northflank,
    n8n,
  ];
}
