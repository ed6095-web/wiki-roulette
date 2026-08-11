import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  DateTime? _lastBackPressTime;
  final List<int> _tabHistory = [0];

  int _indexForLocation(String location) {
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/leaderboard')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTabTapped(int index, BuildContext context) {
    ref.read(currentTabProvider.notifier).state = index;
    _tabHistory.add(index);
    final routes = ['/home', '/discover', '/leaderboard', '/profile'];
    context.go(routes[index]);
  }

  void _handleBackPress(BuildContext context) {
    final currentTab = ref.read(currentTabProvider);

    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      final previousTab = _tabHistory.last;
      ref.read(currentTabProvider.notifier).state = previousTab;
      final routes = ['/home', '/discover', '/leaderboard', '/profile'];
      context.go(routes[previousTab]);
      return;
    }

    if (currentTab != 0) {
      _tabHistory.clear();
      _tabHistory.add(0);
      ref.read(currentTabProvider.notifier).state = 0;
      context.go('/home');
      return;
    }

    // Double tap back to exit on Home tab
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press back again to exit Wiki Roulette',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // Exit application
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexForLocation(location);

    return PopScope(
      canPop: false,
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
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onTabTapped(index, context),
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
