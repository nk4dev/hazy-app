import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/read_later.dart';
import 'read_later_providers.dart';

class ReadLaterStatsChart extends ConsumerWidget {
  const ReadLaterStatsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(readLaterStatsProvider);
    return statsAsync.when(
      data: (stats) => _Chart(stats: stats),
      loading: () => const SizedBox(height: 96),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.stats});

  final ReadLaterStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${stats.readThisWeek} read · ${stats.savedThisWeek} saved this week',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in stats.days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Tooltip(
                          message: '${day.count}',
                          child: FractionallySizedBox(
                            heightFactor: (day.heightPct / 100).clamp(0.03, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
