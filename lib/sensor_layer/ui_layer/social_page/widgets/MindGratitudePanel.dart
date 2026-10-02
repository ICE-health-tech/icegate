import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindLogEntryDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/utils/facebook_profile_link.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gratitude journal — same card grid pattern as [SocialNotesDashboard].
class MindGratitudePanel extends StatelessWidget {
  const MindGratitudePanel({super.key});

  static const flagColor = Color(0xFFE8A317);

  static Future<void> _syncGratitude(BuildContext context) async {
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;
    await context.read<MindBlock>().syncGratitude(personId);
  }

  static Future<void> _syncGratitudeForPerson(
    BuildContext context,
    String personId,
  ) async {
    if (personId.isEmpty) return;
    await context.read<MindBlock>().syncGratitude(personId);
  }

  double _bottomClearance(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wideMac =
        defaultTargetPlatform == TargetPlatform.macOS && width >= 560;
    return wideMac ? 72 : 104;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Watch((context) {
      final personId = context.read<PersonBlock>().currentPersonID.value;
      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final gratitudeDao = context.read<AppDatabase>().gratitudeDAO;

      return _GratitudeSyncOnMount(
        personId: personId,
        child: RefreshIndicator(
          onRefresh: () => _syncGratitudeForPerson(context, personId),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
          SliverToBoxAdapter(
            child: _buildQuickEntryBar(
              context,
              colorScheme,
              textTheme,
              isDark,
              l10n,
            ),
          ),
          StreamBuilder<List<GratitudeEntryData>>(
            stream: gratitudeDao.watchForPerson(personId),
            builder: (context, gratitudeSnap) {
              if (gratitudeSnap.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('${gratitudeSnap.error}')),
                );
              }
              return StreamBuilder<List<ProjectNoteData>>(
                stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
                  personId,
                  'social',
                ),
                builder: (context, notesSnap) {
                  if (!gratitudeSnap.hasData || !notesSnap.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final people = gratitudeSnap.data!
                      .where((e) => e.kind != 'thing')
                      .toList();
                  final label = l10n.act_gratitude;
                  final gratitudeNotes = notesSnap.data!
                      .where(
                        (n) => MindActivityTokens.noteLooksLikeGratitude(
                          title: n.title,
                          content: n.content,
                          gratitudeLabel: label,
                        ),
                      )
                      .toList()
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                  return _GratitudeJournalView(
                    people: people,
                    notes: gratitudeNotes,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    l10n: l10n,
                    bottomClearance: _bottomClearance(context),
                    onEditPerson: (e) {
                      final parsed =
                          MindActivityTokens.parseEntryNote(e.note);
                      _showEntryForm(
                        context,
                        existing: _GratitudeDisplayItem(
                          id: e.id,
                          name: e.name,
                          kind: e.kind,
                          note: parsed.text,
                          tags: parsed.tags,
                          date: e.updatedAt,
                          avatarLocalPath: e.avatarLocalPath,
                          facebookUrl: e.facebookUrl,
                          canEditAvatar: true,
                          onDelete: () => gratitudeDao.deleteEntry(e.id),
                        ),
                      );
                    },
                    onEmptyAdd: () => _showAddDialog(context),
                  );
                },
              );
            },
          ),
            ],
          ),
        ),
      );
    });
  }

  List<_GratitudeDisplayItem> _mergeItems(
    List<GratitudeEntryData> entries,
    List<MindLogData> legacy,
    GratitudeDAO gratitudeDao,
    MindLogsDAO mindDao,
  ) {
    final items = <_GratitudeDisplayItem>[
      for (final e in entries)
        () {
          final parsed = MindActivityTokens.parseEntryNote(e.note);
          return _GratitudeDisplayItem(
            id: e.id,
            name: e.name,
            kind: e.kind,
            note: parsed.text,
            tags: parsed.tags,
            date: e.updatedAt,
            avatarLocalPath: e.avatarLocalPath,
            facebookUrl: e.facebookUrl,
            canEditAvatar: true,
            onDelete: () => gratitudeDao.deleteEntry(e.id),
          );
        }(),
      for (final log in legacy)
        () {
          final parsed = MindActivityTokens.parseGratitudeNote(log.note);
          return _GratitudeDisplayItem(
            id: log.id,
            name: parsed.name,
            kind: parsed.kind,
            note: parsed.text,
            date: log.createdAt,
            onDelete: () => mindDao.deleteLog(log.id),
          );
        }(),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Widget _buildQuickEntryBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: isDesktop ? 12 : 16,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 720 : double.infinity,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => MindLogEntryDialog.show(
                    context,
                    initialActivities: [
                      MindActivityTokens.gratitudeToken,
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 20,
                      vertical: isDesktop ? 10 : 12,
                    ),
                    decoration: HealthMetricColors.shellPanel(
                      colorScheme,
                      isDark: isDark,
                      radius: 30,
                      accent: flagColor,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          size: 20,
                          color: flagColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.gratitude_quick_entry_hint,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: isDesktop ? 14 : null,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _showAddDialog(context),
                icon: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: isDesktop ? 20 : 22,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: flagColor.withValues(alpha: 0.15),
                  foregroundColor: flagColor,
                ),
                tooltip: l10n.gratitude_add_title,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: flagColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_rounded, size: 72, color: flagColor),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.gratitude_empty_title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.gratitude_empty_subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.flag_rounded),
              label: Text(l10n.gratitude_add_title),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function() onDelete,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gratitude_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onDelete();
      if (context.mounted) {
        unawaited(_syncGratitude(context));
      }
    }
  }

  Future<void> _openFacebook(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.gratitude_invalid_facebook_link,
            ),
          ),
        );
      }
    }
  }

  Future<String?> _pickAndUploadAvatar(BuildContext context) async {
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return null;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return null;

    final ext = p.extension(image.path);
    return context.read<ObjectDatabaseBlock>().saveAnyLocalImage(
      image,
      customFileName: '${IDGen.UUIDV7()}${ext.isEmpty ? '.jpg' : ext}',
      subFolder: 'gratitude_avatars',
      personId: personId,
      awaitCloudSync: true,
    );
  }

  Future<void> _changeAvatarForEntry(
    BuildContext context,
    String entryId,
  ) async {
    try {
      final path = await _pickAndUploadAvatar(context);
      if (path == null || !context.mounted) return;
      await context.read<AppDatabase>().gratitudeDAO.updateAvatar(
            id: entryId,
            avatarLocalPath: path,
          );
      if (context.mounted) {
        unawaited(_syncGratitude(context));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showAvatarActions(
    BuildContext context,
    AppLocalizations l10n,
    _GratitudeDisplayItem item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l10n.gratitude_edit_title),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEntryForm(context, existing: item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.gratitude_change_photo),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeAvatarForEntry(context, item.id);
                },
              ),
              if (item.facebookUrl != null)
                ListTile(
                  leading: const Icon(Icons.facebook_rounded),
                  title: Text(l10n.gratitude_open_facebook),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFacebook(context, item.facebookUrl!);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  l10n.common_delete,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, l10n, item.onDelete);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAddDialog(BuildContext context) {
    return MindGratitudePanel()._showAddDialog(context);
  }

  /// Pick an existing gratitude flag → update photo / open Facebook / delete.
  static Future<void> showUpdateFlagPicker(BuildContext context) {
    return MindGratitudePanel()._showUpdateFlagPicker(context);
  }

  Future<void> _showUpdateFlagPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;

    final dao = context.read<AppDatabase>().gratitudeDAO;
    final picked = await showModalBottomSheet<_GratitudeDisplayItem>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.55,
            child: StreamBuilder<List<GratitudeEntryData>>(
              stream: dao.watchForPerson(personId),
              builder: (ctx, snap) {
                final entries = snap.data ?? const [];
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.gratitude_empty_subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            showAddDialog(context);
                          },
                          icon: const Icon(Icons.flag_rounded),
                          label: Text(l10n.gratitude_add_title),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  children: [
                    ListTile(
                      title: Text(
                        l10n.gratitude_update_flag,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(l10n.gratitude_pick_title),
                    ),
                    for (final e in entries)
                      ListTile(
                        leading: Icon(
                          e.kind == 'thing'
                              ? Icons.category_outlined
                              : Icons.person_outline_rounded,
                          color: flagColor,
                        ),
                        title: Text(e.name),
                        subtitle: Text(
                          e.kind == 'thing'
                              ? l10n.gratitude_kind_thing
                              : l10n.gratitude_kind_person,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          final parsed =
                              MindActivityTokens.parseEntryNote(e.note);
                          Navigator.pop(
                            ctx,
                            _GratitudeDisplayItem(
                              id: e.id,
                              name: e.name,
                              kind: e.kind,
                              note: parsed.text,
                              tags: parsed.tags,
                              date: e.updatedAt,
                              avatarLocalPath: e.avatarLocalPath,
                              facebookUrl: e.facebookUrl,
                              canEditAvatar: true,
                              onDelete: () => dao.deleteEntry(e.id),
                            ),
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.add_rounded),
                      title: Text(l10n.gratitude_add_title),
                      onTap: () {
                        Navigator.pop(ctx);
                        showAddDialog(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (picked == null || !context.mounted) return;
    await _showEntryForm(context, existing: picked);
  }

  Future<void> _showAddDialog(BuildContext context) =>
      _showEntryForm(context);

  Future<void> _showEntryForm(
    BuildContext context, {
    _GratitudeDisplayItem? existing,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    final fbController = TextEditingController(text: existing?.facebookUrl ?? '');
    var kind = existing?.kind == 'thing' ? 'thing' : 'person';
    String? avatarRelPath = existing?.avatarLocalPath;
    String? avatarAbsPath;
    String? normalizedFb = existing?.facebookUrl;
    var selectedTags = List<String>.from(existing?.tags ?? const []);
    var fbError = false;
    var pickingImage = false;
    final editing = existing != null;

    if (avatarRelPath != null && avatarRelPath.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final abs = p.isAbsolute(avatarRelPath)
          ? avatarRelPath
          : p.join(appDir.path, avatarRelPath);
      if (File(abs).existsSync()) avatarAbsPath = abs;
    }

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              void onFbChanged(String value) {
                final normalized = FacebookProfileLink.normalize(value);
                final suggest = FacebookProfileLink.suggestedName(normalized);
                setState(() {
                  normalizedFb = normalized;
                  fbError = value.trim().isNotEmpty && normalized == null;
                  if (suggest != null && nameController.text.trim().isEmpty) {
                    nameController.text = suggest;
                  }
                });
              }

              Future<void> pickAvatar() async {
                if (pickingImage) return;
                final personId =
                    context.read<PersonBlock>().currentPersonID.value;
                if (personId == null || personId.isEmpty) return;

                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (image == null) return;

                setState(() => pickingImage = true);
                try {
                  final savedPath = await context
                      .read<ObjectDatabaseBlock>()
                      .saveAnyLocalImage(
                        image,
                        customFileName:
                            '${IDGen.UUIDV7()}${p.extension(image.path).isEmpty ? '.jpg' : p.extension(image.path)}',
                        subFolder: 'gratitude_avatars',
                        personId: personId,
                        awaitCloudSync: true,
                      );
                  final appDir = await getApplicationDocumentsDirectory();
                  final abs = p.isAbsolute(savedPath)
                      ? savedPath
                      : p.join(appDir.path, savedPath);
                  if (ctx.mounted) {
                    setState(() {
                      avatarRelPath = savedPath;
                      avatarAbsPath = abs;
                    });
                  }
                } finally {
                  if (ctx.mounted) setState(() => pickingImage = false);
                }
              }

              final displayName = nameController.text.trim().isEmpty
                  ? '?'
                  : nameController.text.trim();

              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: flagColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        editing
                            ? l10n.gratitude_edit_title
                            : l10n.gratitude_add_title,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'person',
                            label: Text(l10n.gratitude_kind_person),
                            icon: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                            ),
                          ),
                          ButtonSegment(
                            value: 'thing',
                            label: Text(l10n.gratitude_kind_thing),
                            icon: const Icon(
                              Icons.category_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                        selected: {kind},
                        onSelectionChanged: (s) =>
                            setState(() => kind = s.first),
                      ),
                      if (kind == 'person') ...[
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: pickingImage ? null : pickAvatar,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                avatarAbsPath != null &&
                                        File(avatarAbsPath!).existsSync()
                                    ? CircleAvatar(
                                        radius: 36,
                                        backgroundImage:
                                            FileImage(File(avatarAbsPath!)),
                                      )
                                    : CircleAvatar(
                                        radius: 36,
                                        backgroundColor:
                                            flagColor.withValues(alpha: 0.15),
                                        child: Text(
                                          FacebookProfileLink.initials(
                                            displayName,
                                          ),
                                          style: const TextStyle(
                                            color: flagColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(ctx).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    pickingImage
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.camera_alt_rounded,
                                    size: 14,
                                    color:
                                        Theme.of(ctx).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            l10n.gratitude_pick_avatar,
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: fbController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.gratitude_facebook_link_label,
                            hintText: l10n.gratitude_facebook_link_hint,
                            prefixIcon: const Icon(Icons.facebook_rounded),
                            errorText: fbError
                                ? l10n.gratitude_invalid_facebook_link
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: onFbChanged,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        autofocus: kind != 'person',
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.gratitude_name_label,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => Navigator.pop(ctx, true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.gratitude_note_hint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.gratitude_tags_label,
                        style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in MindActivityTokens.presetTags)
                            FilterChip(
                              label: Text(
                                MindActivityTokens.tagLabel(l10n, tag),
                              ),
                              selected: selectedTags.contains(tag),
                              onSelected: (on) {
                                setState(() {
                                  if (on) {
                                    selectedTags.add(tag);
                                  } else {
                                    selectedTags.remove(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.common_cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;
                      if (kind == 'person' &&
                          fbController.text.trim().isNotEmpty &&
                          normalizedFb == null) {
                        setState(() => fbError = true);
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    child: Text(l10n.projects_calendar_save),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved != true || !context.mounted) return;

      final personId = context.read<PersonBlock>().currentPersonID.value;
      if (personId == null || personId.isEmpty) return;

      final fbText = fbController.text.trim();
      final fbUrl = kind == 'person' && fbText.isNotEmpty
          ? (normalizedFb ?? FacebookProfileLink.normalize(fbText))
          : null;
      final packedNote = MindActivityTokens.encodeEntryNote(
        text: noteController.text,
        tags: selectedTags,
      );

      final dao = context.read<AppDatabase>().gratitudeDAO;
      if (editing) {
        await dao.updateEntry(
          id: existing!.id,
          name: nameController.text.trim(),
          kind: kind,
          note: packedNote,
          facebookUrl: fbUrl,
          avatarLocalPath: avatarRelPath,
        );
      } else {
        await dao.insertEntry(
          id: IDGen.UUIDV7(),
          personId: personId,
          name: nameController.text.trim(),
          kind: kind,
          note: packedNote,
          facebookUrl: fbUrl,
          avatarLocalPath: avatarRelPath,
        );
      }
      if (context.mounted) {
        unawaited(_syncGratitude(context));
      }
    } finally {
      nameController.dispose();
      noteController.dispose();
      fbController.dispose();
    }
  }
}



class _GratitudeJournalView extends StatelessWidget {
  const _GratitudeJournalView({
    required this.people,
    required this.notes,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
    required this.bottomClearance,
    required this.onEditPerson,
    required this.onEmptyAdd,
  });

  final List<GratitudeEntryData> people;
  final List<ProjectNoteData> notes;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final double bottomClearance;
  final void Function(GratitudeEntryData person) onEditPerson;
  final VoidCallback onEmptyAdd;

  static const _accent = MindGratitudePanel.flagColor;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gratitude_section_people,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 10),
                if (people.isEmpty)
                  Text(
                    l10n.gratitude_empty_subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: people.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final person = people[index];
                        return _PersonChip(
                          person: person,
                          onTap: () => onEditPerson(person),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.act_gratitude,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (notes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_rounded, size: 56, color: _accent),
                    const SizedBox(height: 12),
                    Text(
                      l10n.gratitude_empty_title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.gratitude_empty_subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onEmptyAdd,
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(l10n.gratitude_add_title),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final cw = constraints.crossAxisExtent;
              var gap = 14.0;
              var hPad = 16.0;
              var maxTileWidth = 320.0;
              var tileHeight = 320.0;
              final useList = cw < 720;

              if (cw >= 1200) {
                maxTileWidth = 300;
                tileHeight = 320;
                hPad = 32;
              } else if (cw >= 900) {
                maxTileWidth = 300;
                tileHeight = 318;
                hPad = 28;
              } else if (cw >= 640) {
                maxTileWidth = 280;
                tileHeight = 312;
                hPad = 20;
              }

              if (useList) {
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomClearance),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < notes.length - 1 ? gap : 0,
                        ),
                        child: SocialJournalNoteCard(
                          note: notes[index],
                          layout: NoteCardLayout.list,
                        ),
                      ),
                      childCount: notes.length,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomClearance),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxTileWidth,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => SocialJournalNoteCard(
                      note: notes[index],
                    ),
                    childCount: notes.length,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.person, required this.onTap});

  final GratitudeEntryData person;
  final VoidCallback onTap;

  static const _accent = MindGratitudePanel.flagColor;

  @override
  Widget build(BuildContext context) {
    final path = person.avatarLocalPath;
    final hasPath = path != null && path.isNotEmpty;
    final personId = context.read<PersonBlock>().currentPersonID.value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                if (hasPath)
                  ClipOval(
                    child: LocalFirstImage(
                      localPath: path!,
                      remoteUrl: MinioService().publicUrlForKey(path),
                      subFolder: 'gratitude_avatars',
                      ownerId: personId,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: CircleAvatar(
                        radius: 28,
                        backgroundColor: _accent.withValues(alpha: 0.2),
                        child: Text(
                          FacebookProfileLink.initials(person.name),
                          style: const TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _accent.withValues(alpha: 0.2),
                    child: Text(
                      FacebookProfileLink.initials(person.name),
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GratitudeItemsView extends StatefulWidget {
  const _GratitudeItemsView({
    required this.allItems,
    required this.people,
    required this.colorScheme,
    required this.textTheme,
    required this.l10n,
    required this.bottomClearance,
    required this.onConfirmDelete,
    required this.onOpenFacebook,
    required this.onEdit,
    required this.onEmptyAdd,
  });

  final List<_GratitudeDisplayItem> allItems;
  final List<GratitudeEntryData> people;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations l10n;
  final double bottomClearance;
  final void Function(_GratitudeDisplayItem item) onConfirmDelete;
  final void Function(String url) onOpenFacebook;
  final void Function(_GratitudeDisplayItem item) onEdit;
  final VoidCallback onEmptyAdd;

  @override
  State<_GratitudeItemsView> createState() => _GratitudeItemsViewState();
}

class _GratitudeItemsViewState extends State<_GratitudeItemsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _personFilter;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      setState(() {
        // Leaving people tab clears person chip selection.
        if (_tabs.index != 0) _personFilter = null;
      });
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_GratitudeDisplayItem> get _filtered {
    final wantPerson = _tabs.index == 0;
    String? personName;
    if (wantPerson && _personFilter != null) {
      for (final p in widget.people) {
        if (p.id == _personFilter) {
          personName = p.name;
          break;
        }
      }
    }

    return widget.allItems.where((item) {
      if (wantPerson) {
        if (item.kind == 'thing') return false;
        if (_personFilter != null) {
          final matchId = item.id == _personFilter;
          final matchName = personName != null && item.name == personName;
          if (!matchId && !matchName) return false;
        }
      } else if (item.kind != 'thing') {
        return false;
      }
      if (_tagFilter != null && !item.tags.contains(_tagFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final l10n = widget.l10n;
    final accent = MindGratitudePanel.flagColor;
    final colorScheme = widget.colorScheme;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    onTap: (_) => setState(() {}),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: accent.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    labelColor: accent,
                    unselectedLabelColor:
                        colorScheme.onSurface.withValues(alpha: 0.65),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.person_outline_rounded, size: 18),
                        text: l10n.gratitude_kind_person,
                        height: 46,
                      ),
                      Tab(
                        icon: const Icon(Icons.category_outlined, size: 18),
                        text: l10n.gratitude_kind_thing,
                        height: 46,
                      ),
                    ],
                  ),
                ),
                if (_tabs.index == 0 && widget.people.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: const Icon(Icons.flag_rounded, size: 16),
                            label: Text(l10n.gratitude_filter_all),
                            selected: _personFilter == null,
                            onSelected: (_) =>
                                setState(() => _personFilter = null),
                          ),
                        ),
                        for (final person in widget.people)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: const Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                              ),
                              label: Text(person.name),
                              selected: _personFilter == person.id,
                              onSelected: (_) => setState(
                                () => _personFilter = _personFilter == person.id
                                    ? null
                                    : person.id,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tag in MindActivityTokens.presetTags)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              MindActivityTokens.tagLabel(l10n, tag),
                            ),
                            selected: _tagFilter == tag,
                            selectedColor: accent.withValues(alpha: 0.28),
                            onSelected: (_) => setState(
                              () =>
                                  _tagFilter = _tagFilter == tag ? null : tag,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.allItems.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_rounded, size: 64, color: accent),
                  const SizedBox(height: 12),
                  Text(l10n.gratitude_empty_title),
                  const SizedBox(height: 8),
                  Text(l10n.gratitude_empty_subtitle),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onEmptyAdd,
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(l10n.gratitude_add_title),
                  ),
                ],
              ),
            ),
          )
        else if (items.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                l10n.gratitude_empty_subtitle,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final cw = constraints.crossAxisExtent;
              var gap = 14.0;
              var hPad = 16.0;
              var maxTileWidth = 320.0;
              var tileHeight = 300.0;
              final bottomPad = widget.bottomClearance;
              final useList = cw < 720;

              if (cw >= 1200) {
                maxTileWidth = 300;
                tileHeight = 308;
                hPad = 32;
              } else if (cw >= 900) {
                maxTileWidth = 300;
                tileHeight = 304;
                hPad = 28;
              } else if (cw >= 640) {
                maxTileWidth = 280;
                tileHeight = 296;
                hPad = 20;
              }

              Widget card(_GratitudeDisplayItem item) => _GratitudeGridCard(
                    item: item,
                    layout: useList
                        ? _GratitudeCardLayout.list
                        : _GratitudeCardLayout.grid,
                    l10n: l10n,
                    onDelete: () => widget.onConfirmDelete(item),
                    onOpenFacebook: item.facebookUrl != null
                        ? () => widget.onOpenFacebook(item.facebookUrl!)
                        : null,
                    onEditAvatar: item.canEditAvatar
                        ? () => widget.onEdit(item)
                        : null,
                  );

              if (useList) {
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < items.length - 1 ? gap : 0,
                        ),
                        child: card(items[index]),
                      ),
                      childCount: items.length,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxTileWidth,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => card(items[index]),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _GratitudeSyncOnMount extends StatefulWidget {
  const _GratitudeSyncOnMount({
    required this.personId,
    required this.child,
  });

  final String personId;
  final Widget child;

  @override
  State<_GratitudeSyncOnMount> createState() => _GratitudeSyncOnMountState();
}

class _GratitudeSyncOnMountState extends State<_GratitudeSyncOnMount> {
  String? _lastSyncedPersonId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfNeeded());
  }

  @override
  void didUpdateWidget(covariant _GratitudeSyncOnMount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.personId != oldWidget.personId) {
      _syncIfNeeded();
    }
  }

  void _syncIfNeeded() {
    final id = widget.personId;
    if (id.isEmpty || id == _lastSyncedPersonId) return;
    _lastSyncedPersonId = id;
    if (!mounted) return;
    unawaited(
      MindGratitudePanel._syncGratitudeForPerson(context, id),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _GratitudeDisplayItem {
  const _GratitudeDisplayItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.date,
    required this.onDelete,
    this.note,
    this.tags = const [],
    this.avatarLocalPath,
    this.facebookUrl,
    this.canEditAvatar = false,
  });

  final String id;
  final String name;
  final String kind;
  final String? note;
  final List<String> tags;
  final DateTime date;
  final String? avatarLocalPath;
  final String? facebookUrl;
  final bool canEditAvatar;
  final Future<void> Function() onDelete;

  bool get isPerson => kind != 'thing';
}

enum _GratitudeCardLayout { grid, list }

class _GratitudeGridCard extends StatelessWidget {
  const _GratitudeGridCard({
    required this.item,
    required this.layout,
    required this.l10n,
    required this.onDelete,
    this.onOpenFacebook,
    this.onEditAvatar,
  });

  final _GratitudeDisplayItem item;
  final _GratitudeCardLayout layout;
  final AppLocalizations l10n;
  final VoidCallback onDelete;
  final VoidCallback? onOpenFacebook;
  final VoidCallback? onEditAvatar;

  static const _accent = MindGratitudePanel.flagColor;

  Widget _flagBubble({double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_accent, Colors.white, 0.2) ?? _accent,
            _accent.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.flag_rounded, size: size * 0.5, color: Colors.white),
    );
  }

  Widget _avatar(BuildContext context, {double radius = 40}) {
    final path = item.avatarLocalPath;
    final personId = context.read<PersonBlock>().currentPersonID.value;
    final hasPath = path != null && path.isNotEmpty;

    Widget face;
    if (hasPath) {
      final remote = MinioService().publicUrlForKey(path);
      face = ClipOval(
        child: LocalFirstImage(
          localPath: path,
          remoteUrl: remote,
          subFolder: 'gratitude_avatars',
          ownerId: personId,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: CircleAvatar(
            radius: radius,
            backgroundColor: _accent.withValues(alpha: 0.2),
            child: Text(
              FacebookProfileLink.initials(item.name),
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.55,
              ),
            ),
          ),
        ),
      );
    } else {
      face = CircleAvatar(
        radius: radius,
        backgroundColor: _accent.withValues(alpha: 0.2),
        child: Text(
          FacebookProfileLink.initials(item.name),
          style: TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.55,
          ),
        ),
      );
    }

    if (onEditAvatar == null) return face;

    return GestureDetector(
      onTap: onEditAvatar,
      onLongPress: onEditAvatar,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          SizedBox(width: radius * 2, height: radius * 2, child: face),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              size: radius * 0.35,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return layout == _GratitudeCardLayout.list
        ? _buildListCard(context)
        : _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final kindLabel = item.isPerson
        ? l10n.gratitude_kind_person
        : l10n.gratitude_kind_thing;
    final note = item.note?.trim() ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: isDark
              ? colorScheme.surface.withValues(alpha: 0.62)
              : colorScheme.surface,
          child: InkWell(
            onTap: onOpenFacebook,
            onLongPress: onDelete,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 2.2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accent.withValues(alpha: 0.38),
                              _accent.withValues(alpha: 0.12),
                              colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: item.isPerson
                              ? _avatar(context, radius: 44)
                              : GestureDetector(
                                  onTap: onEditAvatar,
                                  onLongPress: onEditAvatar,
                                  child: Icon(
                                    Icons.category_rounded,
                                    size: 56,
                                    color: _accent.withValues(alpha: 0.75),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(top: 10, left: 10, child: _flagBubble()),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            DateFormat('MMM d').format(item.date.toLocal()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kindLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final tag in item.tags.take(3))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    MindActivityTokens.tagLabel(l10n, tag),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              note,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.72),
                                height: 1.45,
                                fontSize: 12.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final kindLabel = item.isPerson
        ? l10n.gratitude_kind_person
        : l10n.gratitude_kind_thing;
    final note = item.note?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenFacebook,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isDark
                ? colorScheme.surface.withValues(alpha: 0.55)
                : colorScheme.surface,
            border: Border.all(color: _accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  item.isPerson
                      ? _avatar(context, radius: 26)
                      : GestureDetector(
                          onTap: onEditAvatar,
                          onLongPress: onEditAvatar,
                          child: _flagBubble(size: 52),
                        ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: _flagBubble(size: 22),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d').format(item.date.toLocal()),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kindLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
