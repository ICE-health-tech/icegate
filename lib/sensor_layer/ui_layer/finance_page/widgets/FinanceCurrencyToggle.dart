import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return GestureDetector(
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: FinanceSurface.panel(
            Theme.of(context).colorScheme,
            isDark: isDark,
            radius: 18,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pill('USD', !useVnd, isDark: isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 12,
                  color: FinanceSurface.mutedInk(isDark: isDark),
                ),
              ),
              _pill('VND', useVnd, isDark: isDark),
            ],
          ),
        ),
      );
    });
  }

  static Widget _pill(String label, bool active, {required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FinanceSurface.currencyPillBackground(
          isDark: isDark,
          active: active,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 9,
          color: FinanceSurface.currencyPillForeground(
            isDark: isDark,
            active: active,
          ),
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
