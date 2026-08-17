import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';

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

  static void _onChange() => _tick.value++;

  /// `null` until the Clerk SDK has finished initializing (env not yet
  /// loaded) or before [attach] has run for the first frame.
  static ClerkAuthState? get maybeState =>
      (_state == null || _state!.isNotAvailable) ? null : _state;

  static bool get isSignedIn => _state?.isSignedIn ?? false;

  /// Returns the current Clerk session JWT, or `null` if signed out or the
  /// token couldn't be retrieved (the request will then fail with a 401,
  /// which [ApiClient]/callers surface as [ApiException.isUnauthorized]).
  static Future<String?> getToken() async {
    final s = _state;
    if (s == null || !s.isSignedIn) return null;
    try {
      final token = await s.sessionToken();
      return token.jwt;
    } catch (_) {
      return null;
    }
  }
}
