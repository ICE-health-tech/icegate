import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanActionStore.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/PlanActionDialog.dart';
import 'package:intl/intl.dart';

class PlanActionTabPanel extends StatefulWidget {
  const PlanActionTabPanel({super.key, required this.personId});

  final String personId;

  @override
  State<PlanActionTabPanel> createState() => _PlanActionTabPanelState();
}

class _PlanActionTabPanelState extends State<PlanActionTabPanel> {
  List<PlanAction> _actions = [];
  DateTime? _monthFilter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(PlanActionTabPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personId != widget.personId) _reload();
  }

  Future<void> _reload() async {
    final items = await PlanActionStore.all(widget.personId);
    if (!mounted) return;
    setState(() {
      _actions = items;
      _loading = false;
    });
  }

  List<PlanAction> get _filtered {
    if (_monthFilter == null) return _actions;
    final m = _monthFilter!;
    return _actions.where((a) {
      final d = a.createdAt.toLocal();
      return d.year == m.year && d.month == m.month;
    }).toList();
  }

  List<DateTime> _recentMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - i));
  }

  Future<void> _openDialog({PlanAction? action, bool completeOnly = false}) async {
    final changed = await PlanActionDialog.show(
      context,
      action: action,
      completeOnly: completeOnly,
    );
    if (changed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final pending = filtered.where((a) => !a.isDone).toList();
    final done = filtered.where((a) => a.isDone).toList();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_actions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, size: 48, color: cs.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                l10n.plan_action_empty,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 12,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _Filters(
                month: _monthFilter,
                months: _recentMonths(),
                onMonthChanged: (m) => setState(() => _monthFilter = m),
              )),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                  child: Text(
                    l10n.plan_action_month_summary(filtered.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 2),
                  child: Text(
                    l10n.plan_action_timeline.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final action = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
                      child: _ActionCard(
                        action: action,
                        onTap: () => _openDialog(action: action),
                        onLogReal: action.isDone
                            ? null
                            : () => _openDialog(action: action, completeOnly: true),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
        Expanded(
          flex: 10,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.4),
              border: Border(
                left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                Text(
                  l10n.plan_action_scoreboard.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _ScoreTile(
                  label: l10n.plan_action_total_expected,
                  value: _sumExpected(done),
                  color: cs.primary,
                ),
                const SizedBox(height: 8),
                _ScoreTile(
                  label: l10n.plan_action_total_real,
                  value: _sumReal(done),
                  color: Colors.greenAccent,
                ),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ScoreTile(
                    label: l10n.plan_action_delta,
                    value: _sumReal(done) - _sumExpected(done),
                    color: _deltaColor(_sumReal(done) - _sumExpected(done), cs),
                    signed: true,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  l10n.plan_action_pending.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (pending.isEmpty)
                  Text(
                    l10n.plan_action_no_pending,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  )
                else
                  ...pending.map(
                    (a) => _PendingTile(
                      action: a,
                      onLog: () => _openDialog(action: a, completeOnly: true),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _sumExpected(List<PlanAction> items) =>
      items.fold(0, (s, a) => s + a.expectedPoints);

  int _sumReal(List<PlanAction> items) =>
      items.fold(0, (s, a) => s + (a.realPoints ?? 0));

  Color _deltaColor(int delta, ColorScheme cs) {
    if (delta > 0) return Colors.greenAccent;
    if (delta < 0) return cs.error;
    return cs.onSurfaceVariant;
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.month,
    required this.months,
    required this.onMonthChanged,
  });

  final DateTime? month;
  final List<DateTime> months;
  final ValueChanged<DateTime?> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.achievement_filter_label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.achievement_filter_all_months),
                  selected: month == null,
                  onSelected: (_) => onMonthChanged(null),
                ),
                ...months.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(DateFormat.yMMM().format(m)),
                      selected: month != null &&
                          month!.year == m.year &&
                          month!.month == m.month,
                      onSelected: (_) => onMonthChanged(m),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onTap,
    this.onLogReal,
  });

  final PlanAction action;
  final VoidCallback onTap;
  final VoidCallback? onLogReal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final when = DateFormat.MMMd().add_Hm().format(action.createdAt.toLocal());
    final done = action.isDone;
    final delta = action.delta;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    done ? Icons.check_circle_outline : Icons.flag_outlined,
                    size: 16,
                    color: done ? Colors.greenAccent : cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      when,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                  if (!done && onLogReal != null)
                    TextButton(
                      onPressed: onLogReal,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.plan_action_log_real),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                action.title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pointChip(
                    l10n.plan_action_expected_short,
                    action.expectedPoints,
                    cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _pointChip(
                    l10n.plan_action_real_short,
                    action.realPoints,
                    done ? Colors.greenAccent : cs.onSurfaceVariant,
                    pending: !done,
                  ),
                  if (delta != null) ...[
                    const Spacer(),
                    Text(
                      l10n.plan_action_delta_value(delta),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: delta >= 0 ? Colors.greenAccent : cs.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pointChip(String label, int? value, Color color, {bool pending = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${pending ? '—' : value}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.label,
    required this.value,
    required this.color,
    this.signed = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final text = signed && value > 0 ? '+$value' : '$value';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.action, required this.onLog});

  final PlanAction action;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(action.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l10n.plan_action_expected_value(action.expectedPoints)),
      trailing: IconButton(
        icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
        tooltip: l10n.plan_action_log_real,
        onPressed: onLog,
      ),
    );
  }
}
