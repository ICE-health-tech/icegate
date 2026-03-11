import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class TerminalViewNative extends StatelessWidget {
  final Terminal terminal;
  final TerminalController? controller;
  final bool autofocus;

  const TerminalViewNative(
    this.terminal, {
    super.key,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TerminalView(
      terminal,
      controller: controller,
      autofocus: autofocus,
    );
  }
}
