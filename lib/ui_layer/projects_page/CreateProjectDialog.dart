import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
// import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/utils/l10n_extensions.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _spendingController = TextEditingController();
  final _urlController = TextEditingController(); // For the internal widget URL
  final _taskTitleController = TextEditingController();
  final _noteTitleController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _spendingController.dispose();
    _urlController.dispose();
    _taskTitleController.dispose();
    _noteTitleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final internalWidgetsDAO = context.read<InternalWidgetsDAO>();
        // final externalWidgetsDAO = context.read<ExternalWidgetsDAO>();
        final projectBlock = context.read<ProjectBlock>();
        final growthBlock = context.read<GrowthBlock>();
        final projectNoteDAO = context.read<ProjectNoteDAO>();
        final widgetManager = context.read<WidgetManagerBlock>();

        final name = _nameController.text.trim();
        final description = _descriptionController.text.trim();
        final spendingText = _spendingController.text.trim();
        final url = _urlController.text.trim(); // e.g., /projects/123
        final taskTitle = _taskTitleController.text.trim();
        final noteTitle = _noteTitleController.text.trim();

        final widgetID = IDGen.UUIDV7();
        // 1. Force it to UTC before converting
        final dateAdded = DateTime.now().toUtc().toIso8601String();

        // Result: "2026-02-25T13:53:14.123Z"
        // print("date time: " + dateAdded);

        // 0. Create Project Entity
        final projectId = await projectBlock.createProject(
          name,
          description,
          null,
        );

        // 1. Create InternalWidgetProtocol
        final internalWidget = InternalWidgetProtocol(
          name: name,
          url: url.isNotEmpty ? url : '/projects/$projectId',
          alias: name.toLowerCase().replaceAll(' ', '_'),
          widgetID: widgetID,
          dateAdded: dateAdded,
          description: description,
          category: PluginCategory.productivity,
          icon: Icons.folder, // Default icon for projects
          protocol: 'internal',
          host: 'app',
        );

        // Save Internal Widget
        await internalWidgetsDAO.insertInternalWidget(
          id: widgetID,
          widgetID: widgetID,
          personID:
              context.read<PersonBlock>().information.value.profiles.id ?? "",
          name: internalWidget.name,
          alias: internalWidget.alias,
          url: internalWidget.url,
          imageUrl: internalWidget.imageUrl,
        );

        // Add to Canvas Dashboard (find first empty slot)
        final widgetList = widgetManager.widgets.value;
        final emptyIndex = widgetList.indexWhere((w) => w.isEmpty);
        if (emptyIndex != -1) {
          widgetManager.addWidget(
            emptyIndex,
            InternalWidgetDragProtocol.item(
              name: name,
              url: internalWidget.url,
              imageUrl: internalWidget.imageUrl ?? '',
              alias: 'project_folder',
              dateAdded: dateAdded,
              widgetID: widgetID,
              score: 0,
              isTarget: false,
              isStay: false,
            ),
          );
        }

        // 2. Create ExternalWidgetProtocol (Shortcut) - REMOVED per user request
        // final externalWidget = ExternalWidgetProtocol(
        //   name: name,
        //   protocol: 'internal',
        //   host: 'app',
        //   url: internalWidget.url,
        //   alias: internalWidget.alias,
        //   dateAdded: dateAdded,
        //   imageUrl: null, // Or a default project icon URL
        // );

        // Save External Widget
        // await externalWidgetsDAO.insertNewWidget(
        //   externalWidgetProtocol: externalWidget,
        // );

        // 3. Create Task if provided
        if (taskTitle.isNotEmpty) {
          await growthBlock.createNewTask(
            taskTitle,
            "Initial task for $name",
            projectID: projectId,
          );
        }

        // 4. Create Note if provided
        if (noteTitle.isNotEmpty) {
          final personBlock = context.read<PersonBlock>();
          await projectNoteDAO.insertNote(
            title: noteTitle,
            content: jsonEncode({'content': 'Initial note for $name'}),
            projectID: projectId,
            personID: personBlock.currentPersonID.value,
          );
        }

        // 5. Create initial transaction if spending provided
        if (spendingText.isNotEmpty) {
          final amount = double.tryParse(spendingText);
          if (amount != null && amount > 0) {
            final financeBlock = context.read<FinanceBlock>();
            await financeBlock.addTransaction(
              category: 'investing',
              type: 'investment',
              amount: amount,
              description: "Initial investment for $name",
              projectID: projectId,
            );
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.project_created_msg),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error creating project: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.project_create_failed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.create_project_title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.project_name_label,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.project_name_required;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: context.l10n.description,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _spendingController,
                  decoration: InputDecoration(
                    labelText: context.l10n.project_initial_investment_label,
                    border: const OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: context.l10n.project_internal_path_label,
                    hintText: '/projects/custom-path',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: Text(context.l10n.create),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
