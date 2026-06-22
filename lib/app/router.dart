import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/presentation/analytics/analytics_screen.dart';
import 'package:spendwise/presentation/auth/login/login_screen.dart';
import 'package:spendwise/presentation/auth/register/register_screen.dart';
import 'package:spendwise/presentation/categories/daily/daily_expenses_screen.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';
import 'package:spendwise/presentation/categories/subscriptions/subscriptions_screen.dart';
import 'package:spendwise/presentation/categories/vehicle/vehicle_screen.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final signedIn = auth is Authenticated;
      final authRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (auth is AuthInitial || auth is AuthLoading) {
        return null;
      }
      if (!signedIn && !authRoute) {
        return '/login';
      }
      if (signedIn && (authRoute || state.matchedLocation == '/')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (c, s) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ShellRoute(
        builder: (c, s, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (c, s) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/daily',
            builder: (c, s) => const DailyExpensesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (c, s) => const EntityFormScreen(title: 'Nuova spesa'),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => EntityFormScreen(
                  title: 'Modifica spesa',
                  id: s.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (c, s) => const SubscriptionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (c, s) =>
                    const EntityFormScreen(title: 'Nuovo abbonamento'),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => EntityFormScreen(
                  title: 'Dettaglio abbonamento',
                  id: s.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/installments',
            builder: (c, s) => const InstallmentsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (c, s) =>
                    const EntityFormScreen(title: 'Nuovo piano rateale'),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => EntityFormScreen(
                  title: 'Dettaglio rateizzazione',
                  id: s.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/vehicle',
            builder: (c, s) => const VehicleScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (c, s) =>
                    const EntityFormScreen(title: 'Nuovo veicolo'),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) =>
                    VehicleDetailScreen(vehicleId: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'fuel/add',
                    builder: (c, s) =>
                        const EntityFormScreen(title: 'Nuovo rifornimento'),
                  ),
                  GoRoute(
                    path: 'maintenance/add',
                    builder: (c, s) =>
                        const EntityFormScreen(title: 'Nuova manutenzione'),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (c, s) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
    ],
  ),
);

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

class NavigationShell extends StatelessWidget {
  const NavigationShell({required this.child, super.key});
  final Widget child;
  static const paths = [
    '/dashboard',
    '/daily',
    '/subscriptions',
    '/installments',
    '/vehicle',
  ];
  static const labels = ['Home', 'Spese', 'Abbonamenti', 'Rate', 'Veicolo'];
  static const icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.autorenew,
    Icons.credit_card,
    Icons.directions_car_outlined,
  ];
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = paths.indexWhere(location.startsWith).clamp(0, 4);
    final wide = MediaQuery.sizeOf(context).width > 1024;
    final nav = NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(paths[i]),
      destinations: List.generate(
        5,
        (i) => NavigationRailDestination(
          icon: Icon(icons[i]),
          label: Text(labels[i]),
        ),
      ),
    );
    return Scaffold(
      body: Row(
        children: [
          if (wide) nav,
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(paths[i]),
              destinations: List.generate(
                5,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: labels[i],
                ),
              ),
            ),
    );
  }
}

class EntityFormScreen extends StatelessWidget {
  const EntityFormScreen({required this.title, this.id, super.key});
  final String title;
  final String? id;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Nome / descrizione'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Importo'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Salva'),
        ),
      ],
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Impostazioni')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Esci'),
          onTap: () => ref.read(authStateProvider.notifier).logout(),
        ),
      ],
    ),
  );
}
