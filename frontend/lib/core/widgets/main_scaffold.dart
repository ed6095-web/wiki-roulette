import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final List<int> _tabHistory = [0];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTabSelected(int index, BuildContext context) {
    final routes = ['/home', '/discover', '/leaderboard', '/profile'];
    if (_selectedIndex(context) != index) {
      _tabHistory.add(index);
      context.go(routes[index]);
    }
  }

  bool _handleBackPress(BuildContext context) {
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousTab = _tabHistory.last;
      final routes = ['/home', '/discover', '/leaderboard', '/profile'];
      context.go(routes[previousTab]);
      return false; // Handled back navigation tab-to-tab
    } else {
      final current = _selectedIndex(context);
      if (current != 0) {
        _tabHistory.clear();
        _tabHistory.add(0);
        context.go('/home');
        return false;
      }
      return true; // Exit app only from Home
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);

    return PopScope(
      canPop: selected == 0 && _tabHistory.length <= 1,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackPress(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: NavigationBar(
            backgroundColor: AppColors.navBackground,
            selectedIndex: selected,
            onDestinationSelected: (index) => _onTabSelected(index, context),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.casino_outlined),
                selectedIcon: Icon(Icons.casino_rounded),
                label: 'Roulette',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events_rounded),
                label: 'Rankings',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
