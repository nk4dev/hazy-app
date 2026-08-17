import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/saved_url_card.dart';
import 'library_providers.dart';
import 'save_url_dialog.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(libraryProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Collections',
            onPressed: () => context.push('/library/collections'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) =>
                ref.read(libraryProvider.notifier).setSort(sort),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest first')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSaveUrlDialog(context, ref),
        child: const Icon(Icons.add_link),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.items.isEmpty
            ? EmptyState(
                icon: Icons.bookmark_border,
                title: 'Nothing saved yet',
                subtitle: 'Tap + to save your first link.',
                action: FilledButton.icon(
                  onPressed: () => showSaveUrlDialog(context, ref),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Save a link'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: value.items.length + (value.nextCursor != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= value.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = value.items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete this item?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) =>
                          ref.read(libraryProvider.notifier).deleteItem(item.id),
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
            onRetry: () => ref.read(libraryProvider.notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
