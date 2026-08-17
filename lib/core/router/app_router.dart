import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ask/ask_thread_list_screen.dart';
import '../../features/ask/ask_thread_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/collections/collection_detail_screen.dart';
import '../../features/collections/collections_screen.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/read_later/read_later_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/share_intake/share_confirm_screen.dart';
import '../auth/clerk_token_provider.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: ClerkAuthBridge.listenable,
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final authState = ClerkAuthBridge.maybeState;

    if (authState == null) {
      return loc == '/splash' ? null : '/splash';
    }

    final signedIn = authState.isSignedIn;
    if (!signedIn) {
      return loc == '/sign-in' ? null : '/sign-in';
    }
    if (loc == '/sign-in' || loc == '/splash') {
      return '/library';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/share-confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ShareConfirmScreen(
        sharedUrl: state.extra as String? ?? '',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'item/:id',
                  builder: (context, state) => ItemDetailScreen(
                    itemId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'collections',
                  builder: (context, state) => const CollectionsScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => CollectionDetailScreen(
                        collectionId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/read-later',
              builder: (context, state) => const ReadLaterScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ask',
              builder: (context, state) => const AskThreadListScreen(),
              routes: [
                GoRoute(
                  path: 'thread/:id',
                  builder: (context, state) => AskThreadScreen(
                    threadId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
