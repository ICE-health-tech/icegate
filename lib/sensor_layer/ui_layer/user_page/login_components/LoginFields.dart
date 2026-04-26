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
                  color: EntryColors.iceCyan.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              color: Color(0xFFE5E5EA),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: widget.hint.toUpperCase(),
              hintStyle: TextStyle(
                color: const Color(0xFFE5E5EA).withValues(alpha: _isFocused ? 0.6 : 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
              prefixIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: _isFocused 
                    ? EntryColors.iceCyan 
                    : EntryColors.arcticSilver.withValues(alpha: 0.8),
                ),
              ),
              filled: true,
              fillColor: _isFocused 
                ? Colors.black.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: EntryColors.iceCyan,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
