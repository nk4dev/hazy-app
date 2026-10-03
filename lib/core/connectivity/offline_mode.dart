import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the app should behave as offline: the device reports no
/// network at all, or the user chose "Continue offline" from the splash
/// screen (network present but the servers unreachable).
///
/// Static, like [ClerkAuthBridge], because go_router's `redirect` needs it
/// without a `BuildContext` or `ref`; widgets read it through
/// [isOfflineProvider].
class OfflineMode {
  OfflineMode._();

  static bool _noNetwork = false;
  static bool _manual = false;
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static final ValueNotifier<bool> _isOffline = ValueNotifier(false);
  static ValueListenable<bool> get listenable => _isOffline;
  static bool get isOffline => _isOffline.value;

  static bool _hasNoNetwork(List<ConnectivityResult> results) =>
      results.every((r) => r == ConnectivityResult.none);

  static void _update() => _isOffline.value = _noNetwork || _manual;

  /// Reads the current connectivity once and subscribes to changes. Called
  /// from `main()` before `runApp` so the very first route decision already
  /// knows whether the device is offline.
  static Future<void> init() async {
    final connectivity = Connectivity();
    try {
      _noNetwork = _hasNoNetwork(await connectivity.checkConnectivity());
    } catch (_) {
      // Platform without connectivity support — assume online and let
      // request failures speak for themselves.
      _noNetwork = false;
    }
    _update();
    await _subscription?.cancel();
    _subscription = connectivity.onConnectivityChanged.listen((results) {
      _noNetwork = _hasNoNetwork(results);
      // A real connectivity change supersedes the manual choice.
      _manual = false;
      _update();
    });
  }

  /// "Continue offline" from the splash screen.
  static void enterManually() {
    _manual = true;
    _update();
  }

  /// Called once Clerk is reachable again, which proves the network works.
  static void clearManual() {
    if (!_manual) return;
    _manual = false;
    _update();
  }
}

/// Riverpod view of [OfflineMode] for widgets and providers.
final isOfflineProvider = NotifierProvider<_IsOfflineNotifier, bool>(
  _IsOfflineNotifier.new,
);

class _IsOfflineNotifier extends Notifier<bool> {
  @override
  bool build() {
    void listener() => state = OfflineMode.isOffline;
    OfflineMode.listenable.addListener(listener);
    ref.onDispose(() => OfflineMode.listenable.removeListener(listener));
    return OfflineMode.isOffline;
  }
}
