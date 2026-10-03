import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        Dismissible,
        DismissDirection,
        RefreshIndicator,
        ListView,
        AlwaysScrollableScrollPhysics,
        FloatingActionButton,
        CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/api_exception.dart';
import '../../core/connectivity/offline_mode.dart';
import '../../core/localization/app_strings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/saved_url_card.dart';
import 'library_providers.dart';
import 'save_url_dialog.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// Syncs the local database with the server; the list stays on screen
  /// throughout, so a failure is reported as a toast rather than replacing
  /// the cached items with an error view.
  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(libraryProvider.notifier).sync();
    } on ApiException catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text(
              e.isNetworkError && OfflineMode.isOffline
                  ? AppStrings.of(context).offlineMessage
                  : e.message,
            ),
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final s = AppStrings.of(context);
    return showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(s.deleteItemConfirmTitle),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);
    final isSyncing = state.isLoading || (state.value?.isSyncing ?? false);
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    final sortOptions = {'newest': s.sortNewest, 'oldest': s.sortOldest};

    return Scaffold(
      appBar: AppBar(
        title: Text(s.libraryTitle),
        actions: [
          ShadIconButton.ghost(
            icon: isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw),
            onPressed: isSyncing ? null : () => _sync(context, ref),
          ),
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.folder),
            onPressed: () => context.push('/library/collections'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ShadSelect<String>(
              key: ValueKey(state.value?.sort),
              minWidth: 150,
              initialValue: state.value?.sort ?? 'newest',
              options: sortOptions.entries
                  .map((e) => ShadOption(value: e.key, child: Text(e.value)))
                  .toList(),
              selectedOptionBuilder: (context, value) =>
                  Text(sortOptions[value] ?? value),
              onChanged: (sort) {
                if (sort != null) {
                  ref.read(libraryProvider.notifier).setSort(sort);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSaveUrlDialog(context, ref),
        child: const Icon(LucideIcons.link),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.items.isEmpty
            ? EmptyState(
                icon: LucideIcons.bookmark,
                title: s.emptyLibraryTitle,
                subtitle: s.emptyLibrarySubtitle,
                action: ShadButton(
                  onPressed: () => showSaveUrlDialog(context, ref),
                  leading: const Icon(LucideIcons.link),
                  child: Text(s.saveALink),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _sync(context, ref),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                          LucideIcons.trash2,
                          color: theme.colorScheme.destructiveForeground,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
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
