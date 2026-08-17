import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/saved_url_card.dart';
import 'collections_providers.dart';

class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionDetailProvider(collectionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.name ?? 'Collection'),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.items.isEmpty
            ? const EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No items in this collection yet',
                subtitle: 'Add items from any saved link\'s detail screen.',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(collectionDetailProvider(collectionId).notifier).refresh(),
                child: ListView.builder(
                  itemCount: value.items.length,
                  itemBuilder: (context, index) {
                    final item = value.items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.remove_circle_outline),
                      ),
                      onDismissed: (_) => ref
                          .read(collectionDetailProvider(collectionId).notifier)
                          .removeItem(item.id),
                      child: SavedUrlCard(
                        item: item,
                        onTap: () => context.push('/library/item/${item.id}'),
                      ),
                    );
                  },
                ),
              ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () =>
                ref.read(collectionDetailProvider(collectionId).notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
