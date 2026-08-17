import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/localization/app_strings.dart';
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
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.statsLine(stats.readThisWeek, stats.savedThisWeek),
            style: theme.textTheme.small,
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
    );
  }
}
