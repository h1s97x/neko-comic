import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';

import '../pages/home/home_page.dart';
import '../pages/search/search_page.dart';
import '../pages/favorites/favorites_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/details/comic_details_page.dart';
import '../pages/reader/reader_page.dart';
import '../pages/explore/explore_page.dart';
import '../pages/categories/categories_page.dart';
import '../pages/history/history_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/downloads/downloads_page.dart';
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
            path: '/explore',
            name: 'explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExplorePage(),
            ),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
          GoRoute(
            path: '/downloads',
            name: 'downloads',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DownloadsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/comic/:sourceKey/:id',
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
