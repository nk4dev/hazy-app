import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_exception.dart';
import '../../models/saved_url.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../library/library_providers.dart';
import 'add_to_collection_sheet.dart';
import 'item_detail_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemDetailProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Add to collection',
            onPressed: () => showAddToCollectionSheet(context, ref, itemId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
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
              );
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
    final titleController = TextEditingController(text: item.title ?? '');
    final summaryController = TextEditingController(text: item.summary ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: summaryController,
              decoration: const InputDecoration(labelText: 'Summary'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
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
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (item.ogImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(item.ogImageUrl!, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const SizedBox(height: 12),
        Text(item.displayTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
          child: Text(
            item.url,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (item.domain != null) Chip(label: Text(item.domain!)),
            if (item.estimatedReadMinutes != null)
              Chip(label: Text('${item.estimatedReadMinutes} min read')),
            Chip(label: Text(item.fetchStatus.name)),
          ],
        ),
        const SizedBox(height: 16),
        if (item.fetchStatus == FetchStatus.error) ...[
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.fetchError ?? 'Failed to fetch this page.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(itemDetailProvider(itemId).notifier).refetch(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (item.description != null) ...[
          Text('Description', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(item.description!),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Summary', style: theme.textTheme.labelLarge),
            TextButton.icon(
              onPressed: () async {
                try {
                  await ref.read(itemDetailProvider(itemId).notifier).summarize();
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.isServiceNotConfigured
                              ? 'AI summaries aren\'t available right now.'
                              : e.message,
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(item.summary == null ? 'Generate' : 'Regenerate'),
            ),
          ],
        ),
        Text(item.summary ?? 'No summary yet.'),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _editTitleAndSummary(context, ref),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit title / summary'),
        ),
      ],
    );
  }
}
