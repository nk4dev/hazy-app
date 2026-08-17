import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/user_me.dart';

final userMeProvider = AsyncNotifierProvider<UserMeNotifier, UserMe>(
  UserMeNotifier.new,
);

class UserMeNotifier extends AsyncNotifier<UserMe> {
  @override
  Future<UserMe> build() {
    final api = ref.watch(apiClientProvider);
    return api.getMe();
  }

  Future<void> updatePreferences({
    InterfaceLocale? interfaceLocale,
    AnswerLanguageMode? answerLanguageMode,
    bool? notifyReadLaterDigest,
    bool? notifyWeeklyStats,
  }) async {
    final current = state.value;
    if (current == null) return;
    final api = ref.read(apiClientProvider);
    final updated = await api.updatePreferences(
      interfaceLocale: interfaceLocale,
      answerLanguageMode: answerLanguageMode,
      notifyReadLaterDigest: notifyReadLaterDigest,
      notifyWeeklyStats: notifyWeeklyStats,
    );
    state = AsyncValue.data(
      UserMe(
        id: current.id,
        email: current.email,
        displayName: current.displayName,
        avatarUrl: current.avatarUrl,
        preferences: updated,
      ),
    );
  }
}
