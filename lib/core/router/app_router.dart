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
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/read_later/read_later_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/share_intake/share_confirm_screen.dart';
import '../auth/clerk_token_provider.dart';
import '../connectivity/offline_mode.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// True from the moment the app is entered without Clerk (offline, with a
/// remembered user) until Clerk becomes reachable. Sticky so that regaining
/// the network doesn't bounce the user back to the splash screen while
/// Clerk is still re-initializing.
bool _offlineSession = false;

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: Listenable.merge([
    ClerkAuthBridge.listenable,
    OfflineMode.listenable,
  ]),
  redirect: (context, state) {
    final loc = state.matchedLocation;
    final authState = ClerkAuthBridge.maybeState;

    if (authState == null) {
      // Clerk can't initialize without a network. If someone was signed in
      // on this device before, let them into their locally cached library
      // instead of blocking on the splash screen.
      if (OfflineMode.isOffline && ClerkAuthBridge.userId != null) {
        _offlineSession = true;
      }
      if (_offlineSession) {
        return (loc == '/splash' || loc == '/sign-in') ? '/library' : null;
      }
      return loc == '/splash' ? null : '/splash';
    }
    _offlineSession = false;

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
    // Full-screen, above the bottom nav: the editor needs the room, and
    // its own toolbar sits where the nav bar would be.
    GoRoute(
      path: '/note/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => NoteEditorScreen(
        noteId: state.pathParameters['id']!,
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
              path: '/notes',
              builder: (context, state) => const NotesScreen(),
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
