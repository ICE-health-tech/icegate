import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/SavingsCelebration.dart';

/// Full-screen celebration when focus todos unlock mood +6.
void showMindFocusMoodCelebration(
  BuildContext context, {
  required String body,
}) {
  HapticFeedback.heavyImpact();
  showSavingsCelebration(
    context,
    bannerTitle: 'MOOD +6',
    body: body,
    duration: const Duration(milliseconds: 2400),
  );
}
