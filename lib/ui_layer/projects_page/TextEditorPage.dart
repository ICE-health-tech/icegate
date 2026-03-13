import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:intl/intl.dart';

class TextEditorPage extends StatefulWidget {
  final ProjectNoteData? note;
  final String? initialCategory;

  const TextEditorPage({super.key, this.note, this.initialCategory});

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

  // Animation
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerOpacity;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _editorFocusNode = FocusNode();
    _titleFocusNode = FocusNode();
    _lastSaved = widget.note?.updatedAt;

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeInOut),
    );

    // Load content — handle legacy Quill Delta JSON gracefully
    String initialContent = '';
    if (widget.note != null && widget.note!.content.isNotEmpty) {
      initialContent = _extractContent(widget.note!.content);
    }
    _contentController = TextEditingController(text: initialContent);

    // Listen for changes
    _contentController.addListener(() {
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
      _headerAnimController.forward();
    } else {
      _headerAnimController.reverse();
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
      if (widget.note != null) {
        await context.read<ProjectNoteDAO>().updateNote(
          widget.note!.copyWith(title: title, content: content),
        );
      } else {
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
                            Row(
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
                              ],
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
                width: 100,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isPreview
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => setState(() => _isPreview = !_isPreview),
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
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
      bottom: 10,
      left: 24,
      right: 24,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolbarBtn(Icons.format_bold, 'Bold', () {
                      _insertMarkdown('**', suffix: '**');
                    }),
                    _toolbarBtn(Icons.format_italic, 'Italic', () {
                      _insertMarkdown('*', suffix: '*');
                    }),
                    _toolbarBtn(Icons.strikethrough_s, 'Strike', () {
                      _insertMarkdown('~~', suffix: '~~');
                    }),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.title, 'H1', () {
                      _insertMarkdown('# ');
                    }),
                    _toolbarBtn(Icons.text_fields, 'H2', () {
                      _insertMarkdown('## ');
                    }),
                    _toolbarBtn(Icons.text_fields_outlined, 'H3', () {
                      _insertMarkdown('### ');
                    }),
                    _toolbarDivider(colorScheme),
                    _toolbarBtn(Icons.format_list_bulleted, 'List', () {
                      _insertMarkdown('- ');
                    }),
                    _toolbarBtn(Icons.format_list_numbered, 'Numbered', () {
                      _insertMarkdown('1. ');
                    }),
                    _toolbarBtn(Icons.format_quote, 'Quote', () {
                      _insertMarkdown('> ');
                    }),
                    _toolbarBtn(Icons.code, 'Code', () {
                      _insertMarkdown('`', suffix: '`');
                    }),
                    _toolbarBtn(Icons.link, 'Link', () {
                      _insertMarkdown('[', suffix: '](url)');
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _toolbarDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildCustomHeader(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
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
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isPreview
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () => setState(() => _isPreview = !_isPreview),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
            ),

            const SizedBox(width: 8),

            // Send to AI Hub button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.lan_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                onPressed: () {
                  final plainText = _contentController.text;
                  context.go('/widgets/ssh', extra: plainText);
                },
                tooltip: 'Send to AI Hub',
              ),
            ),

            const SizedBox(width: 8),

            // More options button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
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
