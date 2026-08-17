import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/read_later.dart';
import '../../models/saved_url.dart';

final readLaterQueueProvider =
    AsyncNotifierProvider<ReadLaterQueueNotifier, ReadLaterQueue>(
  ReadLaterQueueNotifier.new,
);

class ReadLaterQueueNotifier extends AsyncNotifier<ReadLaterQueue> {
  @override
  Future<ReadLaterQueue> build() {
    final api = ref.watch(apiClientProvider);
    return api.getReadLaterQueue();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// Optimistically drops [itemId] from all buckets, then persists the
  /// status change — errors trigger a full [refresh] to resync.
  Future<void> setStatus(
    String itemId,
    ReadLaterStatus status, {
    DateTime? snoozedUntil,
  }) async {
    final current = state.value;
    if (current != null) {
      List<SavedUrl> without(List<SavedUrl> items) =>
          items.where((i) => i.id != itemId).toList();
      state = AsyncValue.data(
        ReadLaterQueue(
          totalCount: current.totalCount,
          totalMinutes: current.totalMinutes,
          todaysThreeMinutes: current.todaysThreeMinutes,
          todaysThree: without(current.todaysThree),
          fiveMinutes: without(current.fiveMinutes),
          sitDown: without(current.sitDown),
        ),
      );
    }
    final api = ref.read(apiClientProvider);
    try {
      await api.updateReadLaterStatus(
        itemId,
        status: status,
        snoozedUntil: snoozedUntil,
      );
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

final readLaterStatsProvider = FutureProvider.autoDispose((ref) {
  final api = ref.watch(apiClientProvider);
  return api.getReadLaterStats();
});
