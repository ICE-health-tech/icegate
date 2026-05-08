import 'package:drift/drift.dart' show Value;
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/utils/savings_streak.dart';

/// Stable English titles for de-duplication (also shown in Social / Achievements).
abstract final class SavingsAwardTitles {
  static const firstSave = 'First Brick Laid';
  static const threeStreak = 'Three in a Row';
  static const sevenStreak = 'Iron Will Week';
  static const thirtyStreak = 'Compounding Mind';
  static const hundred = 'First Hundred';
  static const thousand = 'Four Figures';
  static const impulseTen = 'Master of Urges';
}

String? _moodLabel(int? mood) {
  if (mood == null || mood < 1 || mood > 5) return null;
  const labels = ['Awful', 'Bad', 'Meh', 'Good', 'Rad'];
  return labels[mood - 1];
}

Future<Set<String>> _existingFinanceTitles(
  AppDatabase db,
  String personId,
) async {
  final rows = await (db.select(db.achievementsTable)
        ..where((t) => t.personID.equals(personId)))
      .get();
  return rows
      .where((r) => r.domain == 'finance')
      .map((r) => r.title)
      .toSet();
}

/// After a new savings row is committed and [transactions] is refreshed, insert
/// any newly earned finance achievements. Returns newly created titles for UI.
Future<List<String>> checkAndInsertSavingsAwards({
  required AppDatabase database,
  required String personId,
  required List<TransactionData> transactions,
  required AppLocalizations l10n,
  int? moodJustSaved,
}) async {
  if (personId.isEmpty) return [];

  final savings =
      transactions.where((t) => t.type == 'savings').toList();
  final streak = computeSavingsStreak(transactions);
  final totalSaved = savings.fold<double>(
    0,
    (s, t) => s + t.amount,
  );
  final impulseCount = savings
      .where((t) => t.category == 'impulse')
      .length;

  final earned = await _existingFinanceTitles(database, personId);
  final dao = database.achievementsDAO;
  final newly = <String>[];

  Future<void> unlock({
    required String titleKey,
    required String titleDisplay,
    required String description,
    required int impact,
    required String how,
  }) async {
    if (earned.contains(titleKey)) return;
    await dao.insertAchievement(
      AchievementsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        tenantID: Value(DEFAULT_TENANT_ID),
        personID: Value(personId),
        title: titleKey,
        description: Value(description),
        domain: const Value('finance'),
        meaningScore: const Value(6),
        impactScore: impact,
        moodPost: moodJustSaved != null
            ? Value(_moodLabel(moodJustSaved))
            : const Value.absent(),
        impactDescWho: 'You',
        impactDescHow: how,
      ),
    );
    earned.add(titleKey);
    newly.add(titleDisplay);
  }

  if (savings.isNotEmpty) {
    await unlock(
      titleKey: SavingsAwardTitles.firstSave,
      titleDisplay: l10n.finance_award_first_save_title,
      description: l10n.finance_award_first_save_desc,
      impact: 4,
      how: 'Logged first savings entry.',
    );
  }

  if (streak.current >= 3) {
    await unlock(
      titleKey: SavingsAwardTitles.threeStreak,
      titleDisplay: l10n.finance_award_three_streak_title,
      description: l10n.finance_award_three_streak_desc,
      impact: 5,
      how: '${streak.current}-day streak.',
    );
  }

  if (streak.current >= 7) {
    await unlock(
      titleKey: SavingsAwardTitles.sevenStreak,
      titleDisplay: l10n.finance_award_seven_streak_title,
      description: l10n.finance_award_seven_streak_desc,
      impact: 7,
      how: '${streak.current}-day streak.',
    );
  }

  if (streak.current >= 30) {
    await unlock(
      titleKey: SavingsAwardTitles.thirtyStreak,
      titleDisplay: l10n.finance_award_thirty_streak_title,
      description: l10n.finance_award_thirty_streak_desc,
      impact: 9,
      how: '${streak.current}-day streak.',
    );
  }

  if (totalSaved >= 100) {
    await unlock(
      titleKey: SavingsAwardTitles.hundred,
      titleDisplay: l10n.finance_award_hundred_title,
      description: l10n.finance_award_hundred_desc,
      impact: 5,
      how: 'Lifetime savings crossed 100 (base units).',
    );
  }

  if (totalSaved >= 1000) {
    await unlock(
      titleKey: SavingsAwardTitles.thousand,
      titleDisplay: l10n.finance_award_thousand_title,
      description: l10n.finance_award_thousand_desc,
      impact: 8,
      how: 'Lifetime savings crossed 1000 (base units).',
    );
  }

  if (impulseCount >= 10) {
    await unlock(
      titleKey: SavingsAwardTitles.impulseTen,
      titleDisplay: l10n.finance_award_impulse_ten_title,
      description: l10n.finance_award_impulse_ten_desc,
      impact: 7,
      how: '$impulseCount impulse-win savings logged.',
    );
  }

  return newly;
}
