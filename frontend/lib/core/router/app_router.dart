import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/onboarding_screen.dart';
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
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      if (profileState.isLoading) return null;

      final isOnboarded = profileState.isOnboarded;
      final onOnboardingPage = state.matchedLocation == '/onboarding';

      if (!isOnboarded && !onOnboardingPage) return '/onboarding';
      if (isOnboarded && onOnboardingPage) return '/home';
      return null;
    },
    routes: [
      // First-time lightweight onboarding
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
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

      // Full-screen routes
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
