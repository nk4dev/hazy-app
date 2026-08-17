import 'package:flutter/material.dart'
    show Scaffold, AppBar, RefreshIndicator, ListView, Dismissible, DismissDirection;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
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
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.name ?? s.collectionFallbackTitle),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.items.isEmpty
            ? EmptyState(
                icon: LucideIcons.folderOpen,
                title: s.emptyCollectionItemsTitle,
                subtitle: s.emptyCollectionItemsSubtitle,
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
                        color: theme.colorScheme.destructive,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          LucideIcons.circleMinus,
                          color: theme.colorScheme.destructiveForeground,
                        ),
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
