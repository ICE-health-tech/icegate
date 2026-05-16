import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

/// Compact USD | VND pill used above amount fields (transaction dialog, subscription sheet, etc.).
class FinanceInlineCurrencyToggle extends StatelessWidget {
  final FinanceBlock financeBlock;
  final Future<void> Function() onTap;

  const FinanceInlineCurrencyToggle({
    super.key,
    required this.financeBlock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final useVnd = financeBlock.useVnd.value;
      const accent = EntryColors.financeSilverAccent;
      return GestureDetector(
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pill('USD', !useVnd, accent),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 12,
                  color: accent.withValues(alpha: 0.55),
                ),
              ),
              _pill('VND', useVnd, accent),
            ],
          ),
        ),
      );
    });
  }

  static Widget _pill(String label, bool active, Color accent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 9,
          color: active ? Colors.black : accent.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Converts the amount field from the old display currency to the new one after [FinanceBlock.toggleCurrency].
Future<void> toggleFinanceCurrencyWithAmountField({
  required FinanceBlock financeBlock,
  required TextEditingController amountController,
  required void Function(void Function()) setState,
}) async {
  final parsed =
      double.tryParse(amountController.text.replaceFirst(',', '.'));
  double? baseAmount;
  if (parsed != null && parsed > 0) {
    baseAmount = financeBlock.convertToBase(parsed);
  }
  await HapticFeedback.mediumImpact();
  await financeBlock.toggleCurrency();
  setState(() {
    if (baseAmount != null) {
      final display = financeBlock.convertToDisplay(baseAmount);
      amountController.text = financeBlock.useVnd.peek()
          ? display.toStringAsFixed(0)
          : display.toStringAsFixed(2);
    }
  });
}
