import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/api/api_exception.dart';
import '../core/localization/app_strings.dart';

/// Renders an [ApiException] as a friendly, code-aware message (per
/// docs/backend-api-contract.md §4) with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  String _messageFor(Object error, AppStrings s) {
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
              LucideIcons.circleAlert,
              size: 40,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              _messageFor(error, s),
              textAlign: TextAlign.center,
              style: theme.textTheme.p,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ShadButton(onPressed: onRetry, child: Text(s.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
