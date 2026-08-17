import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

/// Shown instead of the Clerk SDK when [AppConfig.isConfigured] is false,
/// so the app never crashes on an empty publishable key — it just tells
/// whoever is running it what to supply.
class ConfigGateScreen extends StatelessWidget {
  const ConfigGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hazy isn\'t configured yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This build is missing the Clerk publishable key. Run '
                  'the app with:',
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'flutter run \\\n'
                    '  --dart-define=HAZY_API_BASE_URL=https://your-host/api/v1 \\\n'
                    '  --dart-define=CLERK_PUBLISHABLE_KEY=pk_...',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Current API base URL: ${AppConfig.apiBaseUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
