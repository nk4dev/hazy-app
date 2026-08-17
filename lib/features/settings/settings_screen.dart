import 'package:flutter/material.dart' show Scaffold, AppBar, ListView, ListTile, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/auth/clerk_token_provider.dart';
import '../../core/localization/app_strings.dart';
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
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.p),
                Text(subtitle, style: theme.textTheme.muted),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ShadSwitch(value: value, onChanged: onChanged),
        ],
      ),
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
    final s = AppStrings.of(context);

    return ListView(
      children: [
        ListTile(
          leading: const Icon(LucideIcons.circleUser),
          title: Text(me.displayName ?? me.email ?? s.signedInFallback),
          subtitle: me.email != null ? Text(me.email!) : null,
        ),
        const ShadSeparator.horizontal(),
        _SectionHeader(s.appearanceSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShadRadioGroup<ThemeMode>(
            key: ValueKey(themeMode),
            initialValue: themeMode,
            onChanged: (value) {
              if (value != null) themeNotifier.setThemeMode(value);
            },
            items: [
              ShadRadio(value: ThemeMode.system, label: Text(s.followSystem)),
              ShadRadio(value: ThemeMode.light, label: Text(s.light)),
              ShadRadio(value: ThemeMode.dark, label: Text(s.dark)),
            ],
          ),
        ),
        const ShadSeparator.horizontal(),
        _SectionHeader(s.languageSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShadRadioGroup<InterfaceLocale>(
            key: ValueKey(prefs.interfaceLocale),
            initialValue: prefs.interfaceLocale,
            onChanged: (value) {
              if (value != null) notifier.updatePreferences(interfaceLocale: value);
            },
            // Language names are conventionally shown in their own
            // language regardless of the current UI language.
            items: const [
              ShadRadio(value: InterfaceLocale.en, label: Text('English')),
              ShadRadio(value: InterfaceLocale.ja, label: Text('日本語')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _SettingSwitchRow(
          title: s.answerInSourceLanguage,
          subtitle: s.answerInSourceLanguageSubtitle,
          value: prefs.answerLanguageMode == AnswerLanguageMode.source,
          onChanged: (checked) => notifier.updatePreferences(
            answerLanguageMode:
                checked ? AnswerLanguageMode.source : AnswerLanguageMode.interface,
          ),
        ),
        const ShadSeparator.horizontal(),
        _SectionHeader(s.notificationsSection),
        _SettingSwitchRow(
          title: s.readLaterDigest,
          subtitle: s.notYetSent,
          value: prefs.notifyReadLaterDigest,
          onChanged: (checked) =>
              notifier.updatePreferences(notifyReadLaterDigest: checked),
        ),
        _SettingSwitchRow(
          title: s.weeklyStats,
          subtitle: s.notYetSent,
          value: prefs.notifyWeeklyStats,
          onChanged: (checked) =>
              notifier.updatePreferences(notifyWeeklyStats: checked),
        ),
        const ShadSeparator.horizontal(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ShadButton.outline(
            width: double.infinity,
            leading: const Icon(LucideIcons.logOut),
            onPressed: () => ClerkAuthBridge.maybeState?.signOut(),
            child: Text(s.signOut),
          ),
        ),
      ],
    );
  }
}
