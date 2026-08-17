import 'package:flutter/material.dart';

import '../core/api/api_exception.dart';

/// Renders an [ApiException] as a friendly, code-aware message (per
/// docs/ai/make-flutter-app.md §4) with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  String _messageFor(Object error) {
    if (error is ApiException) {
      if (error.isServiceNotConfigured) {
        return 'This feature needs an AI key configured on the server. '
            'Please try again later.';
      }
      if (error.isUnauthorized) {
        return 'Your session expired. Please sign in again.';
      }
      if (error.isNotFound) {
        return "This item couldn't be found.";
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _messageFor(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
