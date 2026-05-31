import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
// Preview removed.
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:ice_gate/link_layer/note_export/NoteExportPreferences.dart';
import 'package:ice_gate/link_layer/note_export/NoteExportService.dart';
import 'package:ice_gate/link_layer/note_export/NoteExportSettingsSheet.dart';
import 'package:ice_gate/link_layer/note_export/DocxUtils.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:ice_gate/utils/journal_media.dart';
import 'package:ice_gate/utils/sync_device.dart';

class TextEditorPage extends StatefulWidget {
  final ProjectNoteData? note;
  final String? initialCategory;
  final File? initialFile;
  final String? initialImage;
  final Directory? initialDirectory; // Directory to save new files into
  final String? initialExtension;

  const TextEditorPage({
    super.key,
    this.note,
    this.initialCategory,
    this.initialFile,
    this.initialImage,
    this.initialDirectory,
    this.initialExtension,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _contentController;
  late final TextEditingController _titleController;
  late final FocusNode _editorFocusNode;
  late final FocusNode _titleFocusNode;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _focusMode = false;
  ProjectNoteData? _activeNote;
  // Preview mode removed (always editor).
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  File? _openedFile; // Track the currently opened local file

  // Mood selection
  String? _selectedMood;
  static const List<String> _moodOptions = [
    'Awesome',
    'Good',
    'Meh',
    'Bad',
    'Awful',
  ];

  /// Maps legacy DB values (emoji / old labels) to current [_moodOptions].
  static String? _normalizeMoodForDropdown(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (_moodOptions.contains(stored)) return stored;
    const legacy = <String, String>{
      '🤩': 'Awesome',
      '😄': 'Awesome',
      '✨': 'Awesome',
      '😊': 'Good',
      '🙂': 'Good',
      '😐': 'Meh',
      '😑': 'Meh',
      '😕': 'Bad',
      '😟': 'Bad',
      '😢': 'Awful',
      '😭': 'Awful',
      '😫': 'Awful',
    };
    return legacy[stored] ?? legacy[stored.trim()];
  }

  // Undo/Redo State
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedoAction = false;

  // AI Status
  final ValueNotifier<String?> syncStatus = ValueNotifier<String?>(null);
  String? _vaultPath;

  // Animation
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerOpacity;

  @override
  void initState() {
    super.initState();
    _initVaultPath();
    String title = widget.note?.title ?? '';
    String initialContent = '';

    if (widget.initialFile != null) {
      _openedFile = widget.initialFile;
      title = widget.initialFile!.path
          .split(Platform.pathSeparator)
          .last
          .replaceAll('.md', '');
      try {
        initialContent = widget.initialFile!.readAsStringSync();
        _lastSaved = widget.initialFile!.lastModifiedSync();
      } catch (e) {
        appLog("Error reading initial file: $e");
      }
    } else if (widget.note != null) {
      _lastSaved = widget.note?.updatedAt;
      if (widget.note!.content.isNotEmpty) {
        initialContent = _extractContent(widget.note!.content);
      }
    }

    _titleController = TextEditingController(text: title);

    // If initialImage is provided for a new note, insert it into the content
    if (widget.initialImage != null && initialContent.isEmpty) {
      initialContent = "![Image](${widget.initialImage})\n\n";
    }

    _contentController = TextEditingController(text: initialContent);
    _undoStack.add(initialContent);
    _activeNote = widget.note;
    _editorFocusNode = FocusNode();
    _titleFocusNode = FocusNode();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeInOut),
    );

    // Listen for changes
    _contentController.addListener(() {
      if (!_isUndoRedoAction) {
        if (_undoStack.isEmpty || _undoStack.last != _contentController.text) {
          _redoStack.clear();
          if (_undoStack.length > 50) _undoStack.removeAt(0);
          _undoStack.add(_contentController.text);
        }
      }

      if (!_hasUnsavedChanges && mounted) {
        setState(() => _hasUnsavedChanges = true);
      }
      _scheduleAutoSave();
    });

    _titleController.addListener(() {
      if (!_hasUnsavedChanges && mounted) {
        setState(() => _hasUnsavedChanges = true);
      }
      _scheduleAutoSave();
    });
  }

