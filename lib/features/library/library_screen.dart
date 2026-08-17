import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        Dismissible,
        DismissDirection,
        RefreshIndicator,
        ListView,
        FloatingActionButton,
        CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
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
  Widget build(BuildContext context) {
    final state = ref.watch(libraryProvider);
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    final sortOptions = {'newest': s.sortNewest, 'oldest': s.sortOldest};

    return Scaffold(
      appBar: AppBar(
        title: Text(s.libraryTitle),
        actions: [
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
