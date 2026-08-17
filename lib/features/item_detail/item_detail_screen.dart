import 'package:flutter/material.dart' show Scaffold, AppBar, ListView, Image;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../core/localization/app_strings.dart';
import '../../models/saved_url.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../library/library_providers.dart';
import 'add_to_collection_sheet.dart';
import 'item_detail_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

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
    final state = ref.watch(itemDetailProvider(itemId));
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.itemAppBarTitle),
        actions: [
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.folderOpen),
            onPressed: () => showAddToCollectionSheet(context, ref, itemId),
          ),
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () async {
              final confirmed = await _confirmDelete(context);
              if (confirmed != true) return;
              await ref.read(itemDetailProvider(itemId).notifier).delete();
              ref.invalidate(libraryProvider);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => _ItemDetailBody(item: value, itemId: itemId),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(itemDetailProvider(itemId)),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _ItemDetailBody extends ConsumerWidget {
  const _ItemDetailBody({required this.item, required this.itemId});

  final SavedUrl item;
  final String itemId;

  Future<void> _editTitleAndSummary(BuildContext context, WidgetRef ref) async {
    final s = AppStrings.of(context);
    final titleController = TextEditingController(text: item.title ?? '');
    final summaryController = TextEditingController(text: item.summary ?? '');
    final saved = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(s.editDialogTitle),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ShadButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.save),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadInput(
                controller: titleController,
                placeholder: Text(s.titleFieldPlaceholder),
              ),
              const SizedBox(height: 12),
              ShadTextarea(
                controller: summaryController,
                placeholder: Text(s.summaryFieldPlaceholder),
                minHeight: 100,
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    await ref.read(itemDetailProvider(itemId).notifier).updateFields(
          title: titleController.text.trim(),
          summary: summaryController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (item.ogImageUrl != null)
          ClipRRect(
            borderRadius: theme.radius,
            child: Image.network(item.ogImageUrl!, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const SizedBox(height: 12),
        Text(item.displayTitle, style: theme.textTheme.h3),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
          child: Text(
            item.url,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (item.domain != null) ShadBadge.secondary(child: Text(item.domain!)),
            if (item.estimatedReadMinutes != null)
              ShadBadge.secondary(child: Text(s.minRead(item.estimatedReadMinutes!))),
            ShadBadge.secondary(child: Text(item.fetchStatus.name)),
          ],
        ),
        const SizedBox(height: 16),
        if (item.fetchStatus == FetchStatus.error) ...[
          ShadCard(
            backgroundColor: theme.colorScheme.destructive.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.fetchError ?? s.failedToFetchPage),
                const SizedBox(height: 8),
                ShadButton.outline(
                  onPressed: () =>
                      ref.read(itemDetailProvider(itemId).notifier).refetch(),
                  leading: const Icon(LucideIcons.refreshCw),
                  child: Text(s.retry),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (item.description != null) ...[
          Text(s.descriptionLabel, style: theme.textTheme.small),
          const SizedBox(height: 4),
          Text(item.description!, style: theme.textTheme.p),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.summaryLabel, style: theme.textTheme.small),
            ShadButton.ghost(
              onPressed: () async {
                try {
                  await ref.read(itemDetailProvider(itemId).notifier).summarize();
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        description: Text(
                          e.isServiceNotConfigured
                              ? s.aiSummaryUnavailable
                              : e.message,
                        ),
                      ),
                    );
                  }
                }
              },
              leading: const Icon(LucideIcons.sparkles),
              child: Text(item.summary == null ? s.generate : s.regenerate),
            ),
          ],
        ),
        Text(item.summary ?? s.noSummaryYet, style: theme.textTheme.p),
        const SizedBox(height: 24),
        ShadButton.outline(
          onPressed: () => _editTitleAndSummary(context, ref),
          leading: const Icon(LucideIcons.pencil),
          child: Text(s.editTitleSummary),
        ),
      ],
    );
  }
}
