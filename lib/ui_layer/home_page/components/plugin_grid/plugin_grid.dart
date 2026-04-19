import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/ExternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/ui_layer/home_page/components/plugin_grid/plugin_card.dart';
import 'package:ice_gate/ui_layer/home_page/components/plugin_grid/plugin_navigation_util.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/widget_page/AddPluginForm.dart';
import 'package:ice_gate/ui_layer/widget_page/ConfirmDialog.dart';

class PluginGrid extends StatefulWidget {
  final String personId;
  final bool isEditMode;

  const PluginGrid({
    super.key,
    required this.personId,
    this.isEditMode = false,
  });

  @override
  State<PluginGrid> createState() => _PluginGridState();
}

class _PluginGridState extends State<PluginGrid> {
  @override
  Widget build(BuildContext context) {
    final internalBlock = context.watch<InternalWidgetBlock>();
    final externalBlock = context.watch<ExternalWidgetBlock>();
    final internalWidgets = internalBlock.listInternalWidgetHomePage.watch(context);
    final externalWidgets = externalBlock.listExternalWidgets.watch(context);

    final l10n = AppLocalizations.of(context)!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: internalWidgets.length + externalWidgets.length + 1,
      itemBuilder: (context, index) {
        // Internal Widgets
        if (index < internalWidgets.length) {
          final widgetData = internalWidgets[index];
          return PluginCard(
            label: widgetData.name,
            imageUrl: widgetData.imageUrl,
            isEditMode: widget.isEditMode,
            onTap: () => PluginNavigationUtil.navigateInternal(context, widgetData.url),
            onDelete: () => _handleDeleteInternal(context, widgetData.name),
          );
        }

        // External Widgets
        final externalIndex = index - internalWidgets.length;
        if (externalIndex < externalWidgets.length) {
          final widgetData = externalWidgets[externalIndex];
          return PluginCard(
            label: widgetData.name ?? 'External',
            imageUrl: widgetData.imageUrl,
            isEditMode: widget.isEditMode,
            onTap: () => PluginNavigationUtil.navigateExternal(context, widgetData.url ?? ''),
            onLongPress: () => _showRenameDialog(context, widgetData),
            onDelete: () => _showDeleteDialog(
              context,
              widgetData.name ?? 'External',
              widgetData,
            ),
          );
        }

        // Add Button
        return PluginCard(
          label: l10n.add,
          onTap: () => _showAddPluginDialog(context),
          imageUrl: 'assets/internalwidget/add.png', // Fallback icon path
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String name, ExternalWidgetData? widgetData) {
    if (widgetData == null) return; // For now only handles external delete in this dialog type
    final dao = context.read<ExternalWidgetsDAO>();

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        dao: dao,
        name: name,
        widgetID: widgetData.id,
      ),
    );
  }

  void _handleDeleteInternal(BuildContext context, String? name) async {
    if (name == null) return;
    final dao = context.read<InternalWidgetsDAO>();
    final block = context.read<InternalWidgetBlock>();
    await block.deleteWidget(dao, name);
  }


  void _showRenameDialog(BuildContext context, ExternalWidgetData widgetData) {
    if (widget.isEditMode) return;
    final controller = TextEditingController(text: widgetData.name);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename"), // Fallback to string if getter missing
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.username_email_hint), // Using existing hint as fallback
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final dao = context.read<ExternalWidgetsDAO>();
                final block = context.read<ExternalWidgetBlock>();
                await block.renameWidget(dao, widgetData.id, newName);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showAddPluginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: AddPluginForm(
          data: FormData(
            title: AppLocalizations.of(context)!.add_app_plugin,
            description: AppLocalizations.of(context)!.plugin_desc,
          ),
          scope: 'home',
        ),
      ),
    );
  }
}
