import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
// Assuming your DAO is here and provides deleteWidget
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:flutter/services.dart';

class ConfirmDialog extends StatefulWidget {
  final ExternalWidgetsDAO dao;
  final String name;
  final String widgetID;

  const ConfirmDialog({
    super.key,
    required this.dao,
    required this.name,
    required this.widgetID,
  });

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(AppLocalizations.of(context)!.widget_delete_title),
      content: Text(
        AppLocalizations.of(context)!.widget_delete_msg(widget.name),
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: colorScheme.primary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () async {
            HapticFeedback.heavyImpact();
            await widget.dao.deleteWidget(widget.widgetID);
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
