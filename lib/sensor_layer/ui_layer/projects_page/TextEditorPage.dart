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
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/StorageBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindGratitudePanel.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
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

  /// Image paths parsed out of markdown — shown as previews above the editor body.
  List<String> _inlineImagePaths = [];
  bool _editorImagesSynced = false;

  // Mood selection
  String? _selectedMood;
  static const List<String> _moodOptions = [
    'Awesome',
    'Good',
    'Meh',
    'Bad',
    'Awful',
  ];

  IconData _moodIconData(String mood) {
    return switch (mood.toLowerCase()) {
      'awesome' => Icons.sentiment_very_satisfied_rounded,
      'good' => Icons.sentiment_satisfied_alt_rounded,
      'meh' => Icons.sentiment_neutral_rounded,
      'bad' => Icons.sentiment_dissatisfied_rounded,
      'awful' => Icons.sentiment_very_dissatisfied_rounded,
      _ => Icons.sentiment_neutral_rounded,
    };
  }

  String _moodLabel(AppLocalizations l10n, String mood) {
    return switch (mood) {
      'Awesome' => l10n.mood_rad,
      'Good' => l10n.mood_good,
      'Meh' => l10n.mood_meh,
      'Bad' => l10n.mood_bad,
      'Awful' => l10n.mood_awful,
      _ => mood,
    };
  }

  String? _resolveTenantId(PersonBlock personBlock) {
    final profile = personBlock.information.value.profiles;
    final user = Supabase.instance.client.auth.currentUser;
    final Object? raw = (profile.tenantId != null &&
            profile.tenantId!.isNotEmpty)
        ? profile.tenantId
        : (user?.appMetadata['tenant_id'] ??
            user?.userMetadata?['tenant_id']);
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  Widget _buildMoodIconBubble({
    required ColorScheme colorScheme,
    required String mood,
    required bool selected,
    double size = 52,
  }) {
    final color = mindMoodAccent(_moodScore(mood));
    final icon = _moodIconData(mood);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.18) ?? color,
                  color.withValues(alpha: 0.62),
                ],
              )
            : null,
        color: selected ? null : colorScheme.surface.withValues(alpha: 0.48),
        border: Border.all(
          color: selected
              ? color.withValues(alpha: 0.95)
              : color.withValues(alpha: 0.28),
          width: selected ? 2.4 : 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.42),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: selected ? Colors.white : color,
      ),
    );
  }

  bool get _isJournalNote {
    final category = _activeNote?.category ?? widget.initialCategory;
    return category == 'social';
  }

  int _moodScore(String? mood) {
    return switch (mood?.toLowerCase()) {
      'awful' => 1,
      'bad' => 2,
      'meh' => 3,
      'good' => 4,
      'awesome' => 5,
      _ => 3,
    };
  }

  Color _journalAccent() => mindMoodAccent(_moodScore(_selectedMood));

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
        final parsed = _parseInitialContent(initialContent);
        _inlineImagePaths = parsed.images;
        initialContent = parsed.body;
      } catch (e) {
        appLog("Error reading initial file: $e");
      }
    } else if (widget.note != null) {
      _lastSaved = widget.note?.updatedAt;
      if (widget.note!.content.isNotEmpty) {
        final parsed = _parseInitialContent(widget.note!.content);
        _inlineImagePaths = parsed.images;
        initialContent = parsed.body;
      }
    }

    _titleController = TextEditingController(text: title);

    if (widget.initialImage != null && initialContent.isEmpty) {
      _inlineImagePaths = [widget.initialImage!];
    } else if (widget.initialImage != null) {
      _inlineImagePaths = [
        widget.initialImage!,
        ..._inlineImagePaths,
      ];
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _pullEditorImages());
  }

  String _fullNoteContent() {
    return JournalMedia.composeContent(
      imagePaths: _inlineImagePaths,
      body: _contentController.text,
    );
  }

  ({List<String> images, String body}) _parseInitialContent(String raw) {
    final images = JournalMedia.extractAllImagePaths(raw);
    final body = JournalMedia.extractPlainBody(raw);
    return (images: images, body: body);
  }

  Future<void> _pullEditorImages() async {
    if (_editorImagesSynced || !mounted || _inlineImagePaths.isEmpty) return;

    final personId =
        context.read<PersonBlock>().currentPersonID.value ??
        Supabase.instance.client.auth.currentUser?.id;
    if (personId == null || personId.isEmpty) return;

    _editorImagesSynced = true;
    try {
      final storage = context.read<StorageBlock>();
      final dao = context.read<ProjectNoteDAO>();
      await storage.backfillProjectNoteMediaFromContent(
        personId: personId,
        notesDao: dao,
        category: _activeNote?.category,
      );
      if (_activeNote != null) {
        final fresh = await dao.getNoteById(_activeNote!.id);
        if (fresh != null) _activeNote = fresh;
        await storage.pullProjectNoteImagesFromCloud(
          personId: personId,
          notes: [if (_activeNote != null) _activeNote!],
        );
      } else {
        await storage.pullJournalImagePaths(
          personId: personId,
          imagePaths: _inlineImagePaths,
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      appLog('TextEditorPage: image pull failed: $e');
    }
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

        final personId =
            context.read<PersonBlock>().currentPersonID.value ??
            Supabase.instance.client.auth.currentUser?.id;
        final relativePath = personId != null && personId.isNotEmpty
            ? p.join(personId, 'user_markdown_documentation', fileName)
                .replaceAll('\\', '/')
            : fileName;

        setState(() {
          _inlineImagePaths = [..._inlineImagePaths, relativePath];
          _hasUnsavedChanges = true;
        });
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

  Future<void> _goToMindDashboard() async {
    _dismissKeyboard();
    if (_hasUnsavedChanges) {
      await _saveNote(showConfirmation: false);
    }
    if (!mounted) return;
    context.read<SocialBlock>().activeTab.value = 0;
    context.go('/social');
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
        final parsed = _parseInitialContent(content);
        _inlineImagePaths = parsed.images;
        _contentController.text = parsed.body;
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
      final personBlock = context.read<PersonBlock>();
      final personId =
          personBlock.currentPersonID.value ??
          Supabase.instance.client.auth.currentUser?.id;
      final tenantId =
          _resolveTenantId(personBlock) ?? DEFAULT_TENANT_ID;
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
      final content = _fullNoteContent();
      final category =
          _activeNote?.category ?? widget.initialCategory ?? 'projects';
      final extension =
          _activeNote?.extension ?? widget.initialExtension ?? '.md';

      final imageLocal =
          _inlineImagePaths.isNotEmpty ? _inlineImagePaths.first : null;
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
          tenantID: tenantId,
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
            DocxUtils.createDocxBytesFromPlainText(_fullNoteContent());
        await _openedFile!.writeAsBytes(bytes, flush: true);
      } else {
        await _openedFile!.writeAsString(_fullNoteContent(), flush: true);
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
              ? DocxUtils.createDocxBytesFromPlainText(_fullNoteContent())
              : Uint8List.fromList(utf8.encode(_fullNoteContent()));
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
              DocxUtils.createDocxBytesFromPlainText(_fullNoteContent());
          await file.writeAsBytes(bytes, flush: true);
        } else {
          await file.writeAsString(_fullNoteContent(), flush: true);
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
    final content = _fullNoteContent();
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
    final content = _fullNoteContent();
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
                              _fullNoteContent(),
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
                              ClipboardData(text: _fullNoteContent()),
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
                          icon: Icons.flag_rounded,
                          label: AppLocalizations.of(context)!.gratitude_update_flag,
                          color: const Color(0xFFE8A317),
                          onTap: () {
                            Navigator.pop(ctx);
                            MindGratitudePanel.showUpdateFlagPicker(context);
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
                // Background
                Positioned.fill(
                  child: _isJournalNote
                      ? _buildJournalBackground(colorScheme)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.surface,
                                colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: _isJournalNote ? 20.0 : 16.0,
                            ),
                            child: _isJournalNote
                                ? _buildJournalEditorBody(
                                    colorScheme,
                                    l10n,
                                    keyboardOpen: keyboardOpen,
                                  )
                                : _buildProjectEditorBody(
                                    colorScheme,
                                    l10n,
                                    keyboardOpen: keyboardOpen,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating Markdown Toolbar
                if (!_focusMode)
                  _isJournalNote
                      ? _buildJournalToolbar(colorScheme)
                      : _buildMarkdownToolbar(colorScheme),
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

  Widget _buildProjectEditorBody(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required bool keyboardOpen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              color: colorScheme.onSurface.withValues(alpha: 0.25),
              fontWeight: FontWeight.w800,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _editorFocusNode.requestFocus(),
        ),
        if (!_focusMode) ...[
          const SizedBox(height: 10),
          ValueListenableBuilder<String?>(
            valueListenable: syncStatus,
            builder: (context, aiStatus, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSaveStatusRow(colorScheme, l10n),
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
                              color: Colors.amber.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          Icons.folder_open_rounded,
                          size: 14,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.basename(_openedFile!.path),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        if (!_focusMode && _inlineImagePaths.isNotEmpty) ...[
          _buildInlineImagePreviews(colorScheme),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _buildMarkdownEditor(
            colorScheme,
            l10n,
            reserveToolbarSpace: keyboardOpen,
            showTopHint: _inlineImagePaths.isEmpty,
          ),
        ),
      ],
    );
  }

  DateTime get _journalLogTime =>
      _activeNote?.createdAt.toLocal() ?? DateTime.now();

  Widget _buildJournalEditorBody(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required bool keyboardOpen,
  }) {
    final accent = _journalAccent();
    final when = _journalLogTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_focusMode) ...[
          const SizedBox(height: 2),
          _buildJournalMoodSection(colorScheme, l10n, when),
          const SizedBox(height: 14),
        ],
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.88)
                  : colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : accent.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.92),
                    letterSpacing: -0.2,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.project_note_untitled,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _editorFocusNode.requestFocus(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                if (_inlineImagePaths.isNotEmpty) ...[
                  _buildInlineImagePreviews(
                    colorScheme,
                    journalStyle: true,
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: _buildMarkdownEditor(
                    colorScheme,
                    l10n,
                    reserveToolbarSpace: keyboardOpen,
                    showTopHint: _inlineImagePaths.isEmpty,
                    hintText: l10n.mind_quick_entry_hint,
                    fontSize: 15.5,
                    lineHeight: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJournalMoodSection(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    DateTime when,
  ) {
    return Column(
      children: [
        _buildDaylioMoodPicker(colorScheme, l10n),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat('EEEE, MMM d').format(when),
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            _buildJournalSaveChip(colorScheme, l10n),
          ],
        ),
      ],
    );
  }

  Widget _buildJournalSaveChip(ColorScheme colorScheme, AppLocalizations l10n) {
    if (_isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _journalAccent(),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.note_editor_saving,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      );
    }

    if (_hasUnsavedChanges) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.note_editor_unsaved,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      );
    }

    if (_lastSaved == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_done_rounded,
          size: 13,
          color: _journalAccent().withValues(alpha: 0.85),
        ),
        const SizedBox(width: 5),
        Text(
          l10n.note_editor_saved_label(_formatRelativeTime(_lastSaved!, l10n)),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildJournalBackground(ColorScheme colorScheme) {
    final accent = _journalAccent();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF0E1419) : colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.72),
              radius: 1.1,
              colors: [
                accent.withValues(alpha: isDark ? 0.32 : 0.22),
                accent.withValues(alpha: isDark ? 0.1 : 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.06),
                Colors.transparent,
                base,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaylioMoodPicker(ColorScheme colorScheme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: _moodOptions.map((mood) {
          final selected = _selectedMood == mood;
          final color = mindMoodAccent(_moodScore(mood));
          final label = _moodLabel(l10n, mood);

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMood = mood;
                  _hasUnsavedChanges = true;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: _buildMoodIconBubble(
                      colorScheme: colorScheme,
                      mood: mood,
                      selected: selected,
                      size: selected ? 56 : 46,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: selected ? 10.5 : 9.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? color
                          : colorScheme.onSurface.withValues(alpha: 0.45),
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJournalToolbar(ColorScheme colorScheme) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // Body already shrinks for the keyboard — do not add viewInsets again.
    final keyboardOpen = viewInsets.bottom > 0;
    final bottom = keyboardOpen ? 8.0 : safeBottom + 14;
    final accent = _journalAccent();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: bottom,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surface.withValues(alpha: 0.92)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: accent,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: accent.withValues(alpha: 0.5),
              child: InkWell(
                onTap: _pickAndInsertImage,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const Spacer(),
          
            TextButton.icon(
              onPressed: _goToMindDashboard,
              icon: Icon(
                Icons.check_rounded,
                size: 18,
                color: accent,
              ),
              label: Text(
                'Done',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              onPressed: _showMoreOptions,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
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

  Future<void> _openInlineImageGallery(int initialIndex) async {
    if (!mounted || _inlineImagePaths.isEmpty) return;
    final personId =
        context.read<PersonBlock>().currentPersonID.value ??
        Supabase.instance.client.auth.currentUser?.id ??
        '';
    final paths = List<String>.from(_inlineImagePaths);
    final index = initialIndex.clamp(0, paths.length - 1);
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _JournalImageGalleryScreen(
          imagePaths: paths,
          initialIndex: index,
          personId: personId,
          remoteUrlForPath: (path) => _editorImageRemoteUrl(path, personId),
        ),
      ),
    );
  }

  Widget _buildInlineImagePreviews(
    ColorScheme colorScheme, {
    bool journalStyle = false,
  }) {
    final personId =
        context.read<PersonBlock>().currentPersonID.value ??
        Supabase.instance.client.auth.currentUser?.id ??
        '';
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = journalStyle
        ? (width >= 600 ? 148.0 : 128.0)
        : (width >= 900 ? 200.0 : width >= 600 ? 180.0 : 150.0);
    final radius = journalStyle ? 20.0 : 14.0;
    final total = _inlineImagePaths.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _inlineImagePaths.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _openInlineImageGallery(i),
            child: Container(
              decoration: journalStyle
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: LocalFirstImage(
                        ownerId: personId,
                        localPath: _inlineImagePaths[i],
                        remoteUrl: _editorImageRemoteUrl(
                          _inlineImagePaths[i],
                          personId,
                        ),
                        subFolder: 'user_markdown_documentation',
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (total > 1)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.collections_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${i + 1}/$total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
            ),
          ),
        ],
      ],
    );
  }

  String _editorImageRemoteUrl(String path, String personId) {
    final remoteKey = JournalMedia.canonicalRemotePath(
      path,
      personId: personId.isEmpty ? null : personId,
    );
    if (remoteKey == null || remoteKey.isEmpty) return '';
    if (remoteKey.startsWith('http://') || remoteKey.startsWith('https://')) {
      return remoteKey;
    }
    return MinioService().publicUrlForKey(remoteKey);
  }

  Widget _buildMarkdownEditor(
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required bool reserveToolbarSpace,
    bool showTopHint = true,
    String? hintText,
    double fontSize = 17,
    double lineHeight = 1.65,
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
        fontSize: fontSize,
        height: lineHeight,
        color: colorScheme.onSurface.withValues(alpha: 0.88),
        letterSpacing: 0.1,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: showTopHint
            ? (hintText ?? l10n.note_editor_write_hint)
            : hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.only(top: showTopHint ? 0 : 4, bottom: bottomPad),
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
    final keyboardOpen = viewInsets.bottom > 0;
    final bottom = keyboardOpen ? 8.0 : safeBottom + 16;

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
    final journal = _isJournalNote;
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: journal ? 6 : 10, sigmaY: journal ? 6 : 10),
        child: Container(
          color: journal
              ? Colors.transparent
              : colorScheme.surface.withValues(alpha: 0.5),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: journal
                          ? colorScheme.surface.withValues(alpha: 0.55)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.3,
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
                  const SizedBox(width: 12),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: journal
                          ? colorScheme.surface.withValues(alpha: 0.55)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
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

/// Full-screen swipe gallery for journal inline images.
class _JournalImageGalleryScreen extends StatefulWidget {
  const _JournalImageGalleryScreen({
    required this.imagePaths,
    required this.initialIndex,
    required this.personId,
    required this.remoteUrlForPath,
  });

  final List<String> imagePaths;
  final int initialIndex;
  final String personId;
  final String Function(String path) remoteUrlForPath;

  @override
  State<_JournalImageGalleryScreen> createState() =>
      _JournalImageGalleryScreenState();
}

class _JournalImageGalleryScreenState extends State<_JournalImageGalleryScreen> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagePaths.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(total > 1 ? '${_index + 1} / $total' : ''),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final path = widget.imagePaths[i];
          return LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                minScale: 0.85,
                maxScale: 4,
                child: Center(
                  child: LocalFirstImage(
                    ownerId: widget.personId,
                    localPath: path,
                    remoteUrl: widget.remoteUrlForPath(path),
                    subFolder: 'user_markdown_documentation',
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
