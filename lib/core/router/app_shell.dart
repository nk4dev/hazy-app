import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../features/settings/settings_providers.dart';
import '../localization/app_strings.dart';

/// Bottom-nav scaffold for the 5 primary sections. Each branch keeps its
/// own navigation stack (so pushing item detail from Library doesn't
/// disturb the Ask tab, etc) via [StatefulNavigationShell].
///
/// shadcn_ui has no bottom navigation bar component, so this stays a
/// Material [NavigationBar] (structural chrome, not a themed component)
/// with Lucide icons for visual consistency with the rest of the app.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly triggers GET /me (and its interfaceLocale -> appLocaleProvider
    // sync, see UserMeNotifier.build) as soon as the signed-in app shell
    // mounts, rather than only when the user happens to visit Settings —
    // otherwise the UI stays in its default language until then.
    ref.watch(userMeProvider);

    final s = AppStrings.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(icon: const Icon(LucideIcons.bookmark), label: s.navLibrary),
          NavigationDestination(icon: const Icon(LucideIcons.clock), label: s.navReadLater),
          NavigationDestination(icon: const Icon(LucideIcons.search), label: s.navSearch),
          NavigationDestination(icon: const Icon(LucideIcons.sparkles), label: s.navAsk),
          NavigationDestination(icon: const Icon(LucideIcons.settings), label: s.navSettings),
        ],
      ),
    );
  }
}
