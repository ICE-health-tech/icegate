import 'package:flutter/material.dart';

class TerminalViewNative extends StatelessWidget {
  final dynamic terminal;
  final dynamic controller;
  final bool autofocus;

  const TerminalViewNative(
    this.terminal, {
    super.key,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: const Center(
        child: Text(
          'Terminal View (Web Compatibility Mode)\nSSH is not fully supported in browser environments without a WebSocket proxy.',
          style: TextStyle(color: Colors.greenAccent, fontFamily: 'Courier'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
