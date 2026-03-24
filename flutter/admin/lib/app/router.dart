import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/models/user_profile.dart';

import '../screens/overview/admin_overview_screen.dart';
import '../screens/moderation/listings_moderation_screen.dart';

/// Admin app router — side-drawer navigation, admin-only access.
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);
      final isOnLogin = state.matchedLocation == '/login';

      if (user == null && !isOnLogin) return '/login';
      if (user != null && role != null && !role.isAdmin) return '/unauthorized';
      if (user != null && isOnLogin) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const _AdminLoginScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const _UnauthorizedScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AdminOverviewScreen(),
          ),
          GoRoute(
            path: '/moderation',
            builder: (context, state) => const ListingsModerationScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Admin shell with side drawer (tablet-optimized).
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      // Tablet: permanent side nav
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _getIndex(context),
              onDestinationSelected: (index) => _navigate(context, index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.diamond, color: Color(0xFF0EA5E9), size: 32),
                    SizedBox(height: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings),
                  label: Text('Moderation'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom nav
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getIndex(context),
        onDestinationSelected: (index) => _navigate(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Moderation',
          ),
        ],
      ),
    );
  }

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/moderation') return 1;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/moderation');
        break;
    }
  }
}

class _AdminLoginScreen extends StatelessWidget {
  const _AdminLoginScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Admin Login — restricted access'),
      ),
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_bad, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Admin Access Only',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You do not have admin privileges.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AuthService.signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
