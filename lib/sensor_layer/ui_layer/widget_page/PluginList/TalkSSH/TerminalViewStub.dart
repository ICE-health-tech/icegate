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
    return const Center(child: Text('Terminal not supported on this platform'));
  }
}
