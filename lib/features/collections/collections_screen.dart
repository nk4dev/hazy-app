import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'collections_providers.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(collectionsProvider.notifier).create(name: name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCollection(context, ref),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: Icons.folder_outlined,
                title: 'No collections yet',
                subtitle: 'Group related saved links together.',
                action: FilledButton.icon(
                  onPressed: () => _createCollection(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('New collection'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final collection = value[index];
                    return Dismissible(
                      key: ValueKey(collection.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) =>
                          ref.read(collectionsProvider.notifier).delete(collection.id),
                      child: ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(collection.name),
                        subtitle: Text('${collection.itemCount} items'),
                        onTap: () => context.push('/library/collections/${collection.id}'),
                      ),
                    );
                  },
                ),
              ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.read(collectionsProvider.notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
