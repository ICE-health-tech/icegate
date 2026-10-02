import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ice_gate/orchestration_layer/HubRegistry.dart';

/// Ensures a hub is initialized before showing [child].
class HubLoader extends StatefulWidget {
  const HubLoader({
    super.key,
    required this.hub,
    required this.child,
  });

  final String hub;
  final Widget child;

  @override
  State<HubLoader> createState() => _HubLoaderState();
}

class _HubLoaderState extends State<HubLoader> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = context.read<HubRegistry>().ensure(widget.hub);
  }

  @override
  void didUpdateWidget(covariant HubLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hub != widget.hub && mounted) {
      _ready = context.read<HubRegistry>().ensure(widget.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load hub: ${snapshot.error}'),
          );
        }
        return widget.child;
      },
    );
  }
}

/// Loads the hub for the current route before showing shell content.
class HubRouteGate extends StatelessWidget {
  const HubRouteGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hub = HubRegistry.hubForPath(GoRouterState.of(context).uri.path);
    if (hub == null) return child;
    return HubLoader(hub: hub, child: child);
  }
}
