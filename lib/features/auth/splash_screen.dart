import 'dart:async';

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/auth/clerk_token_provider.dart';
import '../../core/connectivity/offline_mode.dart';
import '../../core/localization/app_strings.dart';
import '../../widgets/launch_view.dart';

/// Shown at `/splash` while Clerk's SDK fetches its environment/client
/// (see [ClerkAuthBridge.maybeState]) — go_router's redirect moves away
/// from this route automatically once that resolves.
///
/// Shows [LaunchView] while that happens — the same widget `ClerkAuth`
/// shows before this route exists, so launch reads as one loading screen.
///
/// The SDK retries a failed fetch on its own every 10s, but sitting on a
/// bare spinner with no feedback for a network blip is a bad experience,
/// so after a timeout — or immediately if the device is offline — this
/// surfaces a retry affordance instead of hanging forever with no
/// explanation. A device that is offline with a previously signed-in user
/// never lingers here: the router sends it straight to the cached library.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _timeout = Duration(seconds: 12);

  Timer? _timer;
  bool _timedOut = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    OfflineMode.listenable.addListener(_onOfflineChanged);
    _armTimer();
  }

  void _onOfflineChanged() {
    if (mounted) setState(() {});
  }

  void _armTimer() {
    _timer?.cancel();
    setState(() => _timedOut = false);
    _timer = Timer(_timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await ClerkAuthBridge.retryInitialization();
    if (!mounted) return;
    setState(() => _isRetrying = false);
    _armTimer();
  }

  @override
  void dispose() {
    OfflineMode.listenable.removeListener(_onOfflineChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    final isOffline = OfflineMode.isOffline;

    if (!_timedOut && !isOffline) {
      return LaunchView(background: theme.colorScheme.background);
    }

    // Offline with nobody remembered on this device: there's no cached
    // library to fall back to, so say so plainly.
    final canContinueOffline = !isOffline && ClerkAuthBridge.userId != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifiOff, size: 40, color: theme.colorScheme.mutedForeground),
              const SizedBox(height: 16),
              Text(
                isOffline ? s.offlineNoCacheTitle : s.connectionTroubleTitle,
                style: theme.textTheme.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isOffline ? s.offlineNoCacheSubtitle : s.connectionTroubleSubtitle,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: _isRetrying ? null : _retry,
                leading: _isRetrying
                    ? const SizedBox(width: 14, height: 14)
                    : const Icon(LucideIcons.refreshCw),
                child: Text(s.retry),
              ),
              if (canContinueOffline) ...[
                const SizedBox(height: 8),
                ShadButton.outline(
                  onPressed: OfflineMode.enterManually,
                  child: Text(s.continueOffline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
