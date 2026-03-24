import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/services/auth_service.dart';

import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/taxi/taxi_home_screen.dart';
import '../screens/taxi/taxi_active_ride_screen.dart';
import '../screens/concierge/concierge_screen.dart';

/// GoRouter configuration with auth redirect.
/// Unauthenticated users are redirected to /login.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isOnLogin = state.matchedLocation == '/login';

      if (user == null && !isOnLogin) return '/login';
      if (user != null && isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/taxi',
            builder: (context, state) => const TaxiHomeScreen(),
          ),
          GoRoute(
            path: '/taxi/ride/:rideId',
            builder: (context, state) => TaxiActiveRideScreen(
              rideId: state.pathParameters['rideId']!,
            ),
          ),
          GoRoute(
            path: '/concierge',
            builder: (context, state) => const ConciergeScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Home shell with bottom navigation bar.
class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/taxi')) return 1;
    if (location == '/concierge') return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/taxi');
              break;
            case 2:
              context.go('/concierge');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_taxi_outlined),
            selectedIcon: Icon(Icons.local_taxi),
            label: 'Taxi',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Concierge',
          ),
        ],
      ),
    );
  }
}
