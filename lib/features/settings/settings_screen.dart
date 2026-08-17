import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/clerk_token_provider.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../models/user_me.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userMeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: switch (state) {
        AsyncData(:final value) => _SettingsBody(me: value),
        AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(userMeProvider),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.me});

  final UserMe me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = me.preferences;
    final notifier = ref.read(userMeProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(me.displayName ?? me.email ?? 'Signed in'),
          subtitle: me.email != null ? Text(me.email!) : null,
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Follow system'),
          value: ThemeMode.system,
          groupValue: themeMode,
          onChanged: (value) => themeNotifier.setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          value: ThemeMode.light,
          groupValue: themeMode,
          onChanged: (value) => themeNotifier.setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          value: ThemeMode.dark,
          groupValue: themeMode,
          onChanged: (value) => themeNotifier.setThemeMode(value!),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        RadioListTile<InterfaceLocale>(
          title: const Text('English'),
          value: InterfaceLocale.en,
          groupValue: prefs.interfaceLocale,
          onChanged: (value) => notifier.updatePreferences(interfaceLocale: value),
        ),
        RadioListTile<InterfaceLocale>(
          title: const Text('日本語'),
          value: InterfaceLocale.ja,
          groupValue: prefs.interfaceLocale,
          onChanged: (value) => notifier.updatePreferences(interfaceLocale: value),
        ),
        SwitchListTile(
          title: const Text('Answer in the source page\'s language'),
          subtitle: const Text('Otherwise Ask answers in your interface language.'),
          value: prefs.answerLanguageMode == AnswerLanguageMode.source,
          onChanged: (checked) => notifier.updatePreferences(
            answerLanguageMode:
                checked ? AnswerLanguageMode.source : AnswerLanguageMode.interface,
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        SwitchListTile(
          title: const Text('Read-later digest'),
          subtitle: const Text('Not yet sent — no push notifications configured.'),
          value: prefs.notifyReadLaterDigest,
          onChanged: (checked) =>
              notifier.updatePreferences(notifyReadLaterDigest: checked),
        ),
        SwitchListTile(
          title: const Text('Weekly stats'),
          subtitle: const Text('Not yet sent — no push notifications configured.'),
          value: prefs.notifyWeeklyStats,
          onChanged: (checked) =>
              notifier.updatePreferences(notifyWeeklyStats: checked),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => ClerkAuthBridge.maybeState?.signOut(),
        ),
      ],
    );
  }
}
