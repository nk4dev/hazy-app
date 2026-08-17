import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/saved_url.dart';

final itemDetailProvider =
    AsyncNotifierProvider.family<ItemDetailNotifier, SavedUrl, String>(
  (itemId) => ItemDetailNotifier(itemId),
);

class ItemDetailNotifier extends AsyncNotifier<SavedUrl> {
  ItemDetailNotifier(this.itemId);

  final String itemId;

  @override
  Future<SavedUrl> build() async {
    final api = ref.watch(apiClientProvider);
    return api.getItem(itemId);
  }

  Future<void> updateFields({String? title, String? summary}) async {
    final api = ref.read(apiClientProvider);
    final updated = await api.updateItem(itemId, title: title, summary: summary);
    state = AsyncValue.data(updated);
  }

  Future<void> refetch() async {
    final api = ref.read(apiClientProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.refetchItem(itemId));
  }

  Future<void> summarize() async {
    final api = ref.read(apiClientProvider);
    final updated = await api.summarizeItem(itemId);
    state = AsyncValue.data(updated);
  }

  Future<void> delete() async {
    final api = ref.read(apiClientProvider);
    await api.deleteItem(itemId);
  }
}
