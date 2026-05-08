import 'dart:async' show unawaited;

import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/utils/savings_awards.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/finance_currency_toggle.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/savings_celebration.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/transaction_builder_dialog.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _ReasonChoice {
  final String id;
  final String label;
  final String description;
  final String category;
  final String Function(AppLocalizations l10n) affirm;

  const _ReasonChoice({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    required this.affirm,
  });
}

/// Fast savings log: amount, optional mood, smart chips, optional custom text.
class QuickSaveSheet extends StatefulWidget {
  final FinanceBlock financeBlock;

  const QuickSaveSheet({super.key, required this.financeBlock});

  static Future<void> show(BuildContext context, FinanceBlock block) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickSaveSheet(financeBlock: block),
    );
  }

  @override
  State<QuickSaveSheet> createState() => _QuickSaveSheetState();
}

class _QuickSaveSheetState extends State<QuickSaveSheet> {
  final _amount = TextEditingController();
  final _customNote = TextEditingController();
  int? _mood;
  int? _lastMindMood;
  _ReasonChoice? _selected;
  bool _customMode = false;
  bool _loadingMood = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadLastMindMood());
      }
    });
  }

  Future<void> _loadLastMindMood() async {
    final db = context.read<AppDatabase>();
    final pid = widget.financeBlock.personId;
    if (pid.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingMood = false;
        });
      }
      return;
    }
    final rows = await (db.select(db.mindLogsTable)
          ..where((t) => t.personID.equals(pid))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _lastMindMood = rows.first.moodScore;
        _loadingMood = false;
      });
    } else if (mounted) {
      setState(() {
        _loadingMood = false;
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _customNote.dispose();
    super.dispose();
  }

  List<_ReasonChoice> _starters(AppLocalizations l10n) {
    return [
      _ReasonChoice(
        id: 'impulse',
        label: l10n.finance_quick_chip_impulse,
        description: l10n.finance_quick_desc_impulse,
        category: 'impulse',
        affirm: (l) => l.finance_quick_affirm_impulse,
      ),
      _ReasonChoice(
        id: 'coffee',
        label: l10n.finance_quick_chip_coffee,
        description: l10n.finance_quick_desc_coffee,
        category: 'impulse',
        affirm: (l) => l.finance_quick_affirm_coffee,
      ),
      _ReasonChoice(
        id: 'shopping',
        label: l10n.finance_quick_chip_shopping,
        description: l10n.finance_quick_desc_shopping,
        category: 'impulse',
        affirm: (l) => l.finance_quick_affirm_shopping,
      ),
      _ReasonChoice(
        id: 'sale',
        label: l10n.finance_quick_chip_sale,
        description: l10n.finance_quick_desc_sale,
        category: 'impulse',
        affirm: (l) => l.finance_quick_affirm_sale,
      ),
      _ReasonChoice(
        id: 'goal',
        label: l10n.finance_quick_chip_goal,
        description: l10n.finance_quick_desc_goal,
        category: 'goal',
        affirm: (l) => l.finance_quick_affirm_goal,
      ),
      _ReasonChoice(
        id: 'emergency',
        label: l10n.finance_quick_chip_emergency,
        description: l10n.finance_quick_desc_emergency,
        category: 'emergency',
        affirm: (l) => l.finance_quick_affirm_emergency,
      ),
    ];
  }

  List<_ReasonChoice> _mruFromTxns(
    AppLocalizations l10n,
    List<TransactionData> txns,
  ) {
    final seen = <String>{};
    final out = <_ReasonChoice>[];
    for (final t in txns) {
      if (t.type != 'savings') continue;
      final d = t.description?.trim();
      if (d == null || d.isEmpty) continue;
      final key = d.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(
        _ReasonChoice(
          id: 'mru_${out.length}_$key',
          label: d.length > 28 ? '${d.substring(0, 25)}…' : d,
          description: d,
          category: t.category,
          affirm: (l) => l.finance_quick_affirm_default,
        ),
      );
      if (out.length >= 4) break;
    }
    return out;
  }

  List<_ReasonChoice> _orderedChips(AppLocalizations l10n) {
    final tx = widget.financeBlock.transactions.value;
    final mru = _mruFromTxns(l10n, tx);
    var starters = _starters(l10n);
    final m = _lastMindMood;
    if (m != null) {
      if (m <= 2) {
        const order = ['impulse', 'coffee', 'shopping', 'sale', 'goal', 'emergency'];
        starters = order
            .map((id) => starters.firstWhere((s) => s.id == id))
            .toList();
      } else if (m >= 4) {
        const order = ['goal', 'emergency', 'impulse', 'coffee', 'shopping', 'sale'];
        starters = order
            .map((id) => starters.firstWhere((s) => s.id == id))
            .toList();
      }
    }
    final mruDesc = mru.map((e) => e.description.toLowerCase()).toSet();
    starters = starters
        .where(
          (s) => !mruDesc.contains(s.description.toLowerCase()),
        )
        .toList();
    final merged = <_ReasonChoice>[...mru, ...starters];
    if (merged.length > 8) {
      return merged.sublist(0, 8);
    }
    return merged;
  }

  bool get _canSave {
    final raw = double.tryParse(
      _amount.text.replaceFirst(',', '.'),
    );
    if (raw == null || raw <= 0) return false;
    if (_customMode) {
      return _customNote.text.trim().isNotEmpty;
    }
    return _selected != null;
  }

  Future<void> _onSave() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    final raw = double.tryParse(
      _amount.text.replaceFirst(',', '.'),
    )!;
    final base = widget.financeBlock.convertToBase(raw);
    String category;
    String description;
    String affirm;
    if (_customMode) {
      category = 'general';
      description = _customNote.text.trim();
      affirm = l10n.finance_quick_affirm_default;
    } else {
      final sel = _selected!;
      category = sel.category;
      description = sel.description;
      affirm = sel.affirm(l10n);
    }

    final mindBlock = context.read<MindBlock>();
    final appDb = context.read<AppDatabase>();
    await widget.financeBlock.addTransaction(
      category: category,
      type: 'savings',
      amount: base,
      description: description,
      moodScore: _mood,
    );

    if (_mood != null) {
      try {
        await mindBlock.addMindLog(
          moodScore: _mood!,
          activities: [l10n.finance_type_savings, description],
          note: description,
          personId: widget.financeBlock.personId,
          tenantId: null,
        );
      } catch (e) {
        debugPrint('QuickSaveSheet: mind log $e');
      }
    }

    if (!mounted) return;
    HapticFeedback.heavyImpact();
    showSavingsCelebration(
      context,
      body: affirm,
    );

    await widget.financeBlock.refreshFromLocalDatabase();
    if (!mounted) return;

    final awards = await checkAndInsertSavingsAwards(
      database: appDb,
      personId: widget.financeBlock.personId,
      transactions: widget.financeBlock.transactions.value,
      l10n: l10n,
      moodJustSaved: _mood,
    );
    if (!mounted) return;
    for (final t in awards) {
      showSavingsCelebration(
        context,
        bannerTitle: l10n.finance_award_unlocked,
        body: t,
        duration: const Duration(milliseconds: 2200),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      if (!mounted) return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final chips = _orderedChips(l10n);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.finance_quick_save_title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.finance_quick_save_subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.finance_quick_mood_prompt,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final score = i + 1;
                  final on = _mood == score;
                  const emojis = ['😖', '😕', '😐', '🙂', '😄'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _mood = score),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: on
                                ? EntryColors.financeYellow.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: on
                                  ? EntryColors.financeYellow.withValues(alpha: 0.6)
                                  : Colors.white12,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                emojis[i],
                                style: const TextStyle(fontSize: 22),
                              ),
                              Text(
                                '$score',
                                style: TextStyle(
                                  color: on
                                      ? EntryColors.financeYellow
                                      : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_loadingMood) const SizedBox.shrink(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FinanceInlineCurrencyToggle(
                  financeBlock: widget.financeBlock,
                  onTap: () => toggleFinanceCurrencyWithAmountField(
                    financeBlock: widget.financeBlock,
                    amountController: _amount,
                    setState: setState,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Watch((context) {
                final useVnd = widget.financeBlock.useVnd.value;
                return TextField(
                  controller: _amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'JetBrainsMono',
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
                      fontSize: 28,
                    ),
                    prefixText: !useVnd ? '\$ ' : null,
                    suffixText: useVnd ? ' ₫' : null,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                );
              }),
              const SizedBox(height: 12),
              Text(
                _customMode
                    ? l10n.finance_quick_note_label
                    : l10n.finance_quick_why_label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (_customMode)
                TextField(
                  controller: _customNote,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.finance_quick_note_label,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...chips.map((c) {
                      final sel = _selected?.id == c.id;
                      return FilterChip(
                        label: Text(
                          c.label,
                          style: TextStyle(
                            color: sel ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) {
                          setState(() {
                            _selected = c;
                            _customMode = false;
                          });
                        },
                        selectedColor: EntryColors.financeYellow,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        checkmarkColor: Colors.black,
                      );
                    }),
                    FilterChip(
                      label: Text(
                        l10n.finance_quick_chip_custom,
                        style: TextStyle(
                          color: _customMode ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: _customMode,
                      onSelected: (_) {
                        setState(() {
                          _customMode = true;
                          _selected = null;
                        });
                      },
                      selectedColor: EntryColors.iceCyan,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      avatar: Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: _customMode ? Colors.black : Colors.white54,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      TransactionBuilderDialog.show(
                        context,
                        preferredType: 'savings',
                        financeBlock: widget.financeBlock,
                      );
                    },
                    child: Text(l10n.finance_quick_full_form),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canSave ? _onSave : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: EntryColors.financeYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      l10n.finance_quick_log,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
