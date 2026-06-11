import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_skill_catalog.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _MindSkillPickerPrefs {
  const _MindSkillPickerPrefs({
    required this.customSkills,
    required this.hiddenDefaultSkillsLower,
  });

  final List<String> customSkills;
  final List<String> hiddenDefaultSkillsLower;
}

Future<_MindSkillPickerPrefs> _loadMindSkillPickerPrefs(String personId) async {
  if (personId.isEmpty) {
    return const _MindSkillPickerPrefs(
      customSkills: [],
      hiddenDefaultSkillsLower: [],
    );
  }
  final prefs = await SharedPreferences.getInstance();
  return _MindSkillPickerPrefs(
    customSkills: MindSkillCatalog.dedupeNames(
      prefs.getStringList('mind_custom_skills_$personId') ?? const [],
    ),
    hiddenDefaultSkillsLower: (prefs
                .getStringList('mind_hidden_default_skills_$personId') ??
            const [])
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList(),
  );
}

/// Pick catalog skills to link to a project (same flow as project detail +).
void showProjectSkillsPicker(
  BuildContext context, {
  required ProjectProtocol project,
}) {
  final growthBlock = context.read<GrowthBlock>();
  final l10n = context.l10n;
  final projectId = project.id;
  final altProjectId = project.projectID;
  final personId =
      context.read<PersonBlock>().information.value.profiles.id ?? '';
  final existing = growthBlock
      .skillsForProject(projectId, altProjectId: altProjectId)
      .map((s) => s.skillName.toLowerCase())
      .toSet();
  final picked = <String>{};

  Future<int> attachSkills(Iterable<String> names) async {
    await growthBlock.ensurePersonSkillLibrary();
    var added = 0;
    for (final name in names) {
      if (existing.contains(name.toLowerCase())) continue;
      await growthBlock.createProjectSkill(
        projectId,
        name,
        altProjectId: altProjectId,
      );
      existing.add(name.toLowerCase());
      added++;
    }
    return added;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;

      return FutureBuilder<_MindSkillPickerPrefs>(
        future: _loadMindSkillPickerPrefs(personId),
        builder: (context, prefsSnap) {
          var customSkills = prefsSnap.data?.customSkills ?? const <String>[];
          final hiddenDefaults =
              prefsSnap.data?.hiddenDefaultSkillsLower ?? const <String>[];

          return StatefulBuilder(
            builder: (context, setSheetState) {
              final cs = Theme.of(sheetContext).colorScheme;

              List<String> visibleSkills() {
                return growthBlock.mindVisibleSkillNames(
                  customSkills: customSkills,
                  hiddenDefaultSkillsLower: hiddenDefaults,
                );
              }

              Future<void> promptCreateNewSkill() async {
                final controller = TextEditingController();
                final name = await showDialog<String>(
                  context: sheetContext,
                  useRootNavigator: true,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: Text(l10n.project_auto_add_all_skills),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: l10n.project_skill_name_hint,
                        ),
                        onSubmitted: (_) => Navigator.of(dialogContext)
                            .pop(controller.text.trim()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext)
                              .pop(controller.text.trim()),
                          child: Text(l10n.add),
                        ),
                      ],
                    );
                  },
                );
                controller.dispose();

                final normalized =
                    (name ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
                if (normalized.isEmpty) return;

                if (normalized.length > 24) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.project_skill_name_too_long),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                if (visibleSkills().any(
                  (s) => MindSkillCatalog.namesMatch(s, normalized),
                )) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.project_skill_already_exists),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                customSkills =
                    await growthBlock.appendCustomMindSkill(normalized);
                if (!existing.contains(normalized.toLowerCase())) {
                  await growthBlock.createProjectSkill(
                    projectId,
                    normalized,
                    altProjectId: altProjectId,
                  );
                  existing.add(normalized.toLowerCase());
                }
                setSheetState(() => picked.add(normalized));

                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.project_skill_added),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  color: cs.surface,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxSheetHeight),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.project_add_skill_title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.project_skill_catalog_hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: prefsSnap.connectionState ==
                                    ConnectionState.waiting
                                ? null
                                : promptCreateNewSkill,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: Text(l10n.project_auto_add_all_skills),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4,
                              left: 4,
                              right: 4,
                            ),
                            child: Text(
                              l10n.project_auto_add_all_skills_subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (prefsSnap.connectionState ==
                              ConnectionState.waiting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            Watch((context) {
                              final names = visibleSkills();
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: names.map((name) {
                                  final onProject = existing.contains(
                                    name.toLowerCase(),
                                  );
                                  final selected = picked.contains(name);
                                  return FilterChip(
                                    label: Text(name),
                                    selected: selected || onProject,
                                    onSelected: onProject
                                        ? null
                                        : (v) {
                                            setSheetState(() {
                                              if (v) {
                                                picked.add(name);
                                              } else {
                                                picked.remove(name);
                                              }
                                            });
                                          },
                                  );
                                }).toList(),
                              );
                            }),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: Text(l10n.cancel),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: picked.isEmpty
                                    ? null
                                    : () async {
                                        final added =
                                            await attachSkills(picked);
                                        setSheetState(() => picked.clear());
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                        if (context.mounted && added > 0) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n
                                                    .project_skills_added_count(
                                                  added,
                                                ),
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                child: Text(l10n.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
