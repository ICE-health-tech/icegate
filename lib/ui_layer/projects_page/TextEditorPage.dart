import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TextEditorPage extends StatefulWidget {
  final ProjectNoteData? note;
  final String? initialCategory;
  final File? initialFile;

  const TextEditorPage({super.key, this.note, this.initialCategory, this.initialFile});

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
  bool _isPreview = false;
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  File? _openedFile; // Track the currently opened local file
  
  // Undo/Redo State
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedoAction = false;
  
  // AI Status
  final ValueNotifier<String?> syncStatus = ValueNotifier<String?>(null);

  // Animation
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerOpacity;

  @override
  void initState() {
    super.initState();
    String title = widget.note?.title ?? '';
    String initialContent = '';
    
    if (widget.initialFile != null) {
      _openedFile = widget.initialFile;
      title = widget.initialFile!.path.split(Platform.pathSeparator).last.replaceAll('.md', '');
      try {
        initialContent = widget.initialFile!.readAsStringSync();
        _lastSaved = widget.initialFile!.lastModifiedSync();
      } catch (e) {
        print("Error reading initial file: $e");
      }
    } else if (widget.note != null) {
      _lastSaved = widget.note?.updatedAt;
      if (widget.note!.content.isNotEmpty) {
        initialContent = _extractContent(widget.note!.content);
      }
    }

    _titleController = TextEditingController(text: title);
    _contentController = TextEditingController(text: initialContent);
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
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      if (_hasUnsavedChanges && mounted) {
        _saveNote(showSnackbar: false);
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

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    if (_focusMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _headerAnimController.forward();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _headerAnimController.reverse();
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
      allowedExtensions: ['md', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final title = result.files.single.name.replaceFirst(RegExp(r'\.md$'), '');

      setState(() {
        _contentController.text = content;
        _titleController.text = title;
        _openedFile = file;
        _hasUnsavedChanges = false;
        _lastSaved = file.lastModifiedSync();
      });
    }
  }

  Future<void> _saveToLocalFile() async {
    if (_openedFile != null) {
      await _openedFile!.writeAsString(_contentController.text);
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _lastSaved = DateTime.now();
        });
      }
    } else {
      // Prompt user to save as a new file if no file is currently opened
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save as Markdown',
        fileName: '${_titleController.text}.md',
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(_contentController.text);
        if (mounted) {
          setState(() {
            _openedFile = file;
            _hasUnsavedChanges = false;
            _lastSaved = DateTime.now();
          });
        }
      }
    }
  }

  Future<void> _saveNote({bool showSnackbar = true}) async {
    final title = _titleController.text;
    final content = _contentController.text; // Store as plain markdown

    if (title.isEmpty) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
     
      final String? userAlias = Supabase.instance.client.auth.currentUser?.id;
        final fileName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
         // 1. Automatic Save to user_markdown_documentation
      final appDir = await getApplicationDocumentsDirectory();
                            
      final docDir = Directory('${appDir.path}/${userAlias}/user_markdown_documentation');
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      
      final String savingPath=docDir.path+"/"+fileName+".md";
      // Clean filename
    
      // final localFile = File('${docDir.path}/$fileName.md');
          final localFile = File(savingPath);
      await localFile.writeAsString(content);
      
      // If we didn't have a file opened manually, track this auto-saved one
      if (_openedFile == null) {
        _openedFile = localFile;
      }

      // 2. Database Sync
      if (widget.note != null) {
        await context.read<ProjectNoteDAO>().updateNote(
          widget.note!.copyWith(title: title, content: content),
        );
      } else {
        // Only insert to DB if it's a new database note
        final personBlock = context.read<PersonBlock>();
        await context.read<ProjectNoteDAO>().insertNote(
          title: title,
          content: content,
          personID: personBlock.currentPersonID.value,
          category: widget.initialCategory,
        );
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
          _lastSaved = DateTime.now();
        });
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Saved'),
                ],
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              width: 140,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
              color: colorScheme.outlineVariant.withOpacity(0.3),
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
          color: color.withOpacity(0.08),
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
                color: colorScheme.onSurface.withOpacity(0.5),
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
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _optionTile(
                ctx,
                icon: Icons.save_rounded,
                label: 'Save Note',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(ctx);
                  _saveNote();
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
                icon: Icons.share_rounded,
                label: 'Share Markdown',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(_contentController.text, subject: _titleController.text);
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
              if (widget.note != null)
                _optionTile(
                  ctx,
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Note',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Delete Note?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<ProjectNoteDAO>().deleteNote(
                        widget.note!.id,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
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
          color: color.withOpacity(0.1),
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
          await _saveNote(showSnackbar: false);
        }
        if (context.mounted) Navigator.pop(context);
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _saveNote(),
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _saveNote(),
          const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => _insertMarkdown('**', suffix: '**'),
          const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () => _insertMarkdown('**', suffix: '**'),
          const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _insertMarkdown('*', suffix: '*'),
          const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () => _insertMarkdown('*', suffix: '*'),
          const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => setState(() => _isPreview = !_isPreview),
          const SingleActivator(LogicalKeyboardKey.keyP, meta: true): () => setState(() => _isPreview = !_isPreview),
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _redo,
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): _redo,
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          extendBodyBehindAppBar: true,
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
                        colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  // Animated Header
                  AnimatedBuilder(
                    animation: _headerOpacity,
                    builder: (context, child) {
                      return _focusMode && _headerOpacity.value < 0.05
                          ? SizedBox(
                              height: MediaQuery.of(context).padding.top + 8,
                            )
                          : Opacity(
                              opacity: _headerOpacity.value,
                              child: _buildCustomHeader(context, colorScheme),
                            );
                    },
                  ),

                  // Editor / Preview
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: _toggleFocusMode,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Hero(
                              tag: 'note_title_${widget.note?.noteID ?? "new"}',
                              child: Material(
                                color: Colors.transparent,
                                child: TextField(
                                  controller: _titleController,
                                  focusNode: _titleFocusNode,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.8,
                                    height: 1.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Untitled',
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.2,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) =>
                                      _editorFocusNode.requestFocus(),
                                ),
                              ),
                            ),

                            // Metadata row
                            if (!_focusMode) ...[
                              const SizedBox(height: 4),
                              ValueListenableBuilder(
                                valueListenable: syncStatus,
                                builder: (context, status, child) {
                                  return Row(
                                    children: [
                                      if (_lastSaved != null) ...[
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: colorScheme.onSurface.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saved ${_formatRelativeTime(_lastSaved!)}',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withOpacity(
                                              0.3,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                      if (_openedFile != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.folder_open_rounded,
                                          size: 12,
                                          color: colorScheme.primary.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _openedFile!.path,
                                            style: TextStyle(
                                              color: colorScheme.primary.withOpacity(0.5),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (_hasUnsavedChanges) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Unsaved',
                                          style: TextStyle(
                                            color: Colors.orange.withOpacity(0.7),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (_isSaving) ...[
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saving...',
                                          style: TextStyle(
                                            color: colorScheme.primary.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (status != null) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 12),

                            // Toggle Edit / Preview
                            Expanded(
                              child: _isPreview
                                  ? _buildMarkdownPreview(colorScheme)
                                  : _buildMarkdownEditor(colorScheme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Markdown Toolbar
              if (!_focusMode && !_isPreview) _buildMarkdownToolbar(colorScheme),

              Positioned(
                bottom: 64,
                // left: 24,
                right: 24,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isPreview
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _isPreview = !_isPreview),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPreview ? Icons.edit_rounded : Icons.preview_rounded,
                          size: 16,
                          color: _isPreview
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isPreview ? 'EDIT' : 'PREVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: _isPreview
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.6),
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
    );
  }

  Widget _buildMarkdownEditor(ColorScheme colorScheme) {
    return TextField(
      controller: _contentController,
      focusNode: _editorFocusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      style: TextStyle(
        fontSize: 15,
        height: 1.8,
        color: colorScheme.onSurface.withOpacity(0.85),
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText:
            'Write in markdown...\n\n# Heading\n## Subheading\n**bold** *italic* ~~strikethrough~~\n- bullet list\n1. numbered list\n> blockquote\n`inline code`',
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.15),
          fontSize: 14,
          height: 1.8,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(bottom: 120),
      ),
    );
  }

  Widget _buildMarkdownPreview(ColorScheme colorScheme) {
    return Markdown(
      data: _contentController.text,
      padding: const EdgeInsets.only(bottom: 120),
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.3,
          color: colorScheme.onSurface,
        ),
        h2: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: colorScheme.onSurface,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: colorScheme.onSurface.withOpacity(0.9),
        ),
        p: TextStyle(
          fontSize: 16,
          height: 1.7,
          color: colorScheme.onSurface.withOpacity(0.85),
        ),
        code: TextStyle(
          fontSize: 14,
          backgroundColor: colorScheme.primary.withOpacity(0.08),
          color: colorScheme.primary,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary.withOpacity(0.4),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        listBullet: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownToolbar(ColorScheme colorScheme) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
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
                    _toolbarBtn(Icons.undo_rounded, 'Undo', _undo, 
                        color: _undoStack.length > 1 ? null : colorScheme.onSurface.withOpacity(0.2)),
                    _toolbarBtn(Icons.redo_rounded, 'Redo', _redo,
                        color: _redoStack.isNotEmpty ? null : colorScheme.onSurface.withOpacity(0.2)),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.auto_awesome_rounded, 'Magic AI', _magicAIImprove, color: Colors.amber),
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
                    _toolbarBtn(Icons.format_list_numbered_rounded, 'Numbered', () {
                      _insertMarkdown('1. ');
                    }),
                    _toolbarBtn(Icons.format_quote_rounded, 'Quote', () {
                      _insertMarkdown('> ');
                    }),
                    _toolbarBtn(Icons.code_rounded, 'Code', () {
                      _insertMarkdown('`', suffix: '`');
                    }),
                    _toolbarBtn(Icons.link_rounded, 'Link', () {
                      _insertMarkdown('[', suffix: '](url)');
                    }),
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

  Widget _toolbarBtn(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(
              icon,
              size: 20,
              color: color ?? colorScheme.onSurface.withOpacity(0.7),
            ),
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
            colorScheme.onSurface.withOpacity(0.0),
            colorScheme.onSurface.withOpacity(0.15),
            colorScheme.onSurface.withOpacity(0.0),
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
          color: colorScheme.surface.withOpacity(0.5),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () {
                        if (_hasUnsavedChanges) {
                          _saveNote(showSnackbar: false).then((_) {
                            if (context.mounted) Navigator.pop(context);
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const Spacer(),

                  // Preview / Edit toggle chip
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _headerToggleItem(
                          icon: Icons.edit_note_rounded,
                          label: 'EDIT',
                          active: !_isPreview,
                          onTap: () => setState(() => _isPreview = false),
                          colorScheme: colorScheme,
                        ),
                        _headerToggleItem(
                          icon: Icons.auto_awesome_mosaic_rounded,
                          label: 'PREVIEW',
                          active: _isPreview,
                          onTap: () => setState(() => _isPreview = true),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // More options button
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
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

  Widget _headerToggleItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active ? [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: active ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(time);
  }
}
