import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/clerk_token_provider.dart';
import '../../core/providers.dart';
import '../../models/saved_url.dart';

class LibraryState {
  const LibraryState({
    required this.items,
    required this.sort,
    this.isSyncing = false,
  });

  final List<SavedUrl> items;
  final String sort;

  /// True while a sync with `GET /items` is in flight on top of
  /// already-displayed local data.
  final bool isSyncing;

  LibraryState copyWith({List<SavedUrl>? items, String? sort, bool? isSyncing}) {
    return LibraryState(
      items: items ?? this.items,
      sort: sort ?? this.sort,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

final libraryProvider =
    AsyncNotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);

/// Library is served from the local SQLite cache
/// (`lib/core/db/local_database.dart`) and reconciled with the server by
/// [sync] — automatically when the app opens, and on demand from the
/// reload button / pull-to-refresh.
class LibraryNotifier extends AsyncNotifier<LibraryState> {
  String get _userId => ClerkAuthBridge.userId ?? '';

  @override
  Future<LibraryState> build() async {
    final db = ref.watch(localDatabaseProvider);
    final cached = await db.savedUrls(_userId);
    if (cached.isEmpty) {
      // Nothing cached yet (first launch, fresh install, or a genuinely
      // empty library): wait for the server so the user sees a loading
      // state rather than a misleading "nothing saved" screen.
      await _pullRemote();
      return LibraryState(items: await db.savedUrls(_userId), sort: 'newest');
    }
    // Show cached items immediately, then sync behind them. A failure here
    // (e.g. offline) is silent — the cached library is still usable and the
    // reload button surfaces the error if the user retries.
    unawaited(Future(() => sync().catchError((_) {})));
    return LibraryState(items: cached, sort: 'newest');
  }

  /// Fetches every page of `GET /items` and replaces the local cache with it.
  Future<void> _pullRemote() async {
    final api = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final userId = _userId;
    final all = <SavedUrl>[];
    String? cursor;
    do {
      final page = await api.listItems(cursor: cursor, limit: 100);
      all.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    await db.replaceSavedUrls(userId, all);
  }

  Future<void> _reloadFromLocal({bool? isSyncing}) async {
    final current = state.value;
    if (current == null) return;
    final items = await ref
        .read(localDatabaseProvider)
        .savedUrls(_userId, sort: current.sort);
    final latest = state.value ?? current;
    state = AsyncValue.data(
      latest.copyWith(items: items, isSyncing: isSyncing),
    );
  }

  /// Pulls the latest saved items from the server into the local database
  /// while keeping the current list on screen. Throws on failure (leaving
  /// the cached items in place) so callers can surface it.
  Future<void> sync() async {
    final current = state.value;
    if (current == null) {
      // No local data on screen yet (initial load or error) — rebuild.
      return refresh();
    }
    if (current.isSyncing) return;
    state = AsyncValue.data(current.copyWith(isSyncing: true));
    try {
      await _pullRemote();
      await _reloadFromLocal(isSyncing: false);
    } catch (_) {
      final latest = state.value;
      if (latest != null) {
        state = AsyncValue.data(latest.copyWith(isSyncing: false));
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<void> setSort(String sort) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(sort: sort));
    await _reloadFromLocal();
  }

  /// Idempotent per the brief (§6): a 200 (already saved) or 201 (new) both
  /// just resolve to the current [SavedUrl].
  Future<SavedUrl> save(String url) async {
    final api = ref.read(apiClientProvider);
    final saved = await api.saveUrl(url);
    await upsertLocal(saved);
    return saved;
  }

  Future<void> deleteItem(String id) async {
    final api = ref.read(apiClientProvider);
    await api.deleteItem(id);
    await removeLocal(id);
  }

  /// Mirrors an item the API just returned (save, edit, refetch, summarize)
  /// into the local database and the on-screen list.
  Future<void> upsertLocal(SavedUrl item) async {
    await ref.read(localDatabaseProvider).upsertSavedUrl(_userId, item);
    await _reloadFromLocal();
  }

  /// Drops an item the API just deleted from the local database and list.
  Future<void> removeLocal(String id) async {
    await ref.read(localDatabaseProvider).deleteSavedUrl(_userId, id);
    await _reloadFromLocal();
  }
}
