import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanActionStore.dart';
import 'package:provider/provider.dart';

class PlanActionDialog extends StatefulWidget {
  const PlanActionDialog({
    super.key,
    this.action,
    this.completeOnly = false,
  });

  final PlanAction? action;
  final bool completeOnly;

  static Future<bool?> show(
    BuildContext context, {
    PlanAction? action,
    bool completeOnly = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => PlanActionDialog(
        action: action,
        completeOnly: completeOnly,
      ),
    );
  }

  @override
  State<PlanActionDialog> createState() => _PlanActionDialogState();
}

class _PlanActionDialogState extends State<PlanActionDialog> {
  final _titleCtrl = TextEditingController();
  final _expectedCtrl = TextEditingController(text: '5');
  final _realCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.action;
    if (a != null) {
      _titleCtrl.text = a.title;
      _expectedCtrl.text = '${a.expectedPoints}';
      if (a.realPoints != null) _realCtrl.text = '${a.realPoints}';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _expectedCtrl.dispose();
    _realCtrl.dispose();
    super.dispose();
  }

  int? _parsePoints(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;

    final existing = widget.action;
    if (widget.completeOnly && existing != null) {
      final real = _parsePoints(_realCtrl.text);
      if (real == null) {
        _snack(l10n.plan_action_points_invalid);
        return;
      }
      await PlanActionStore.logReal(personId, existing.id, real);
    } else {
      final title = _titleCtrl.text.trim();
      if (title.isEmpty) {
        _snack(l10n.plan_action_title_required);
        return;
      }
      final expected = _parsePoints(_expectedCtrl.text);
      if (expected == null) {
        _snack(l10n.plan_action_points_invalid);
        return;
      }
      final real = _parsePoints(_realCtrl.text);

      if (existing != null) {
        await PlanActionStore.update(
          personId,
          existing.copyWith(
            title: title,
            expectedPoints: expected,
            realPoints: real,
            completedAt: real != null ? (existing.completedAt ?? DateTime.now()) : null,
            clearReal: real == null,
          ),
        );
      } else {
        await PlanActionStore.add(
          personId,
          PlanAction(
            id: IDGen.UUIDV7(),
            title: title,
            expectedPoints: expected,
            realPoints: real,
            createdAt: DateTime.now(),
            completedAt: real != null ? DateTime.now() : null,
          ),
        );
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final completeOnly = widget.completeOnly;
    final editing = widget.action != null;

    return AlertDialog(
      title: Text(
        completeOnly
            ? l10n.plan_action_log_real
            : editing
                ? l10n.plan_action_edit
                : l10n.plan_action_add,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!completeOnly) ...[
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.plan_action_title_label,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expectedCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.plan_action_expected_label,
                ),
              ),
            ] else if (widget.action != null) ...[
              Text(
                widget.action!.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.plan_action_expected_value(widget.action!.expectedPoints),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
            if (!completeOnly || completeOnly) ...[
              if (!completeOnly) const SizedBox(height: 12),
              TextField(
                controller: _realCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.plan_action_real_label,
                  hintText: completeOnly ? null : l10n.plan_action_real_hint,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.tooltip_save),
        ),
      ],
    );
  }
}
