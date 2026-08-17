import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/saved_url.dart';

class LibraryState {
  const LibraryState({
    required this.items,
    required this.nextCursor,
    required this.sort,
    this.isLoadingMore = false,
  });

  final List<SavedUrl> items;
  final String? nextCursor;
  final String sort;
  final bool isLoadingMore;
}

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

class LibraryNotifier extends AsyncNotifier<LibraryState> {
  @override
  Future<LibraryState> build() async {
    final api = ref.watch(apiClientProvider);
    final page = await api.listItems(sort: 'newest');
    return LibraryState(
      items: page.items,
      nextCursor: page.nextCursor,
      sort: 'newest',
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<void> setSort(String sort) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      final page = await api.listItems(sort: sort);
      return LibraryState(
        items: page.items,
        nextCursor: page.nextCursor,
        sort: sort,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.nextCursor == null || current.isLoadingMore) {
      return;
    }
    state = AsyncValue.data(
      LibraryState(
        items: current.items,
        nextCursor: current.nextCursor,
        sort: current.sort,
        isLoadingMore: true,
      ),
    );
    try {
      final api = ref.read(apiClientProvider);
      final page = await api.listItems(
        cursor: current.nextCursor,
        sort: current.sort,
      );
      state = AsyncValue.data(
        LibraryState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          sort: current.sort,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(
        LibraryState(
          items: current.items,
          nextCursor: current.nextCursor,
          sort: current.sort,
        ),
      );
      rethrow;
    }
  }

  /// Idempotent per the brief (§6): a 200 (already saved) or 201 (new) both
  /// just resolve to the current [SavedUrl].
  Future<SavedUrl> save(String url) async {
    final api = ref.read(apiClientProvider);
    final saved = await api.saveUrl(url);
    final current = state.value;
    if (current != null && current.items.every((i) => i.id != saved.id)) {
      state = AsyncValue.data(
        LibraryState(
          items: [saved, ...current.items],
          nextCursor: current.nextCursor,
          sort: current.sort,
        ),
      );
    }
    return saved;
  }

  Future<void> deleteItem(String id) async {
    final api = ref.read(apiClientProvider);
    await api.deleteItem(id);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        LibraryState(
          items: current.items.where((i) => i.id != id).toList(),
          nextCursor: current.nextCursor,
          sort: current.sort,
        ),
      );
    }
  }
}
