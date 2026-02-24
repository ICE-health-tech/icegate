import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:intl/intl.dart';

class TextEditorPage extends StatefulWidget {
  final ProjectNoteData? note;

  const TextEditorPage({super.key, this.note});

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage>
    with SingleTickerProviderStateMixin {
  late final QuillController _controller;
  late final TextEditingController _titleController;
  late final FocusNode _editorFocusNode;
  late final FocusNode _titleFocusNode;

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _focusMode = false;
  bool _showToolbar = false;
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

    if (widget.note != null) {
      try {
        final json = jsonDecode(widget.note!.content);
        _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
    }

    // Listen for changes
    _controller.document.changes.listen((_) {
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
    _controller.dispose();
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
    final content = jsonEncode(_controller.document.toDelta().toJson());

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
        await context.read<ProjectNoteDAO>().insertNote(
          title: title,
          content: content,
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
    final plainText = _controller.document.toPlainText().trim();
    final wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).length;
    final charCount = plainText.length;
    final lineCount = _controller.document.toPlainText().split('\n').length;
    final readTime = (wordCount / 200).ceil(); // ~200 wpm

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
                label: 'Copy as Plain Text',
                color: Colors.teal,
                onTap: () async {
                  Navigator.pop(ctx);
                  final text = _controller.document.toPlainText();
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  // Copy to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                        widget.note!.noteID!,
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
            // Background
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

                // Editor
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: _toggleFocusMode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
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

                          // Editor
                          Expanded(
                            child: QuillEditor.basic(
                              controller: _controller,
                              focusNode: _editorFocusNode,
                              config: QuillEditorConfig(
                                placeholder: 'Start writing...',
                                padding: const EdgeInsets.only(bottom: 120),
                                customStyles: DefaultStyles(
                                  paragraph: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontSize: 16,
                                      height: 1.7,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.85,
                                      ),
                                    ),
                                    const HorizontalSpacing(0, 0),
                                    const VerticalSpacing(6, 0),
                                    const VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h1: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.3,
                                      color: colorScheme.onSurface,
                                    ),
                                    const HorizontalSpacing(0, 0),
                                    const VerticalSpacing(16, 8),
                                    const VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h2: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                      color: colorScheme.onSurface,
                                    ),
                                    const HorizontalSpacing(0, 0),
                                    const VerticalSpacing(12, 6),
                                    const VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h3: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.9,
                                      ),
                                    ),
                                    const HorizontalSpacing(0, 0),
                                    const VerticalSpacing(10, 4),
                                    const VerticalSpacing(0, 0),
                                    null,
                                  ),
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
            ),

            // Floating Toolbar — toggled by MainButton
            if (!_focusMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: _showToolbar ? 90 : -80,
                left: 24,
                right: 24,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.7),
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
                        child: QuillSimpleToolbar(
                          controller: _controller,
                          config: const QuillSimpleToolbarConfig(
                            showFontFamily: false,
                            showFontSize: false,
                            showSearchButton: false,
                            showSubscript: false,
                            showSuperscript: false,
                            showInlineCode: false,
                            showColorButton: false,
                            showBackgroundColorButton: false,
                            showClearFormat: false,
                            showAlignmentButtons: false,
                            showDirection: false,
                            showIndent: false,
                            multiRowsDisplay: false,
                            toolbarIconAlignment: WrapAlignment.center,
                            buttonOptions: QuillSimpleToolbarButtonOptions(
                              base: QuillToolbarBaseButtonOptions(
                                iconTheme: QuillIconTheme(
                                  iconButtonSelectedData: IconButtonData(
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                        Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // MainButton to toggle toolbar
            if (!_focusMode)
              Positioned(
                bottom: 24,
                right: 0,
                left: 0,
                child: Center(
                  child: MainButton(
                    type: 'editor',
                    destination: '/projects/editor',
                    size: 48,
                    icon: _showToolbar
                        ? Icons.close_rounded
                        : Icons.edit_rounded,
                    mainFunction: () {
                      setState(() => _showToolbar = !_showToolbar);
                    },
                    subButtons: [
                      SubButton(
                        icon: Icons.save_rounded,
                        backgroundColor: Colors.green,
                        tooltip: 'Save',
                        onPressed: _saveNote,
                      ),
                      SubButton(
                        icon: Icons.bar_chart_rounded,
                        backgroundColor: Colors.blueAccent,
                        tooltip: 'Statistics',
                        onPressed: _showStats,
                      ),
                      if (widget.note != null)
                        SubButton(
                          icon: Icons.delete_outline_rounded,
                          backgroundColor: Colors.redAccent,
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Note?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
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
                                widget.note!.noteID!,
                              );
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),

            // Focus mode exit hint
            if (_focusMode)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleFocusMode,
                    child: AnimatedOpacity(
                      opacity: 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Double-tap to exit focus mode',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: colorScheme.onSurface,
                size: 18,
              ),
              onPressed: () {
                if (_hasUnsavedChanges) {
                  // WillPopScope handles it
                  Navigator.maybePop(context);
                } else {
                  Navigator.pop(context);
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                padding: const EdgeInsets.all(12),
              ),
            ),

            // Actions
            Row(
              children: [
                // Save status indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _hasUnsavedChanges
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSaving
                            ? Icons.sync_rounded
                            : _hasUnsavedChanges
                            ? Icons.edit_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: _hasUnsavedChanges
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSaving
                            ? 'Saving'
                            : _hasUnsavedChanges
                            ? 'Edited'
                            : 'Saved',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _hasUnsavedChanges
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Save button
                IconButton(
                  icon: Icon(
                    Icons.save_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: _saveNote,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer.withOpacity(
                      0.5,
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 6),
                // More options
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                  onPressed: _showMoreOptions,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
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
