import 'package:flutter/material.dart';
import 'package:ice_gate/link_layer/note_export/NoteExportPreferences.dart';

Future<void> showNoteExportSettingsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _NoteExportSettingsBody(),
  );
}

class _NoteExportSettingsBody extends StatefulWidget {
  const _NoteExportSettingsBody();

  @override
  State<_NoteExportSettingsBody> createState() =>
      _NoteExportSettingsBodyState();
}

class _NoteExportSettingsBodyState extends State<_NoteExportSettingsBody> {
  bool _loading = true;
  late bool _autoAfterSave;
  late bool _notionOn;
  late bool _gdocsOn;
  late TextEditingController _dbId;
  late TextEditingController _titleProp;
  late TextEditingController _secret;

  /// `null` means user did not touch secret field (persist unchanged).
  bool _secretTouched = false;

  @override
  void initState() {
    super.initState();
    _dbId = TextEditingController();
    _titleProp = TextEditingController();
    _secret = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final p = await NoteExportPreferences.load();
    if (!mounted) return;
    setState(() {
      _autoAfterSave = p.autoExportAfterSave;
      _notionOn = p.notionEnabled;
      _gdocsOn = p.googleDocsEnabled;
      _dbId.text = p.notionDatabaseId;
      _titleProp.text = p.notionTitlePropertyName;
      _secret.text = p.notionSecretPresent ? '••••••••' : '';
      _secretTouched = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _dbId.dispose();
    _titleProp.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String? secretArg;
    if (_secretTouched) {
      if (_secret.text == '••••••••') {
        secretArg = null;
      } else if (_secret.text.trim().isEmpty) {
        secretArg = '';
      } else {
        secretArg = _secret.text;
      }
    }
    await NoteExportPreferences.save(
      autoExportAfterSave: _autoAfterSave,
      notionEnabled: _notionOn,
      googleDocsEnabled: _gdocsOn,
      notionDatabaseId: _dbId.text,
      notionTitlePropertyName: _titleProp.text,
      notionSecret: secretArg,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note export settings saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottom + 24),
        child: const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export after save',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional: push each saved note to Notion and/or Google Docs from '
              'this device. Create a Notion integration and share your database '
              'with it; paste the secret and database ID below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-export after save'),
              value: _autoAfterSave,
              onChanged: (v) => setState(() => _autoAfterSave = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Notion (when auto-export is on)'),
              value: _notionOn,
              onChanged: (v) => setState(() => _notionOn = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Google Doc (when auto-export is on)'),
              value: _gdocsOn,
              onChanged: (v) => setState(() => _gdocsOn = v),
            ),
            const Divider(height: 32),
            Text(
              'Notion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _secret,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Integration secret',
                hintText: 'secret_…',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                if (_secret.text == '••••••••') {
                  setState(() {
                    _secret.text = '';
                    _secretTouched = true;
                  });
                }
              },
              onChanged: (_) {
                _secretTouched = true;
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dbId,
              decoration: const InputDecoration(
                labelText: 'Database ID',
                hintText: 'UUID of your Notion database',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleProp,
              decoration: const InputDecoration(
                labelText: 'Title property name',
                hintText: 'Often "Name" or "Title"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
