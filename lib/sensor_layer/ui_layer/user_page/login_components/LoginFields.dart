import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

/// A premium, high-fidelity input field with focus glow and glassmorphism.
class ModernAuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const ModernAuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  State<ModernAuthField> createState() => _ModernAuthFieldState();
}

class _ModernAuthFieldState extends State<ModernAuthField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: EntryColors.iceCyan.withValues(alpha: 0.42),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              color: Color(0xFFF2F8FF),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: widget.hint.toUpperCase(),
              hintStyle: TextStyle(
                color: const Color(0xFFB8D4EA).withValues(
                  alpha: _isFocused ? 0.82 : 0.68,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: _isFocused
                      ? EntryColors.iceCyan
                      : const Color(0xFFE8F4FC).withValues(alpha: 0.88),
                ),
              ),
              filled: true,
              fillColor: _isFocused
                  ? const Color(0xFF030814).withValues(alpha: 0.92)
                  : const Color(0xFF050C18).withValues(alpha: 0.88),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1.25,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.32),
                  width: 1.25,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: EntryColors.iceCyan,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
