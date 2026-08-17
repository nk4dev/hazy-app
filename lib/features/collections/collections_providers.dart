import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/collection.dart';

final collectionsProvider =
    AsyncNotifierProvider<CollectionsNotifier, List<Collection>>(
  CollectionsNotifier.new,
);

class CollectionsNotifier extends AsyncNotifier<List<Collection>> {
  @override
  Future<List<Collection>> build() {
    final api = ref.watch(apiClientProvider);
    return api.listCollections();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<Collection> create({
    required String name,
    String? description,
    String? color,
  }) async {
    final api = ref.read(apiClientProvider);
    final created = await api.createCollection(
      name: name,
      description: description,
      color: color,
    );
    final current = state.value ?? const [];
    state = AsyncValue.data([created, ...current]);
    return created;
  }

  Future<void> delete(String id) async {
    final api = ref.read(apiClientProvider);
    await api.deleteCollection(id);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.where((c) => c.id != id).toList());
    }
  }
}

final collectionDetailProvider = AsyncNotifierProvider.family<
    CollectionDetailNotifier, CollectionDetail, String>(
  (id) => CollectionDetailNotifier(id),
);

class CollectionDetailNotifier extends AsyncNotifier<CollectionDetail> {
  CollectionDetailNotifier(this.collectionId);

  final String collectionId;

  @override
  Future<CollectionDetail> build() {
    final api = ref.watch(apiClientProvider);
    return api.getCollection(collectionId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<void> removeItem(String savedUrlId) async {
    final api = ref.read(apiClientProvider);
    await api.removeItemFromCollection(collectionId, savedUrlId);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        CollectionDetail(
          id: current.id,
          name: current.name,
          description: current.description,
          color: current.color,
          items: current.items.where((i) => i.id != savedUrlId).toList(),
        ),
      );
    }
  }

  Future<void> rename({String? name, String? description, String? color}) async {
    final api = ref.read(apiClientProvider);
    await api.updateCollection(
      collectionId,
      name: name,
      description: description,
      color: color,
    );
    await refresh();
  }
}
