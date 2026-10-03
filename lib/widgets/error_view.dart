import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/api/api_exception.dart';
import '../core/connectivity/offline_mode.dart';
import '../core/localization/app_strings.dart';

/// Renders an [ApiException] as a friendly, code-aware message (per
/// docs/backend-api-contract.md §4) with an optional retry action.
///
/// A failure caused by being offline is shown as such, and retries itself
/// as soon as the connection returns so the screen doesn't sit on a stale
/// error.
class ErrorView extends StatefulWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool get _isOfflineError {
    final error = widget.error;
    return error is ApiException &&
        (error.isOffline || (error.isNetworkError && OfflineMode.isOffline));
  }

  @override
  void initState() {
    super.initState();
    OfflineMode.listenable.addListener(_onOfflineChanged);
  }

  @override
  void dispose() {
    OfflineMode.listenable.removeListener(_onOfflineChanged);
    super.dispose();
  }

  void _onOfflineChanged() {
    if (!mounted || OfflineMode.isOffline) return;
    final error = widget.error;
    if (error is ApiException && error.isNetworkError) widget.onRetry?.call();
  }

  String _messageFor(Object error, AppStrings s) {
    if (_isOfflineError) return s.offlineMessage;
    if (error is ApiException) {
      if (error.isServiceNotConfigured) return s.aiKeyNotConfigured;
      if (error.isUnauthorized) return s.sessionExpired;
      if (error.isNotFound) return s.itemNotFound;
      return error.message;
    }
    return s.somethingWentWrong;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOfflineError ? LucideIcons.wifiOff : LucideIcons.circleAlert,
              size: 40,
              color: _isOfflineError
                  ? theme.colorScheme.mutedForeground
                  : theme.colorScheme.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              _messageFor(widget.error, s),
              textAlign: TextAlign.center,
              style: theme.textTheme.p,
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 16),
              ShadButton(onPressed: widget.onRetry, child: Text(s.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
