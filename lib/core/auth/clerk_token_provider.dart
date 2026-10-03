import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../connectivity/offline_mode.dart';

/// Bridges the live [ClerkAuthState] (only reachable via [BuildContext],
/// through `ClerkAuth.of(context)`) into plain callbacks that don't need a
/// context — [ApiClient] and go_router's `redirect`/`refreshListenable`
/// both consume it this way.
///
/// [attach] is called once, from a `Builder` directly under the root
/// `ClerkAuth` widget in `main.dart`.
class ClerkAuthBridge {
  ClerkAuthBridge._();

  static ClerkAuthState? _state;

  /// Ticks on every Clerk auth state change so go_router's `redirect` gets
  /// re-evaluated (wired as `GoRouter(refreshListenable: ...)`).
  static final ValueNotifier<int> _tick = ValueNotifier(0);
  static Listenable get listenable => _tick;

  static void attach(ClerkAuthState state) {
    if (identical(_state, state)) return;
    _state?.removeListener(_onChange);
    _state = state;
    state.addListener(_onChange);
    _onChange();
  }

  static void _onChange() {
    _rememberUser();
    _tick.value++;
  }

  static const _lastUserIdKey = 'last_signed_in_user_id';
  static String? _lastUserId;

  /// Loads the id of the user who was signed in last time the app ran, so
  /// an offline launch (where Clerk can't initialize) can still open that
  /// user's local SQLite cache. Called from `main()` before `runApp`.
  static Future<void> restoreLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    _lastUserId = prefs.getString(_lastUserIdKey);
  }

  /// Persists the signed-in user id, and forgets it on a confirmed
  /// sign-out. While Clerk is unavailable (offline) the answer is unknown,
  /// so the remembered id is left untouched.
  static void _rememberUser() {
    final s = maybeState;
    if (s == null) return;
    OfflineMode.clearManual();
    final id = s.user?.id;
    if (id == _lastUserId) return;
    _lastUserId = id;
    SharedPreferences.getInstance().then((prefs) {
      if (id == null) {
        prefs.remove(_lastUserIdKey);
      } else {
        prefs.setString(_lastUserIdKey, id);
      }
    });
  }

  /// `null` until the Clerk SDK has finished initializing (env not yet
  /// loaded) or before [attach] has run for the first frame.
  static ClerkAuthState? get maybeState =>
      (_state == null || _state!.isNotAvailable) ? null : _state;

  static bool get isSignedIn => _state?.isSignedIn ?? false;

  /// The signed-in Clerk user's id, used to scope the local SQLite cache
  /// per account — or, while Clerk is unreachable, the last user who was
  /// signed in on this device. `null` when signed out.
  static String? get userId => maybeState?.user?.id ?? _lastUserId;

  /// Forces an immediate retry of Clerk's environment/client fetch, for a
  /// manual "Retry" action on [SplashScreen] — the SDK already retries this
  /// on its own every 10s, but that's a long wait to sit through silently
  /// after a transient network blip.
  static Future<void> retryInitialization() async {
    final s = _state;
    if (s == null) return;
    try {
      await s.initialize();
    } catch (_) {
      // Swallow — maybeState stays null and the splash screen's own
      // timeout/retry affordance handles surfacing this to the user.
    }
  }

  /// Returns the current Clerk session JWT, or `null` if signed out or the
  /// token couldn't be retrieved (the request will then fail with a 401,
  /// which [ApiClient]/callers surface as [ApiException.isUnauthorized]).
  static Future<String?> getToken() async {
    final s = _state;
    if (s == null || !s.isSignedIn) return null;
    try {
      // Bounded: on a flaky connection the SDK's own retry schedule can
      // run for about a minute before giving up.
      final token = await s.sessionToken().timeout(const Duration(seconds: 10));
      return token.jwt;
    } catch (_) {
      return null;
    }
  }
}
