import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/models/user_profile.dart';

import '../screens/dashboard/provider_dashboard_screen.dart';
import '../screens/taxi_driver/driver_home_screen.dart';
import '../screens/listings/create_listing_screen.dart';

/// Provider app router with role-aware guards.
/// Only provider roles can access this app.
final providerRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);
      final isOnLogin = state.matchedLocation == '/login';

      // Not authenticated
      if (user == null && !isOnLogin) return '/login';

      // Authenticated but not a provider
      if (user != null && role != null && !role.isProvider && !role.isAdmin) {
        return '/unauthorized';
      }

      if (user != null && isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const _ProviderLoginScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const _UnauthorizedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _ProviderShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const ProviderDashboardScreen(),
          ),
          GoRoute(
            path: '/driver',
            builder: (context, state) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/listings/create',
            builder: (context, state) => const CreateListingScreen(),
          ),
        ],
      ),
    ],
  );
});

class _ProviderShell extends StatelessWidget {
  final Widget child;
  const _ProviderShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/driver');
              break;
            case 2:
              context.go('/listings/create');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_taxi_outlined),
            selectedIcon: Icon(Icons.local_taxi),
            label: 'Drive',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_business_outlined),
            selectedIcon: Icon(Icons.add_business),
            label: 'New Listing',
          ),
        ],
      ),
    );
  }

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/driver') return 1;
    if (location.startsWith('/listings')) return 2;
    return 0;
  }
}

class _ProviderLoginScreen extends StatelessWidget {
  const _ProviderLoginScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Provider Login — use customer app login_screen as reference')),
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app is for PearlHub providers only. '
                'Please sign up as a provider to access this app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => AuthService.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
