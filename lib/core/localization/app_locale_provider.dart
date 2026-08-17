import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { en, ja }

const _prefsKey = 'hazy.uiLocale';

/// The Flutter app's own UI language. Mirrors (and stays in sync with) the
/// backend's `preferences.interfaceLocale` (see
/// docs/backend-api-contract.md §6/§7) so the choice made in Settings takes
/// effect immediately here — persisted locally too, so it's available
/// before `GET /me` resolves on cold start.
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale>(
  AppLocaleNotifier.new,
);

class AppLocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    _load();
    return AppLocale.en;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return;
    state = AppLocale.values.firstWhere(
      (l) => l.name == stored,
      orElse: () => AppLocale.en,
    );
  }

  /// Sets the local UI language immediately. Callers that also want this
  /// persisted server-side (so the web app agrees) should separately call
  /// `UserMeNotifier.updatePreferences(interfaceLocale: ...)`.
  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.name);
  }
}
