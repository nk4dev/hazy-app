import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:retry/retry.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/auth/clerk_token_provider.dart';
import 'core/config/app_config.dart';
import 'core/connectivity/offline_mode.dart';
import 'core/localization/app_locale_provider.dart';
import 'core/localization/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/config_gate_screen.dart';
import 'features/share_intake/share_intake_listener.dart';
import 'widgets/launch_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  await OfflineMode.init();
  await ClerkAuthBridge.restoreLastUser();
  runApp(
    ProviderScope(
      // Riverpod re-runs a failed provider up to 10 times with backoff,
      // showing a spinner throughout. Offline that is just a long wait for
      // a request that can't succeed, so surface the offline state at once.
      retry: (retryCount, error) => OfflineMode.isOffline
          ? null
          : ProviderContainer.defaultRetry(retryCount, error),
      child: const HazyApp(),
    ),
  );
}

class HazyApp extends ConsumerWidget {
  const HazyApp({super.key});

  ShadThemeData _theme(Brightness brightness) => ShadThemeData(
        brightness: brightness,
        colorScheme: brightness == Brightness.light
            ? const ShadVioletColorScheme.light()
            : const ShadVioletColorScheme.dark(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    if (!AppConfig.isConfigured) {
      return AppStringsScope(
        locale: locale,
        child: ShadApp(
          title: 'Hazy',
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const ConfigGateScreen(),
        ),
      );
    }

    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };

    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: AppConfig.clerkPublishableKey,
        // Shown while the Clerk SDK starts; SplashScreen then shows the
        // same view, so launch is a single continuous loading screen.
        loading: LaunchView(
          background: _theme(brightness).colorScheme.background,
        ),
        // Don't fetch a session token as part of startup. That request
        // throws out of the SDK's initialization when it fails (no
        // network, or a session the server no longer accepts), which
        // leaves ClerkAuth on its loading widget forever. Tokens are
        // fetched on demand by ClerkAuthBridge.getToken instead, which
        // also starts the SDK's refresh timer.
        sessionTokenPolling: false,
        // Launched with no network: Clerk restores the last session from
        // its on-device cache, so don't spend the default retry schedule
        // (about a minute) on requests that can't succeed.
        retryOptions: OfflineMode.isOffline
            ? const RetryOptions(maxAttempts: 1)
            : const RetryOptions(),
      ),
      child: Builder(
        builder: (context) {
          ClerkAuthBridge.attach(ClerkAuth.of(context, listen: false));
          return AppStringsScope(
            locale: locale,
            child: ShareIntakeListener(
              child: ShadApp.router(
                title: 'Hazy',
                theme: _theme(Brightness.light),
                darkTheme: _theme(Brightness.dark),
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                // Framework-provided UI (the note editor's toolbar and
                // dialogs, the license page) follows the in-app language;
                // the app's own copy comes from AppStrings.
                locale: Locale(locale.name),
                supportedLocales: const [Locale('en'), Locale('ja')],
                localizationsDelegates: const [
                  FlutterQuillLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: appRouter,
              ),
            ),
          );
        },
      ),
    );
  }
}
