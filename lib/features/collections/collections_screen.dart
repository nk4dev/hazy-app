import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        FloatingActionButton,
        RefreshIndicator,
        ListView,
        Dismissible,
        DismissDirection,
        ListTile;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'collections_providers.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final s = AppStrings.of(context);
    final nameController = TextEditingController();
    final name = await showShadDialog<String>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(s.newCollection),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: Text(s.create),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShadInput(
            controller: nameController,
            autofocus: true,
            placeholder: Text(s.nameFieldPlaceholder),
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(collectionsProvider.notifier).create(name: name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionsProvider);
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.collectionsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCollection(context, ref),
        child: const Icon(LucideIcons.folderPlus),
      ),
      body: switch (state) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(
                icon: LucideIcons.folder,
                title: s.emptyCollectionsTitle,
                subtitle: s.emptyCollectionsSubtitle,
                action: ShadButton(
                  onPressed: () => _createCollection(context, ref),
                  leading: const Icon(LucideIcons.folderPlus),
                  child: Text(s.newCollection),
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
                        color: theme.colorScheme.destructive,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          LucideIcons.trash2,
                          color: theme.colorScheme.destructiveForeground,
                        ),
                      ),
                      onDismissed: (_) =>
                          ref.read(collectionsProvider.notifier).delete(collection.id),
                      child: ListTile(
                        leading: const Icon(LucideIcons.folder),
                        title: Text(collection.name),
                        subtitle: Text(s.itemsCount(collection.itemCount)),
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
