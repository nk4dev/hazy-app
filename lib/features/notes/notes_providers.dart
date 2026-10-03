import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../models/note.dart';

final noteListProvider =
    AsyncNotifierProvider<NoteListNotifier, List<Note>>(NoteListNotifier.new);

class NoteListNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    return ref.watch(noteApiClientProvider).listNotes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// Reflects a note the editor just saved, newest first like the server.
  void upsert(Note note) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data([
      note,
      ...current.where((n) => n.id != note.id),
    ]);
  }

  /// Removes the note from the list straight away (a swiped-away row must
  /// leave the tree at once) and puts it back if the server refuses.
  Future<void> delete(String id) async {
    final previous = state.value;
    if (previous != null) {
      state = AsyncValue.data(previous.where((n) => n.id != id).toList());
    }
    try {
      await ref.read(noteApiClientProvider).deleteNote(id);
    } on ApiException catch (e) {
      // Already gone server-side: the list is right as it is.
      if (e.isNotFound) return;
      if (previous != null) state = AsyncValue.data(previous);
      rethrow;
    }
  }
}

final noteProjectsProvider = FutureProvider<List<NoteProject>>((ref) {
  return ref.watch(noteApiClientProvider).listProjects();
});