  /// Extract content — if JSON (old Quill Delta), convert to plain text.
  /// Otherwise return as-is (markdown).
  String _extractContent(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        // Quill Delta format — extract plain text
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    // Already plain text / markdown
    return raw;
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (!_hasUnsavedChanges || !mounted) return;
      if (_openedFile != null) {
        // Never trigger a "Save As" picker from autosave.
        _saveToLocalFile();
      } else {
        _saveNote(showConfirmation: false);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _contentController.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _titleFocusNode.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _initVaultPath() async {
    if (widget.initialDirectory != null) {
      setState(() {
        _vaultPath = widget.initialDirectory!.path;
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final appDir = await getApplicationDocumentsDirectory();
      setState(() {
        _vaultPath = '${appDir.path}/${user.id}/user_markdown_documentation';
      });
    }

    // Initialize selected mood from existing note if editing
    if (widget.note != null && widget.note!.mood != null) {
      final normalized = _normalizeMoodForDropdown(widget.note!.mood);
      if (mounted) {
        setState(() => _selectedMood = normalized);
      } else {
        _selectedMood = normalized;
      }
    }
  }

  Future<void> _pickAndInsertImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final imageFile = File(result.files.single.path!);
        final extension = p.extension(imageFile.path);
        final fileName =
            'img_${DateTime.now().millisecondsSinceEpoch}$extension';

        if (_vaultPath == null) await _initVaultPath();
        if (_vaultPath == null) return;

        final vaultDir = Directory(_vaultPath!);
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }

        final destination = File('${vaultDir.path}/$fileName');
        await imageFile.copy(destination.path);

        // Insert markdown link at cursor
        _insertMarkdown('![Image]($fileName)');
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('❌ [Editor] Image pick failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add image: $e')));
      }
    }
  }

  void _dismissKeyboard() {
    _editorFocusNode.unfocus();
    _titleFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    if (_focusMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _headerAnimController.forward();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _headerAnimController.reverse();
      _dismissKeyboard();
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isUndoRedoAction = true;
      _redoStack.add(_undoStack.removeLast());
      final previousState = _undoStack.last;
      _contentController.text = previousState;
      _isUndoRedoAction = false;
      HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isUndoRedoAction = true;
      final nextState = _redoStack.removeLast();
      _undoStack.add(nextState);
      _contentController.text = nextState;
      _isUndoRedoAction = false;
      HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  Future<void> _magicAIImprove() async {
    setState(() => _isSaving = true);
    syncStatus.value = "AI is polishing your text...";

    try {
      // Simulate/Trigger AI Improvement
      // In a real app, this would call Supabase Edge Function or OpenAI
      await Future.delayed(const Duration(seconds: 2));

      final currentText = _contentController.text;
      if (currentText.trim().isEmpty) return;

      final improvedText = """$currentText\n\n---
*AI Suggestion: Consider clarifying the objective in the first paragraph to better engage the reader.*""";

      _contentController.text = improvedText;
      syncStatus.value = "✨ Magic applied!";
    } catch (e) {
      syncStatus.value = "❌ Magic failed: $e";
    } finally {
      setState(() => _isSaving = false);
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  Future<void> _pickLocalFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final ext = p.extension(file.path).toLowerCase();
      final title =
          result.files.single.name.replaceFirst(RegExp(r'\.(md|txt|docx)$'), '');
      String content;
      if (ext == '.docx') {
        final bytes = await file.readAsBytes();
        content = DocxUtils.extractPlainText(bytes);
      } else {
        content = await file.readAsString();
      }

      setState(() {
        _contentController.text = content;
        _titleController.text = title;
        _openedFile = file;
        _hasUnsavedChanges = false;
        _lastSaved = file.lastModifiedSync();
      });
    }
  }

  Future<bool> _saveNote({bool showConfirmation = true}) async {
    if (_isSaving) return false;
    setState(() => _isSaving = true);
    try {
      final dao = context.read<ProjectNoteDAO>();
      final personId =
          context.read<PersonBlock>().currentPersonID.value ??
          Supabase.instance.client.auth.currentUser?.id;
      if (personId == null || personId.isEmpty) {
        if (!mounted) return false;
        if (showConfirmation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in to save notes'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      final title = _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim();
      final content = _contentController.text;
      final category =
          _activeNote?.category ?? widget.initialCategory ?? 'projects';
      final extension =
          _activeNote?.extension ?? widget.initialExtension ?? '.md';

      final imageLocal = JournalMedia.extractFirstImagePath(content);
      final imageRemote = JournalMedia.canonicalRemotePath(
        imageLocal,
        personId: personId,
      );
      final imageDevice = imageLocal != null ? SyncDevice.current() : null;

      if (_activeNote != null) {
        final updated = _activeNote!.copyWith(
          title: title,
          content: content,
          mood: Value(_selectedMood),
          localPath: Value(imageLocal),
          remotePath: Value(imageRemote),
          device: Value(imageDevice),
          updatedAt: DateTime.now(),
        );
        await dao.updateNote(updated);
        if (!mounted) return false;
        setState(() {
          _activeNote = updated;
          _hasUnsavedChanges = false;
          _lastSaved = DateTime.now();
        });
      } else {
        final id = await dao.insertNote(
          title: title,
          content: content,
          personID: personId,
          category: category,
          mood: _selectedMood,
          extension: extension,
          localPath: imageLocal,
          remotePath: imageRemote,
          device: imageDevice,
        );
        final saved = await dao.getNoteById(id);
        if (!mounted) return false;
        setState(() {
          _activeNote = saved;
          _hasUnsavedChanges = false;
          _lastSaved = DateTime.now();
        });
      }

      if (showConfirmation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteNote() async {
    final note = _activeNote;
    if (note == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.project_delete_note_title),
        content: Text(l10n.project_delete_note_msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await context.read<ProjectNoteDAO>().deleteNote(note.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _saveToLocalFile() async {
    if (_openedFile != null) {
      final ext = p.extension(_openedFile!.path).toLowerCase();
      if (ext == '.docx') {
        final bytes =
            DocxUtils.createDocxBytesFromPlainText(_contentController.text);
        await _openedFile!.writeAsBytes(bytes, flush: true);
      } else {
        await _openedFile!.writeAsString(_contentController.text, flush: true);
      }
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _lastSaved = DateTime.now();
        });
      }
    } else {
      // Prompt user to save as a new file if no file is currently opened
      final ext = widget.initialExtension ?? '.md';
      final fileName = '${_titleController.text}$ext';
      final bytes =
          ext.toLowerCase() == '.docx'
              ? DocxUtils.createDocxBytesFromPlainText(_contentController.text)
              : Uint8List.fromList(utf8.encode(_contentController.text));
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['md', 'txt', 'docx'],
        bytes: bytes,
      );

      if (path != null) {
        final file = File(path);
        final ext = p.extension(file.path).toLowerCase();
        if (ext == '.docx') {
          final bytes =
              DocxUtils.createDocxBytesFromPlainText(_contentController.text);
          await file.writeAsBytes(bytes, flush: true);
        } else {
          await file.writeAsString(_contentController.text, flush: true);
        }
        if (mounted) {
          setState(() {
            _openedFile = file;
            _hasUnsavedChanges = false;
            _lastSaved = DateTime.now();
          });
        }
      } else {
        // On iOS/Android, saveFile can succeed without returning a filesystem path
        // when [bytes] is provided. In that case, consider the content saved.
        if (mounted) {
          setState(() {
            _hasUnsavedChanges = false;
            _lastSaved = DateTime.now();
          });
        }
      }
    }
  }

  Future<void> _runPostSaveExportsIfNeeded(String title, String content) async {
    try {
      final prefs = await NoteExportPreferences.load();
      await NoteExportService.runPostSaveExports(
        prefs: prefs,
        title: title,
        body: content,
      );
    } catch (e, st) {
      debugPrint('Note export after save: $e\n$st');
    }
  }

  Future<void> _exportToNotionFromEditor() async {
    final title = _titleController.text;
    final content = _contentController.text;
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final prefs = await NoteExportPreferences.load();
    if (!prefs.hasNotionConfig) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Note export settings and add your Notion token and database ID.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await NoteExportService.exportNotionIfConfigured(
        prefs,
        title: title,
        body: content,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exported to Notion'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notion export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportToGoogleDocFromEditor() async {
    final title = _titleController.text;
    final content = _contentController.text;
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await NoteExportService.exportToGoogleDoc(
        title: title,
        body: content,
        interactive: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Created Google Doc'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Doc export failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showStats() {
    final plainText = _contentController.text.trim();
    final wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).length;
    final charCount = plainText.length;
    final lineCount = _contentController.text.split('\n').length;
    final readTime = (wordCount / 200).ceil();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Note Statistics',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statCard(
                    ctx,
                    '$wordCount',
                    'Words',
                    Icons.text_fields_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    ctx,
                    '$charCount',
                    'Characters',
                    Icons.abc_rounded,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard(
                    ctx,
                    '$lineCount',
                    'Lines',
                    Icons.format_list_numbered_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    ctx,
                    '~$readTime min',
                    'Read time',
                    Icons.timer_rounded,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // isScrollControlled allows the sheet to expand beyond half-screen height
      // so all menu options, including Delete Note, are always accessible
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Scrollable list of options
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _optionTile(
                          ctx,
                          icon: Icons.save_rounded,
                          label: 'Save Note',
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.pop(ctx);
                            _saveNote();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.file_download_rounded,
                          label: 'Save to Local File',
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.pop(ctx);
                            _saveToLocalFile();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.file_open_rounded,
                          label: 'Open Local File',
                          color: Colors.amber,
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickLocalFile();
                          },
                        ),
                     
                        _optionTile(
                          ctx,
                          icon: Icons.share_rounded,
                          label: 'Share Markdown',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(ctx);
                            Share.share(
                              _contentController.text,
                              subject: _titleController.text,
                            );
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.bar_chart_rounded,
                          label: 'Statistics',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showStats();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: _focusMode
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          label: _focusMode ? 'Exit Focus Mode' : 'Focus Mode',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pop(ctx);
                            _toggleFocusMode();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.copy_rounded,
                          label: 'Copy as Markdown',
                          color: Colors.teal,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await Clipboard.setData(
                              ClipboardData(text: _contentController.text),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.lan_rounded,
                          label: 'Send to AI Hub',
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.pop(ctx);
                            final plainText = _contentController.text;
                            context.go('/widgets/ssh', extra: plainText);
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.book_outlined,
                          label: 'Export to Notion',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.pop(ctx);
                            _exportToNotionFromEditor();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.description_outlined,
                          label: 'Export to Google Doc',
                          color: Colors.deepPurple,
                          onTap: () {
                            Navigator.pop(ctx);
                            _exportToGoogleDocFromEditor();
                          },
                        ),
                        _optionTile(
                          ctx,
                          icon: Icons.settings_suggest_outlined,
                          label: 'Note export settings',
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.pop(ctx);
                            showNoteExportSettingsSheet(context);
                          },
                        ),

                        if (_activeNote != null) ...[
                          Divider(
                            height: 8,
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                          _optionTile(
                            ctx,
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete Note',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(ctx);
                              _confirmDeleteNote();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  /// Insert markdown syntax at cursor
  void _insertMarkdown(String prefix, {String suffix = ''}) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final start = sel.start;
    final end = sel.end;

    if (start < 0) return;

    final selectedText = text.substring(start, end);
    final newText = '$prefix$selectedText$suffix';
    _contentController.text = text.replaceRange(start, end, newText);
    _contentController.selection = TextSelection.collapsed(
      offset: start + prefix.length + selectedText.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;

    return PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('Do you want to save before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Discard'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (shouldSave == true) {
            await _saveNote(showConfirmation: false);
          }
          if (context.mounted) Navigator.pop(context);
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                _saveToLocalFile(),
            const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
                _saveToLocalFile(),
            const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
                _insertMarkdown('**', suffix: '**'),
            const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
                _insertMarkdown('**', suffix: '**'),
            const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
                _insertMarkdown('*', suffix: '*'),
            const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
                _insertMarkdown('*', suffix: '*'),
            // Preview shortcut removed.
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                _undo,
            const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
            const SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: true,
              shift: true,
            ): _redo,
            const SingleActivator(
              LogicalKeyboardKey.keyZ,
              meta: true,
              shift: true,
            ): _redo,
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Background gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface,
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Column(
                    children: [
                      // Animated Header
                      AnimatedBuilder(
                        animation: _headerOpacity,
                        builder: (context, child) {
                          return _focusMode && _headerOpacity.value < 0.05
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.top + 8,
                                )
                              : Opacity(
                                  opacity: _headerOpacity.value,
                                  child: _buildCustomHeader(
                                    context,
                                    colorScheme,
                                  ),
                                );
                        },
                      ),

                      // Editor / Preview
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _dismissKeyboard,
                          onDoubleTap: _toggleFocusMode,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                TextField(
                                  controller: _titleController,
                                  focusNode: _titleFocusNode,
                                  maxLines: 2,
                                  minLines: 1,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.6,
                                    height: 1.25,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.project_note_untitled,
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.25,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) =>
                                      _editorFocusNode.requestFocus(),
                                ),

                                if (!_focusMode) ...[
                                  const SizedBox(height: 10),
                                  ValueListenableBuilder<String?>(
                                    valueListenable: syncStatus,
                                    builder: (context, aiStatus, _) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSaveStatusRow(
                                            colorScheme,
                                            l10n,
                                          ),
                                          if (aiStatus != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome_rounded,
                                                  size: 14,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    aiStatus,
                                                    style: TextStyle(
                                                      color: Colors.amber
                                                          .shade800,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (_openedFile != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .folder_open_rounded,
                                                  size: 14,
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.7),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    p.basename(
                                                      _openedFile!.path,
                                                    ),
                                                    style: TextStyle(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ] else
                                  const SizedBox(height: 12),

                                Expanded(
                                  child: _buildMarkdownEditor(
                                    colorScheme,
                                    l10n,
                                    reserveToolbarSpace: keyboardOpen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating Markdown Toolbar
                if (!_focusMode)
                  _buildMarkdownToolbar(colorScheme),
                if (_focusMode)
                  Positioned(
                    right: 20,
                    bottom: 24,
                    child: _buildKeyboardDismissButton(colorScheme),
                  ),

                // Preview button removed.
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildSaveStatusRow(ColorScheme colorScheme, AppLocalizations l10n) {
    if (_isSaving) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.note_editor_saving,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_hasUnsavedChanges) {
      return Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.note_editor_unsaved,
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_lastSaved == null) return const SizedBox.shrink();

    final when = _formatRelativeTime(_lastSaved!, l10n);
    return Row(
      children: [
        Icon(
          Icons.cloud_done_outlined,
          size: 15,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          l10n.note_editor_saved_label(when),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownEditor(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required bool reserveToolbarSpace,
  }) {
    final bottomPad = reserveToolbarSpace ? 72.0 : 24.0;
    return TextField(
      controller: _contentController,
      focusNode: _editorFocusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      style: TextStyle(
        fontSize: 17,
        height: 1.65,
        color: colorScheme.onSurface.withValues(alpha: 0.9),
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: l10n.note_editor_write_hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          fontSize: 17,
          height: 1.65,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(bottom: bottomPad),
      ),
    );
  }

  // Preview renderer removed.

  Widget _buildMoodSelector(ColorScheme colorScheme) {
    final validValue =
        _selectedMood != null && _moodOptions.contains(_selectedMood)
            ? _selectedMood
            : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          hint: Text(
            'Mood',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          icon: const Icon(Icons.mood, size: 20),
          iconSize: 20,
          elevation: 4,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
          underline: Container(
            height: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedMood = newValue;
              _hasUnsavedChanges = true;
            });
          },
          items: _moodOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMarkdownToolbar(ColorScheme colorScheme) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = viewInsets.bottom > 0
        ? viewInsets.bottom + 8
        : safeBottom + 16;

    return Positioned(
      bottom: bottom,
      left: 16,
      right: 16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolbarBtn(
                      Icons.keyboard_hide_rounded,
                      'Hide keyboard',
                      _dismissKeyboard,
                    ),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(
                      Icons.undo_rounded,
                      'Undo',
                      _undoStack.length > 1 ? _undo : null,
                    ),
                    _toolbarBtn(
                      Icons.redo_rounded,
                      'Redo',
                      _redoStack.isNotEmpty ? _redo : null,
                    ),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(
                      Icons.auto_awesome_rounded,
                      'Magic AI',
                      _magicAIImprove,
                      color: Colors.amber,
                    ),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.format_bold_rounded, 'Bold', () {
                      _insertMarkdown('**', suffix: '**');
                    }),
                    _toolbarBtn(Icons.format_italic_rounded, 'Italic', () {
                      _insertMarkdown('*', suffix: '*');
                    }),
                    _toolbarBtn(Icons.strikethrough_s_rounded, 'Strike', () {
                      _insertMarkdown('~~', suffix: '~~');
                    }),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.title_rounded, 'H1', () {
                      _insertMarkdown('# ');
                    }),
                    _toolbarBtn(Icons.text_fields_rounded, 'H2', () {
                      _insertMarkdown('## ');
                    }),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.format_list_bulleted_rounded, 'List', () {
                      _insertMarkdown('- ');
                    }),
                    _toolbarBtn(
                      Icons.format_list_numbered_rounded,
                      'Numbered',
                      () {
                        _insertMarkdown('1. ');
                      },
                    ),
                    _toolbarBtn(Icons.format_quote_rounded, 'Quote', () {
                      _insertMarkdown('> ');
                    }),
                    _toolbarBtn(Icons.code_rounded, 'Code', () {
                      _insertMarkdown('`', suffix: '`');
                    }),
                    _toolbarBtn(Icons.link_rounded, 'Link', () {
                      _insertMarkdown('[', suffix: '](url)');
                    }),
                    _toolbarBtn(
                      Icons.image_rounded,
                      'Image',
                      _pickAndInsertImage,
                      color: colorScheme.secondary,
                    ),
                    _toolbarDivider(colorScheme),
                    // Mood selector
                    _buildMoodSelector(colorScheme),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.terminal_rounded, 'AI Hub', () {
                      final plainText = _contentController.text;
                      context.go('/widgets/ssh', extra: plainText);
                    }, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardDismissButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Hide keyboard',
        icon: const Icon(Icons.keyboard_hide_rounded),
        onPressed: _dismissKeyboard,
      ),
    );
  }

  Widget _toolbarBtn(
    IconData icon,
    String tooltip,
    VoidCallback? onTap, {
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final iconColor = color ??
        (enabled
            ? colorScheme.onSurface.withValues(alpha: 0.75)
            : colorScheme.onSurface.withValues(alpha: 0.22));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _toolbarDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.onSurface.withValues(alpha: 0.0),
            colorScheme.onSurface.withValues(alpha: 0.15),
            colorScheme.onSurface.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, ColorScheme colorScheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: colorScheme.surface.withValues(alpha: 0.5),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Back button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.05),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () {
                        _dismissKeyboard();
                        if (_hasUnsavedChanges) {
                          _saveNote(showConfirmation: false).then((_) {
                            if (context.mounted) Navigator.pop(context);
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const Spacer(),

                  // Preview toggle removed.

                  const SizedBox(width: 12),

                  // More options button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.05),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: _showMoreOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Preview toggle UI removed.

  String _formatRelativeTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return l10n.note_editor_saved_just_now;
    if (diff.inMinutes < 60) {
      return l10n.note_editor_saved_minutes(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.note_editor_saved_hours(diff.inHours);
    }
    return DateFormat.MMMd().format(time);
  }
}
