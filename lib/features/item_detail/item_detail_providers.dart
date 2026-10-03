import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/clerk_token_provider.dart';
import '../../core/providers.dart';
import '../../models/saved_url.dart';
import '../library/library_providers.dart';

final itemDetailProvider =
    AsyncNotifierProvider.family<ItemDetailNotifier, SavedUrl, String>(
  (itemId) => ItemDetailNotifier(itemId),
);

class ItemDetailNotifier extends AsyncNotifier<SavedUrl> {
  ItemDetailNotifier(this.itemId);

  final String itemId;

  /// Keeps Library's local SQLite cache in step with edits made here.
  LibraryNotifier get _library => ref.read(libraryProvider.notifier);

  @override
  Future<SavedUrl> build() async {
    final api = ref.watch(apiClientProvider);
    try {
      return await api.getItem(itemId);
    } on ApiException catch (e) {
      // Offline: fall back to the copy in the local SQLite cache.
      if (!e.isNetworkError) rethrow;
      final cached = await ref
          .read(localDatabaseProvider)
          .savedUrl(ClerkAuthBridge.userId ?? '', itemId);
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<void> updateFields({String? title, String? summary}) async {
    final api = ref.read(apiClientProvider);
    final updated = await api.updateItem(itemId, title: title, summary: summary);
    state = AsyncValue.data(updated);
    await _library.upsertLocal(updated);
  }

  Future<void> refetch() async {
    final api = ref.read(apiClientProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.refetchItem(itemId));
    final refetched = state.value;
    if (refetched != null) await _library.upsertLocal(refetched);
  }

  Future<void> summarize() async {
    final api = ref.read(apiClientProvider);
    final updated = await api.summarizeItem(itemId);
    state = AsyncValue.data(updated);
    await _library.upsertLocal(updated);
  }

  Future<void> delete() async {
    final api = ref.read(apiClientProvider);
    await api.deleteItem(itemId);
    await _library.removeLocal(itemId);
  }
}
