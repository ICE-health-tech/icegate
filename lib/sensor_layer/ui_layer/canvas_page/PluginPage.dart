import 'package:flutter/material.dart';

class PluginPage extends StatelessWidget {
  const PluginPage({super.key});

  static Widget icon() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: Icon(
            Icons.snowing,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const PluginPage()));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Text(
          'Plugin Page',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
