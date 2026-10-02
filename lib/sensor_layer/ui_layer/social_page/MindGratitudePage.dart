import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindGratitudePanel.dart';

class MindGratitudePage extends StatelessWidget {
  const MindGratitudePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_rounded,
              color: MindGratitudePanel.flagColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(l10n.mind_insights_open_gratitude),
          ],
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: MindGratitudePanel(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => MindGratitudePanel.showAddDialog(context),
        icon: const Icon(Icons.flag_rounded),
        label: Text(l10n.gratitude_add_title),
      ),
    );
  }
}
