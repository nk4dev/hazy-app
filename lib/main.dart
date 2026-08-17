import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/auth/clerk_token_provider.dart';
import 'core/config/app_config.dart';
import 'core/localization/app_locale_provider.dart';
import 'core/localization/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/config_gate_screen.dart';
import 'features/share_intake/share_intake_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(const ProviderScope(child: HazyApp()));
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

    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: AppConfig.clerkPublishableKey),
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
                routerConfig: appRouter,
              ),
            ),
          );
        },
      ),
    );
  }
}
