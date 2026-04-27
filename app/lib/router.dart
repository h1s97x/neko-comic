import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';

import '../pages/home/home_page.dart';
import '../pages/search/search_page.dart';
import '../pages/favorites/favorites_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/details/comic_details_page.dart';
import '../pages/reader/reader_page.dart';
import 'router/shell_scaffold.dart';

/// Application router configuration
class NekoRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/comic/:id',
        name: 'comic-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sourceKey = state.pathParameters['sourceKey']!;
          final comicId = state.pathParameters['id']!;
          final source = NekoComicSourceManager().find(sourceKey);
          return ComicDetailsPage(
            sourceKey: sourceKey,
            comicId: comicId,
            source: source!,
          );
        },
      ),
      GoRoute(
        path: '/reader',
        name: 'reader',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReaderPage(
            comicId: extra['comicId'] as String,
            chapterId: extra['chapterId'] as String,
            source: extra['source'] as NekoComicSource,
          );
        },
      ),
    ],
  );
}
