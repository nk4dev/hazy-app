import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        Dismissible,
        DismissDirection,
        RefreshIndicator,
        ListView,
        FloatingActionButton,
        InkWell,
        AlwaysScrollableScrollPhysics;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
import '../../models/note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'notes_providers.dart';

/// Sentinel id for a note that hasn't been created server-side yet.
const newNoteId = 'new';

/// hazy note's notes, edited natively (see `NoteEditorScreen`).
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Future<bool?> _confirmDelete(BuildContext context) {
    final s = AppStrings.of(context);
    return showShadDialog<bool>(
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteListProvider);
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    void openNew() => context.push('/note/$newNoteId');

    return Scaffold(
      appBar: AppBar(title: Text(s.notesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: openNew,
        child: const Icon(LucideIcons.plus),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: LucideIcons.notebookPen,
                title: s.emptyNotesTitle,
                subtitle: s.emptyNotesSubtitle,
                action: ShadButton(
                  onPressed: openNew,
                  leading: const Icon(LucideIcons.plus),
                  child: Text(s.newNote),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(noteListProvider.notifier).refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const ShadSeparator.horizontal(
                    margin: EdgeInsets.zero,
                  ),
                  itemBuilder: (context, index) {
                    final note = value[index];
                    return Dismissible(
                      key: ValueKey(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: theme.colorScheme.destructive,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          LucideIcons.trash2,
                          color: theme.colorScheme.destructiveForeground,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) =>
                          ref.read(noteListProvider.notifier).delete(note.id),
                      child: _NoteRow(
                        note: note,
                        onTap: () => context.push('/note/${note.id}'),
                      ),
                    );
                  },
                ),
              ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.read(noteListProvider.notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    final preview = note.preview;
    final isDone = note.status == NoteStatus.done;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title.isEmpty ? s.untitledNote : note.title,
              style: theme.textTheme.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview,
                style: theme.textTheme.muted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isDone)
                  ShadBadge(child: Text(s.noteStatusDone))
                else
                  ShadBadge.outline(child: Text(s.noteStatusDraft)),
                for (final tag in note.tags.take(4))
                  ShadBadge.secondary(child: Text(tag.label)),
                Text(note.updatedLabel, style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.normal,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
