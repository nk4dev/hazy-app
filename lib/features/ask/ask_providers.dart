import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/ask.dart';

final askThreadListProvider =
    AsyncNotifierProvider<AskThreadListNotifier, List<AskThread>>(
  AskThreadListNotifier.new,
);

class AskThreadListNotifier extends AsyncNotifier<List<AskThread>> {
  @override
  Future<List<AskThread>> build() {
    final api = ref.watch(apiClientProvider);
    return api.listAskThreads();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<void> delete(String id) async {
    final api = ref.read(apiClientProvider);
    await api.deleteAskThread(id);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.where((t) => t.id != id).toList());
    }
  }
}

/// `threadId == 'new'` is the sentinel for a not-yet-created thread: no
/// `GET` is made, and the first successful [ask] call promotes it to a real
/// thread (the caller is responsible for navigating to the real id
/// afterwards).
class AskThreadState {
  const AskThreadState({
    required this.thread,
    required this.messages,
    this.isSending = false,
  });

  final AskThread? thread;
  final List<AskMessage> messages;
  final bool isSending;
}

const newAskThreadId = 'new';

final askThreadProvider =
    AsyncNotifierProvider.family<AskThreadNotifier, AskThreadState, String>(
  (threadId) => AskThreadNotifier(threadId),
);

class AskThreadNotifier extends AsyncNotifier<AskThreadState> {
  AskThreadNotifier(this.threadId);

  final String threadId;

  @override
  Future<AskThreadState> build() async {
    if (threadId == newAskThreadId) {
      return const AskThreadState(thread: null, messages: []);
    }
    final api = ref.watch(apiClientProvider);
    final result = await api.getAskThread(threadId);
    return AskThreadState(thread: result.thread, messages: result.messages);
  }

  /// Returns the real thread id the question landed in (useful for the
  /// screen to swap `/ask/thread/new` for the real route on first send).
  Future<String> ask(String question, {String? answerLanguageOverride}) async {
    final current = state.value ??
        const AskThreadState(thread: null, messages: []);

    final optimisticUserMessage = AskMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: question,
      modelId: null,
      usedFallback: false,
      createdAt: DateTime.now(),
      citations: const [],
    );
    state = AsyncValue.data(
      AskThreadState(
        thread: current.thread,
        messages: [...current.messages, optimisticUserMessage],
        isSending: true,
      ),
    );

    final api = ref.read(apiClientProvider);
    try {
      final response = current.thread == null
          ? await api.askQuestion(question, answerLanguageOverride: answerLanguageOverride)
          : await api.askFollowUp(
              current.thread!.id,
              question,
              answerLanguageOverride: answerLanguageOverride,
            );
      state = AsyncValue.data(
        AskThreadState(
          thread: response.thread,
          messages: [...current.messages, optimisticUserMessage, response.message],
          isSending: false,
        ),
      );
      return response.thread.id;
    } catch (e) {
      state = AsyncValue.data(
        AskThreadState(
          thread: current.thread,
          messages: current.messages,
          isSending: false,
        ),
      );
      rethrow;
    }
  }
}
