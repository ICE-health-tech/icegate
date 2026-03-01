import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
// import 'package:ice_shield/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/InternalWidgetProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_shield/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';
import 'package:provider/provider.dart';

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
        final url = _urlController.text.trim(); // e.g., /project/123
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
          url: url.isNotEmpty ? url : '/project/$projectId',
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
          await projectNoteDAO.insertNote(
            title: noteTitle,
            content: jsonEncode({'content': 'Initial note for $name'}),
            projectID: projectId,
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
            const SnackBar(
              content: Text('Project created with all components!'),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error creating project: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating project: $e'),
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
                  'Create Project Widget',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _spendingController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Investment',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Internal Path (Optional)',
                    hintText: '/project/custom-path',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _handleSubmit,
                      child: const Text('Create'),
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
