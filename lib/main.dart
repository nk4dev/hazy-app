import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/clerk_token_provider.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/config_gate_screen.dart';
import 'features/share_intake/share_intake_listener.dart';

void main() {
  runApp(const ProviderScope(child: HazyApp()));
}

class HazyApp extends ConsumerWidget {
  const HazyApp({super.key});

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: brightness,
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    if (!AppConfig.isConfigured) {
      return MaterialApp(
        title: 'Hazy',
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const ConfigGateScreen(),
      );
    }

    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: AppConfig.clerkPublishableKey),
      child: Builder(
        builder: (context) {
          ClerkAuthBridge.attach(ClerkAuth.of(context, listen: false));
          return ShareIntakeListener(
            child: MaterialApp.router(
              title: 'Hazy',
              theme: _theme(Brightness.light),
              darkTheme: _theme(Brightness.dark),
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
