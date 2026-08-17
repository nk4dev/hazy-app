import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/saved_url.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/saved_url_card.dart';
import 'read_later_providers.dart';
import 'read_later_stats_chart.dart';

class ReadLaterScreen extends ConsumerWidget {
  const ReadLaterScreen({super.key});

  Widget _statusMenu(BuildContext context, WidgetRef ref, String itemId) {
    return PopupMenuButton<ReadLaterStatus>(
      icon: const Icon(Icons.more_vert),
      onSelected: (status) async {
        try {
          await ref.read(readLaterQueueProvider.notifier).setStatus(itemId, status);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not update this item.')),
            );
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: ReadLaterStatus.read, child: Text('Mark as read')),
        PopupMenuItem(value: ReadLaterStatus.archived, child: Text('Archive')),
        PopupMenuItem(value: ReadLaterStatus.inbox, child: Text('Back to inbox')),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<SavedUrl> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        for (final item in items)
          SavedUrlCard(
            item: item,
            trailing: _statusMenu(context, ref, item.id),
            onTap: () => context.push('/library/item/${item.id}'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readLaterQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Read later')),
      body: switch (state) {
        AsyncData(:final value) => value.totalCount == 0
            ? const EmptyState(
                icon: Icons.schedule_outlined,
                title: 'Your read-later queue is empty',
                subtitle: 'Saved items in your inbox show up here.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(readLaterQueueProvider.notifier).refresh(),
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: ReadLaterStatsChart(),
                    ),
                    _section(
                      context,
                      ref,
                      "Today's 3 (~${value.todaysThreeMinutes} min)",
                      value.todaysThree,
                    ),
                    _section(context, ref, '5-minute reads', value.fiveMinutes),
                    _section(context, ref, 'Sit-down reads', value.sitDown),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.read(readLaterQueueProvider.notifier).refresh(),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
