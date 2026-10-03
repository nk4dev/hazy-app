import 'dart:async';

import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        Material,
        InkWell,
        TextField,
        InputDecoration,
        ListTile,
        showModalBottomSheet,
        Divider;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/note_api_client.dart';
import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../models/note.dart';
import '../../models/saved_url.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../library/library_providers.dart';
import 'notes_providers.dart';
import 'notes_screen.dart' show newNoteId;

enum _SaveState { idle, dirty, saving, saved, failed }

/// An `@token` at the caret — after a space or line start, so `foo@bar.com`
/// doesn't trigger the picker. Same rule as hazy note's web editor.
final _mentionTrigger = RegExp(r'(?:^|\s)@([^\s@\[\]]*)$');

class _Mention {
  const _Mention({required this.at, required this.query});

  /// Document index of the `@`.
  final int at;
  final String query;

  /// Characters to replace: the `@` plus the query.
  int get length => query.length + 1;
}

/// Native editor for one hazy note. Mirrors the web editor
/// (`apps/hazy-note/app/(app)/notes/[id]/note-client.tsx`): the body is a
/// Quill Delta edited in place, everything autosaves on a debounce, `@`
/// cites a saved URL (inserting a link and recording it as a source), and
/// AI suggestions can be taken into the body or dismissed.
///
/// `noteId == newNoteId` is a draft that is only created server-side once
/// something has been written.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  static const _saveDelay = Duration(milliseconds: 900);

  // Captured up front so a final save can still run from dispose(), where
  // `ref` is no longer usable.
  late final NoteApiClient _api = ref.read(noteApiClientProvider);
  late final NoteListNotifier _list = ref.read(noteListProvider.notifier);

  final _titleController = TextEditingController();
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();
  QuillController? _quill;
  StreamSubscription<DocChange>? _changes;

  String? _id;
  Object? _loadError;
  bool _loading = true;

  List<NoteTag> _tags = const [];
  NoteStatus _status = NoteStatus.draft;
  String _projectId = '';
  List<NoteSourceRef> _sources = const [];
  List<NoteSuggestion> _suggestions = const [];
  List<NoteFlag> _flags = const [];

  _SaveState _saveState = _SaveState.idle;
  Timer? _saveTimer;
  Future<void>? _saving;
  bool _saveAgain = false;
  bool _deleted = false;

  /// The note as it stood when the screen closed, for the final save —
  /// the controllers it is read from are disposed by then.
  Map<String, dynamic>? _finalPayload;

  _Mention? _mention;

  /// Bumped whenever sheet-visible state changes, so the open details
  /// sheet rebuilds.
  final _detailsRevision = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Leaving with unsaved edits: send them rather than drop them.
    if (_quill != null &&
        (_saveState == _SaveState.dirty || _saveState == _SaveState.failed)) {
      _finalPayload = _payload();
      unawaited(_save(notify: false));
    }
    _changes?.cancel();
    _quill?.removeListener(_onEditorChanged);
    _quill?.dispose();
    _titleController.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    _detailsRevision.dispose();
    super.dispose();
  }

  // ---- Loading -------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (widget.noteId == newNoteId) {
        _attach(null);
      } else {
        _attach(await _api.getNote(widget.noteId));
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Quill requires a document to end with a newline; bodies written by
  /// `PATCH {text}` or older notes may not.
  static Document _documentFrom(List<Map<String, dynamic>> ops) {
    if (ops.isEmpty) return Document();
    final normalized = [...ops];
    final last = normalized.last['insert'];
    if (last is! String || !last.endsWith('\n')) {
      normalized.add({'insert': '\n'});
    }
    try {
      return Document.fromJson(normalized);
    } catch (_) {
      // An op this editor can't represent: fall back to the plain text
      // rather than refusing to open the note.
      final text = ops.map((op) => op['insert']).whereType<String>().join();
      return Document()..insert(0, text);
    }
  }

  void _attach(Note? note) {
    if (!mounted) return;
    final quill = QuillController(
      document: note == null ? Document() : _documentFrom(note.body),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _id = note?.id;
    _titleController.text = note?.title ?? '';
    _tags = note?.tags ?? const [];
    _status = note?.status ?? NoteStatus.draft;
    _projectId = note?.projectId ?? '';
    _sources = note?.sources ?? const [];
    _suggestions = note?.suggestions ?? const [];
    _flags = note?.flags ?? const [];
    _quill = quill;
    _changes = quill.document.changes.listen((_) => _markDirty());
    quill.addListener(_onEditorChanged);
  }

  // ---- Saving --------------------------------------------------------

  bool get _hasContent {
    final quill = _quill;
    return _titleController.text.trim().isNotEmpty ||
        (quill != null && quill.document.toPlainText().trim().isNotEmpty);
  }

  void _markDirty() {
    if (!mounted || _deleted) return;
    // A brand-new note isn't created until there's something in it.
    if (_id == null && !_hasContent) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
    if (_saveState != _SaveState.dirty) {
      setState(() => _saveState = _SaveState.dirty);
    }
  }

  Map<String, dynamic> _payload() => {
        'title': _titleController.text,
        'body': _quill!.document.toDelta().toJson(),
        'suggestions': _suggestions.map((s) => s.toJson()).toList(),
        'tags': _tags.map((t) => t.toJson()).toList(),
        'status': _status.name,
        'sources': _sources.map((s) => s.toJson()).toList(),
        'projectId': _projectId,
      };

  /// Saves the whole note. Calls are serialized: one that arrives while a
  /// save is in flight is coalesced into a single follow-up save.
  Future<void> _save({bool notify = true}) {
    if (_deleted || _quill == null) return Future.value();
    if (_saving != null) {
      _saveAgain = true;
      return _saving!;
    }
    return _saving = _runSave(notify).whenComplete(() {
      _saving = null;
      if (_saveAgain) {
        _saveAgain = false;
        _save(notify: notify && mounted);
      }
    });
  }

  Future<void> _runSave(bool notify) async {
    _saveTimer?.cancel();
    final payload = _finalPayload ?? _payload();
    if (notify && mounted) setState(() => _saveState = _SaveState.saving);
    try {
      final id = _id;
      final saved = id == null
          ? await _api.createNote(payload)
          : await _api.updateNote(id, payload);
      _id = saved.id;
      _list.upsert(saved);
      if (notify && mounted) {
        setState(() {
          _flags = saved.flags;
          // Further edits made while this request was in flight keep the
          // note dirty; the pending timer will save them.
          if (_saveState == _SaveState.saving) _saveState = _SaveState.saved;
        });
      }
    } catch (_) {
      if (notify && mounted) setState(() => _saveState = _SaveState.failed);
    }
  }

  // ---- Edits ---------------------------------------------------------

  void _mutate(VoidCallback change) {
    setState(change);
    _detailsRevision.value++;
    _markDirty();
  }

  void _toggleStatus() => _mutate(() {
        _status =
            _status == NoteStatus.done ? NoteStatus.draft : NoteStatus.done;
      });

  void _addTag(String raw) {
    final label = raw.trim().replaceFirst(RegExp(r'^#'), '');
    if (label.isEmpty || _tags.any((t) => t.label == label)) return;
    _mutate(() => _tags = [..._tags, NoteTag(label: label)]);
  }

  void _removeTag(NoteTag tag) =>
      _mutate(() => _tags = _tags.where((t) => t.label != tag.label).toList());

  Future<void> _promptTag() async {
    final s = AppStrings.of(context);
    final controller = TextEditingController();
    final label = await showShadDialog<String>(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: Text(s.addTag),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          ShadButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(s.add),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShadInput(
            controller: controller,
            autofocus: true,
            placeholder: Text(s.tagPlaceholder),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
        ),
      ),
    );
    if (label != null) _addTag(label);
  }

  Future<void> _delete() async {
    final s = AppStrings.of(context);
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(s.deleteNoteConfirmTitle),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _saveTimer?.cancel();
    // Stops autosave from here on, so the note can't be written back after
    // it is deleted.
    _deleted = true;
    try {
      // A save still in flight lands first: a note that is only now being
      // created needs its id to be deleted at all.
      await _saving;
      final id = _id;
      if (id != null) await _list.delete(id);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      _deleted = false;
      if (_saveState == _SaveState.dirty) _markDirty();
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(e.message)),
        );
      }
    }
  }

  // ---- @ mention -----------------------------------------------------

  void _onEditorChanged() {
    final quill = _quill;
    if (quill == null || !mounted) return;
    _Mention? next;
    final selection = quill.selection;
    if (selection.isCollapsed && selection.baseOffset > 0) {
      final text = quill.document.toPlainText();
      final caret = selection.baseOffset.clamp(0, text.length);
      // Only the current line can hold the token.
      final lineStart = text.lastIndexOf('\n', caret - 1) + 1;
      final match = _mentionTrigger.firstMatch(text.substring(lineStart, caret));
      if (match != null) {
        final query = match.group(1)!;
        next = _Mention(at: caret - query.length - 1, query: query);
      }
    }
    if (next?.at != _mention?.at || next?.query != _mention?.query) {
      setState(() => _mention = next);
    }
  }

  List<SavedUrl> _mentionResults(List<SavedUrl> items) {
    final mention = _mention;
    if (mention == null) return const [];
    final q = mention.query.toLowerCase();
    return items
        .where(
          (i) =>
              q.isEmpty ||
              i.displayTitle.toLowerCase().contains(q) ||
              i.url.toLowerCase().contains(q),
        )
        .take(6)
        .toList();
  }

  void _pickMention(SavedUrl item) {
    final quill = _quill;
    final mention = _mention;
    if (quill == null || mention == null) return;
    final title = item.displayTitle;
    quill
      ..replaceText(
        mention.at,
        mention.length,
        title,
        TextSelection.collapsed(offset: mention.at + title.length),
      )
      ..formatText(mention.at, title.length, LinkAttribute(item.url))
      // Move past the link so what's typed next isn't part of it.
      ..replaceText(
        mention.at + title.length,
        0,
        ' ',
        TextSelection.collapsed(offset: mention.at + title.length + 1),
      )
      ..formatText(mention.at + title.length, 1, const LinkAttribute(null));
    _cite(label: title, url: item.url);
  }

  void _cite({required String label, required String url}) {
    if (_sources.any((s) => s.url == url || s.label == label)) return;
    final n = _sources.fold<int>(0, (max, s) => s.n > max ? s.n : max) + 1;
    _mutate(() {
      _sources = [
        ..._sources,
        NoteSourceRef(n: n, label: label, cited: true, url: url),
      ];
    });
  }

  // ---- Suggestions ---------------------------------------------------

  Future<void> _resolveSuggestion(NoteSuggestion suggestion, String action) async {
    final quill = _quill;
    if (quill == null) return;
    if (action == 'accept') {
      final length = quill.document.length;
      final offset = quill.selection.baseOffset;
      // At the caret if there is one, otherwise appended as a new paragraph.
      final index = offset >= 0 && offset < length ? offset : length - 1;
      final text = index == length - 1 && length > 1
          ? '\n${suggestion.text}'
          : suggestion.text;
      quill.replaceText(
        index,
        0,
        text,
        TextSelection.collapsed(offset: index + text.length),
      );
    }
    _mutate(() {
      _suggestions = _suggestions.where((s) => s.id != suggestion.id).toList();
    });
    final id = _id;
    if (id == null) return;
    try {
      final note = await _api.resolveSuggestion(id, suggestion.id, action);
      if (mounted) {
        setState(() => _flags = note.flags);
        _detailsRevision.value++;
      }
    } on ApiException {
      // The suggestion is already gone locally and the autosave carries
      // the same list, so there is nothing further to undo.
    }
  }

  void _showDetails() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => ValueListenableBuilder<int>(
        valueListenable: _detailsRevision,
        builder: (context, _, _) => _DetailsSheet(
          suggestions: _suggestions,
          sources: _sources,
          flags: _flags,
          onAccept: (s) {
            Navigator.of(sheetContext).pop();
            _resolveSuggestion(s, 'accept');
          },
          onDismiss: (s) => _resolveSuggestion(s, 'dismiss'),
        ),
      ),
    );
  }

  // ---- Build ---------------------------------------------------------

  String _saveLabel(AppStrings s) => switch (_saveState) {
        _SaveState.saving || _SaveState.dirty => s.noteSaving,
        _SaveState.saved => s.noteSaved,
        _SaveState.failed => s.noteSaveFailed,
        _SaveState.idle => _id == null ? s.noteUnsavedDraft : '',
      };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    final quill = _quill;

    if (_loading || quill == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _loadError != null
            ? ErrorView(error: _loadError!, onRetry: _load)
            : const LoadingView(),
      );
    }

    final isDone = _status == NoteStatus.done;
    final projects = ref.watch(noteProjectsProvider).value ?? const [];
    final libraryItems = ref.watch(libraryProvider).value?.items ?? const [];
    final mentionResults = _mentionResults(libraryItems);
    final detailCount = _suggestions.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          _saveLabel(s),
          style: theme.textTheme.small.copyWith(
            fontWeight: FontWeight.normal,
            color: _saveState == _SaveState.failed
                ? theme.colorScheme.destructive
                : theme.colorScheme.mutedForeground,
          ),
        ),
        actions: [
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: _toggleStatus,
            leading: Icon(
              isDone ? LucideIcons.circleCheck : LucideIcons.circleDashed,
              size: 16,
            ),
            child: Text(isDone ? s.noteStatusDone : s.noteStatusDraft),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              ShadIconButton.ghost(
                icon: const Icon(LucideIcons.sparkles),
                onPressed: _showDetails,
              ),
              if (detailCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$detailCount',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primaryForeground,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _delete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                controller: _titleController,
                onChanged: (_) => _markDirty(),
                style: theme.textTheme.h3,
                maxLines: null,
                decoration: InputDecoration.collapsed(
                  hintText: s.noteTitlePlaceholder,
                  hintStyle: theme.textTheme.h3.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tag in _tags)
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: ShadBadge.secondary(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag.label),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.x, size: 12),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _promptTag,
                    child: ShadBadge.outline(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus, size: 12),
                          const SizedBox(width: 4),
                          Text(s.addTag),
                        ],
                      ),
                    ),
                  ),
                  if (projects.isNotEmpty)
                    ShadSelect<String>(
                      key: ValueKey(_projectId),
                      minWidth: 140,
                      initialValue: _projectId,
                      options: [
                        ShadOption(value: '', child: Text(s.noProject)),
                        for (final p in projects)
                          ShadOption(value: p.id, child: Text(p.name)),
                      ],
                      selectedOptionBuilder: (context, value) => Text(
                        projects
                                .where((p) => p.id == value)
                                .map((p) => p.name)
                                .firstOrNull ??
                            s.noProject,
                      ),
                      onChanged: (value) {
                        if (value != null && value != _projectId) {
                          _mutate(() => _projectId = value);
                        }
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: QuillEditor(
                controller: quill,
                focusNode: _editorFocus,
                scrollController: _editorScroll,
                config: QuillEditorConfig(
                  placeholder: s.noteBodyPlaceholder,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  expands: true,
                  // Quill's default link colour comes from the Material
                  // scheme's secondary, which is near-white under ShadApp.
                  customStyles: DefaultStyles(
                    link: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onLaunchUrl: (url) => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ),
            if (mentionResults.isNotEmpty)
              _MentionPicker(items: mentionResults, onPick: _pickMention),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colorScheme.border)),
              ),
              child: QuillSimpleToolbar(
                controller: quill,
                config: const QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showDividers: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showUnderLineButton: false,
                  showStrikeThrough: false,
                  showInlineCode: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showListCheck: false,
                  showCodeBlock: false,
                  showIndent: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionPicker extends StatelessWidget {
  const _MentionPicker({required this.items, required this.onPick});

  final List<SavedUrl> items;
  final ValueChanged<SavedUrl> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Material(
      color: theme.colorScheme.popover,
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            for (final item in items)
              InkWell(
                onTap: () => onPick(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small,
                      ),
                      Text(
                        item.domain ?? item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({
    required this.suggestions,
    required this.sources,
    required this.flags,
    required this.onAccept,
    required this.onDismiss,
  });

  final List<NoteSuggestion> suggestions;
  final List<NoteSourceRef> sources;
  final List<NoteFlag> flags;
  final ValueChanged<NoteSuggestion> onAccept;
  final ValueChanged<NoteSuggestion> onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          for (final flag in flags)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(flag.text, style: theme.textTheme.muted),
            ),
          Text(s.suggestionsTitle, style: theme.textTheme.large),
          const SizedBox(height: 8),
          if (suggestions.isEmpty)
            Text(s.noSuggestions, style: theme.textTheme.muted),
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShadCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (suggestion.kind.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          suggestion.kind,
                          style: theme.textTheme.small.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    Text(suggestion.text, style: theme.textTheme.p),
                    if (suggestion.ref != null && suggestion.ref!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(suggestion.ref!, style: theme.textTheme.muted),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ShadButton(
                          size: ShadButtonSize.sm,
                          onPressed: () => onAccept(suggestion),
                          child: Text(s.suggestionAccept),
                        ),
                        const SizedBox(width: 8),
                        ShadButton.ghost(
                          size: ShadButtonSize.sm,
                          onPressed: () => onDismiss(suggestion),
                          child: Text(s.suggestionDismiss),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 32),
          Text(s.sourcesTitle, style: theme.textTheme.large),
          const SizedBox(height: 8),
          if (sources.isEmpty) Text(s.noSourcesYet, style: theme.textTheme.muted),
          for (final source in sources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Text('${source.n}', style: theme.textTheme.muted),
              title: Text(source.label, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: source.url == null
                  ? null
                  : Text(source.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: source.url == null
                  ? null
                  : () => launchUrl(
                        Uri.parse(source.url!),
                        mode: LaunchMode.externalApplication,
                      ),
            ),
        ],
      ),
    );
  }
}
