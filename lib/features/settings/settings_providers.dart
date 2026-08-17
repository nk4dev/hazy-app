import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_locale_provider.dart';
import '../../core/providers.dart';
import '../../models/user_me.dart';

final userMeProvider = AsyncNotifierProvider<UserMeNotifier, UserMe>(
  UserMeNotifier.new,
);

AppLocale _toAppLocale(InterfaceLocale locale) =>
    locale == InterfaceLocale.ja ? AppLocale.ja : AppLocale.en;

class UserMeNotifier extends AsyncNotifier<UserMe> {
  @override
  Future<UserMe> build() async {
    final api = ref.watch(apiClientProvider);
    final me = await api.getMe();
    // Sync the locally-cached UI language from the backend on load, so a
    // user who switched language on the web app sees it here too.
    ref.read(appLocaleProvider.notifier).setLocale(
          _toAppLocale(me.preferences.interfaceLocale),
        );
    return me;
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
    if (interfaceLocale != null) {
      ref.read(appLocaleProvider.notifier).setLocale(_toAppLocale(interfaceLocale));
    }
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
