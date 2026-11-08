import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/subscriptions', builder: (context, state) => const SubscriptionsScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/subscription/new',
        builder: (context, state) => const SubscriptionFormScreen(),
      ),
      GoRoute(
        path: '/subscription/:id',
        builder: (context, state) =>
            SubscriptionFormScreen(subscriptionId: state.pathParameters['id']),
      ),
    ],
  );
});

class SubZeroApp extends ConsumerWidget {
  const SubZeroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SubZero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = location == '/subscriptions' ? 1 : location == '/settings' ? 2 : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(switch (value) {
          1 => '/subscriptions',
          2 => '/settings',
          _ => '/',
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.autorenew), label: 'Subscriptions'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SubZeroApp()));
}
