import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummaryPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummarySuggestions.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryPayloadBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/N8nSummaryDispatch.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/ReportRecipientResolver.dart';

/// Outcome of [DailyMailSummaryAutoSend.trySendIfDue] (for UI + logs).
enum DailyMailSummarySendResult {
  skippedDisabled,
  skippedNotDue,
  skippedAlreadySent,
  skippedNoRecipient,
  success,
  failedNotConfigured,
  failedSend,
}

/// Sends the daily summary to n8n once per day after the scheduled local time.
class DailyMailSummaryAutoSend {
  /// Report window: scheduled time on day D until just before scheduled time on D+1.
  /// Opening the app the next morning still sends if yesterday was missed.
  static String reportDayKeyForNow(DateTime now, int hour, int minute) {
    final local = now.toLocal();
    final scheduledToday =
        DateTime(local.year, local.month, local.day, hour, minute);
    if (!local.isBefore(scheduledToday)) {
      return DailyMailSummaryPrefs.todayKey(local);
    }
    final yesterday = scheduledToday.subtract(const Duration(days: 1));
    return DailyMailSummaryPrefs.todayKey(yesterday);
  }

  static Future<DailyMailSummarySendResult> trySendIfDue({
    required FinanceBlock finance,
    required HealthBlock health,
    required MindBlock mind,
    required GrowthBlock growth,
    required ProjectBlock project,
    required ConfigBlock config,
    required PersonBlock person,
    required String localeCode,
  }) async {
    if (kIsWeb) return DailyMailSummarySendResult.skippedDisabled;
    if (!await DailyMailSummaryPrefs.getEnabled()) {
      return DailyMailSummarySendResult.skippedDisabled;
    }

    final now = DateTime.now().toLocal();
    final hour = await DailyMailSummaryPrefs.getHour();
    final minute = await DailyMailSummaryPrefs.getMinute();
    final reportDayKey = reportDayKeyForNow(now, hour, minute);
    if (await DailyMailSummaryPrefs.getLastSentDate() == reportDayKey) {
      return DailyMailSummarySendResult.skippedAlreadySent;
    }

    final email = await ReportRecipientResolver.resolve(person);
    if (email == null || email.isEmpty) {
      debugPrint('DailyMailSummaryAutoSend: skipped — no recipient email');
      return DailyMailSummarySendResult.skippedNoRecipient;
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
      final suggestions = await DailyMailSummarySuggestions.resolveAsync(
        l10n: l10n,
        finance: finance,
        health: health,
        mind: mind,
        growth: growth,
        localeCode: localeCode,
      );

      final payload = DailySummaryPayloadBuilder.build(
        finance: finance,
        health: health,
        mind: mind,
        growth: growth,
        project: project,
        personId: personId,
        currency: config.currency.value,
        locale: localeCode,
        recipientEmail: email,
        recipientName: ReportRecipientResolver.displayName(person),
        categoryLabels: categoryLabels,
        suggestions: suggestions.suggestions,
      );
      await N8nSummaryDispatch.send(payload);
      await DailyMailSummaryPrefs.setLastSentDate(reportDayKey);
      debugPrint('DailyMailSummaryAutoSend: sent for $reportDayKey');
      return DailyMailSummarySendResult.success;
    } on N8nSummaryDispatchException catch (e) {
      debugPrint('DailyMailSummaryAutoSend: failed — $e');
      if (e.message.contains('not configured')) {
        return DailyMailSummarySendResult.failedNotConfigured;
      }
      return DailyMailSummarySendResult.failedSend;
    } catch (e) {
      debugPrint('DailyMailSummaryAutoSend: failed — $e');
      return DailyMailSummarySendResult.failedSend;
    }
  }
}
