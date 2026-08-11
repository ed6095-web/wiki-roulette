import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/article/screens/article_reveal_screen.dart';
import '../../features/article/screens/article_read_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/score_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/discover/screens/search_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/achievements_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/main_scaffold.dart';
import '../../data/models/models.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuthed = authState.isAuthenticated;
      final isLoading = authState.isLoading && authState.user == null;

      if (isLoading) return null;

      final onAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!isAuthed && !onAuthPage) return '/login';
      if (isAuthed && onAuthPage) return '/home';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Main app shell (bottom navigation)
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/article/reveal',
        builder: (context, state) {
          final article = state.extra as ArticleModel;
          return ArticleRevealScreen(article: article);
        },
      ),
      GoRoute(
        path: '/article/read',
        builder: (context, state) {
          final article = state.extra as ArticleModel;
          return ArticleReadScreen(article: article);
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) {
          final article = state.extra as ArticleModel;
          return QuizScreen(article: article);
        },
      ),
      GoRoute(
        path: '/score',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return ScoreScreen(
            article: args['article'] as ArticleModel,
            result: args['result'] as GameCompleteModel,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
});
