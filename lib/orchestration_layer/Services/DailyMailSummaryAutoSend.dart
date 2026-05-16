import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DailyMailSummaryPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/DailySummaryPayloadBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/N8nSummaryDispatch.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/orchestration_layer/Services/ReportRecipientResolver.dart';

/// Sends the daily summary to n8n once per day after the scheduled local time.
class DailyMailSummaryAutoSend {
  static Future<bool> trySendIfDue({
    required FinanceBlock finance,
    required HealthBlock health,
    required ConfigBlock config,
    required PersonBlock person,
    required String localeCode,
  }) async {
    if (kIsWeb) return false;
    if (!await DailyMailSummaryPrefs.getEnabled()) return false;

    final now = DateTime.now().toLocal();
    final hour = await DailyMailSummaryPrefs.getHour();
    final minute = await DailyMailSummaryPrefs.getMinute();
    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isBefore(scheduled)) return false;

    final today = DailyMailSummaryPrefs.todayKey(now);
    if (await DailyMailSummaryPrefs.getLastSentDate() == today) return false;

    final email = await ReportRecipientResolver.resolve(person);
    if (email == null || email.isEmpty) {
      debugPrint('DailyMailSummaryAutoSend: skipped — no recipient email');
      return false;
    }

    final personId = person.currentPersonID.value ?? '';
    final l10n = lookupAppLocalizations(Locale(localeCode));
    final categoryLabels = <String, String>{};
    for (final t in finance.transactions.value) {
      categoryLabels.putIfAbsent(
        t.category,
        () => FinancePage.getCategoryName(l10n, t.category),
      );
    }

    try {
      final payload = DailySummaryPayloadBuilder.build(
        finance: finance,
        health: health,
        personId: personId,
        currency: config.currency.value,
        locale: localeCode,
        recipientEmail: email,
        categoryLabels: categoryLabels,
      );
      await N8nSummaryDispatch.send(payload);
      await DailyMailSummaryPrefs.setLastSentDate(today);
      debugPrint('DailyMailSummaryAutoSend: sent for $today');
      return true;
    } catch (e) {
      debugPrint('DailyMailSummaryAutoSend: failed — $e');
      return false;
    }
  }

}
