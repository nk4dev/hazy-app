import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> delete(String id) async {
    await ref.read(noteApiClientProvider).deleteNote(id);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.where((n) => n.id != id).toList());
    }
  }
}

final noteProjectsProvider = FutureProvider<List<NoteProject>>((ref) {
  return ref.watch(noteApiClientProvider).listProjects();
});
