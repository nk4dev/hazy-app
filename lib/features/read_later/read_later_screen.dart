import 'package:flutter/material.dart'
    show
        Scaffold,
        AppBar,
        RefreshIndicator,
        ListView,
        PopupMenuButton,
        PopupMenuItem;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
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
    final s = AppStrings.of(context);
    return PopupMenuButton<ReadLaterStatus>(
      icon: const Icon(LucideIcons.ellipsisVertical),
      onSelected: (status) async {
        try {
          await ref.read(readLaterQueueProvider.notifier).setStatus(itemId, status);
        } catch (_) {
          if (context.mounted) {
            ShadToaster.of(context).show(
              ShadToast.destructive(description: Text(s.couldNotUpdateItem)),
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: ReadLaterStatus.read, child: Text(s.markAsRead)),
        PopupMenuItem(value: ReadLaterStatus.archived, child: Text(s.archive)),
        PopupMenuItem(value: ReadLaterStatus.inbox, child: Text(s.backToInbox)),
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
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: theme.textTheme.small),
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
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.readLaterTitle)),
      body: switch (state) {
        AsyncData(:final value) => value.totalCount == 0
            ? EmptyState(
                icon: LucideIcons.clock,
                title: s.emptyReadLaterTitle,
                subtitle: s.emptyReadLaterSubtitle,
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
                      s.todaysThree(value.todaysThreeMinutes),
                      value.todaysThree,
                    ),
                    _section(context, ref, s.fiveMinuteReads, value.fiveMinutes),
                    _section(context, ref, s.sitDownReads, value.sitDown),
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
