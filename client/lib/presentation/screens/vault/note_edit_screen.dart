import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/vault_note_model.dart';
import '../../providers/vault_provider.dart';
import 'widgets/code_snippet_card.dart';

/// Screen for creating or updating a Knowledge Vault note (UC-121, UC-122, UC-124)
class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagInputController = TextEditingController();

  bool _isMistakeSolution = false;
  List<String> _tags = [];
  List<CodeSnippet> _snippets = [];
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadExistingNote();
    } else {
      _isLoaded = true;
    }
  }

  Future<void> _loadExistingNote() async {
    final note = await ref.read(vaultProvider.notifier).getNoteById(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _titleController.text = note.title;
        _contentController.text = note.content;
        _isMistakeSolution = note.isMistakeSolution;
        _tags = List.from(note.tags);
        _snippets = List.from(note.codeSnippets);
        _isLoaded = true;
      });
    } else if (mounted) {
      setState(() => _isLoaded = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputController.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _showAddSnippetDialog([CodeSnippet? initialSnippet, int? index]) {
    final langController = TextEditingController(text: initialSnippet?.language ?? 'typescript');
    final descController = TextEditingController(text: initialSnippet?.description ?? '');
    final codeController = TextEditingController(text: initialSnippet?.code ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initialSnippet == null ? 'Add Code Snippet' : 'Edit Code Snippet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: langController,
                decoration: const InputDecoration(
                  labelText: 'Language (e.g. typescript, python, sql, dart)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                maxLines: 8,
                style: GoogleFonts.firaCode(fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Code Body',
                  hintText: 'Paste or type code snippet here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                final newSnippet = CodeSnippet(
                  language: langController.text.trim().toLowerCase(),
                  description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                  code: code,
                );
                setState(() {
                  if (index != null) {
                    _snippets[index] = newSnippet;
                  } else {
                    _snippets.add(newSnippet);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Snippet'),
          ),
        ],
      ),
    );
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(vaultProvider.notifier);

    if (widget.noteId == null) {
      // Create Note
      final newNote = await notifier.createNote(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        codeSnippets: _snippets,
        isMistakeSolution: _isMistakeSolution,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (newNote != null) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note captured in Knowledge Vault')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save note')),
          );
        }
      }
    } else {
      // Update Note
      final success = await notifier.updateNote(
        widget.noteId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        codeSnippets: _snippets,
        isMistakeSolution: _isMistakeSolution,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ref.invalidate(singleVaultNoteProvider(widget.noteId!));
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update note')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;

    if (!_isLoaded) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(backgroundColor: colorScheme.surface),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          widget.noteId == null ? 'Create Note' : 'Edit Note',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          children: [
            // Title Input
            TextFormField(
              controller: _titleController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                hintText: 'Note Title...',
                border: InputBorder.none,
              ),
            ),
            const Divider(),

            // Mistake / Solution Toggle (UC-123)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isMistakeSolution ? Colors.amber.shade700.withAlpha(20) : colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _isMistakeSolution ? Colors.amber.shade700.withAlpha(60) : colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 20,
                    color: _isMistakeSolution ? Colors.amber.shade700 : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mistake & Solution Log',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _isMistakeSolution ? Colors.amber.shade700 : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Tag as a solved bug or debugging breakthrough (UC-123)',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isMistakeSolution,
                    activeColor: Colors.amber.shade700,
                    onChanged: (val) => setState(() => _isMistakeSolution = val),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGapMd,

            // Tags Editor
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    onSubmitted: (_) => _addTag(),
                    decoration: InputDecoration(
                      hintText: 'Add tag (e.g. redis, distributed, math)...',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        onPressed: _addTag,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in _tags)
                    Chip(
                      label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => _removeTag(tag),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ],
            AppSpacing.verticalGapMd,

            // Markdown Formatting Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(isDark ? 80 : 40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Text('H1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _insertMarkdown('# '),
                      tooltip: 'Heading 1',
                    ),
                    IconButton(
                      icon: const Text('H2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _insertMarkdown('## '),
                      tooltip: 'Heading 2',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_bold_rounded, size: 18),
                      onPressed: () => _insertMarkdown('**', '**'),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                      onPressed: () => _insertMarkdown('- '),
                      tooltip: 'Bullet List',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_quote_rounded, size: 18),
                      onPressed: () => _insertMarkdown('> '),
                      tooltip: 'Quote',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code_rounded, size: 18),
                      onPressed: () => _insertMarkdown('`', '`'),
                      tooltip: 'Inline Code',
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_rounded, size: 18),
                      onPressed: () => _insertMarkdown('[[', ']]'),
                      tooltip: 'Wiki Note Link',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Content Text Editor
            TextFormField(
              controller: _contentController,
              maxLines: 12,
              style: const TextStyle(fontSize: 14, height: 1.45),
              decoration: InputDecoration(
                hintText: 'Write in Markdown: headers, lists, code fences...\nUse [[Note Title]] to link other notes.',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(120), fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            AppSpacing.verticalGapLg,

            // Code Snippets Section (UC-124)
            Row(
              children: [
                Icon(Icons.terminal_rounded, size: 18, color: primary),
                const SizedBox(width: 8),
                const Text(
                  'CODE SNIPPETS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddSnippetDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Snippet', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_snippets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.code_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'No code snippets added yet.',
                      style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (int i = 0; i < _snippets.length; i++)
                CodeSnippetCard(
                  snippet: _snippets[i],
                  onDelete: () => setState(() => _snippets.removeAt(i)),
                ),
          ],
        ),
      ),
    );
  }
}
