import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/presentation/analytics/analytics_screen.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/presentation/auth/login/login_screen.dart';
import 'package:spendwise/presentation/auth/register/register_screen.dart';
import 'package:spendwise/presentation/categories/daily/daily_expenses_screen.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';
import 'package:spendwise/presentation/categories/subscriptions/subscriptions_screen.dart';
import 'package:spendwise/presentation/categories/vehicle/vehicle_screen.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/manual/manual_screen.dart';
import 'package:spendwise/presentation/settings/settings_screen.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/tester/tester_dashboard_screen.dart';
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
                builder: (c, s) => const AddDailyExpenseScreen(),
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
                builder: (c, s) => const AddSubscriptionScreen(),
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
                builder: (c, s) => const AddInstallmentScreen(),
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
              GoRoute(path: 'add', builder: (c, s) => const AddVehicleScreen()),
              GoRoute(
                path: ':id',
                builder: (c, s) =>
                    VehicleDetailScreen(vehicleId: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'fuel/add',
                    builder: (c, s) =>
                        AddFuelScreen(vehicleId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'maintenance/add',
                    builder: (c, s) => AddMaintenanceScreen(
                      vehicleId: s.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'accessories/add',
                    builder: (c, s) =>
                        AddAccessoryScreen(vehicleId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (c, s) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/manual', builder: (c, s) => const ManualScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
          GoRoute(
            path: '/tester',
            builder: (c, s) => const TesterDashboardScreen(),
          ),
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

class NavigationShell extends ConsumerWidget {
  const NavigationShell({required this.child, super.key});
  final Widget child;
  static const paths = [
    '/dashboard',
    '/daily',
    '/subscriptions',
    '/installments',
    '/vehicle',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.autorenew,
    Icons.credit_card,
    Icons.directions_car_outlined,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(settingsProvider).visibleModules;
    final visibleIndexes = <int>[
      0,
      if (modules.contains('daily')) 1,
      if (modules.contains('subscriptions')) 2,
      if (modules.contains('installments')) 3,
      if (modules.contains('vehicle')) 4,
    ];
    final location = GoRouterState.of(context).matchedLocation;
    final absoluteIndex = paths.indexWhere(location.startsWith).clamp(0, 4);
    final index = visibleIndexes
        .indexOf(absoluteIndex)
        .clamp(0, visibleIndexes.length - 1);
    final wide = MediaQuery.sizeOf(context).width > 1024;
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.dashboard,
      strings.expensesNav,
      strings.subscriptions,
      strings.installments,
      strings.vehicle,
    ];
    final nav = NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(paths[visibleIndexes[i]]),
      destinations: List.generate(
        visibleIndexes.length,
        (i) => NavigationRailDestination(
          icon: Icon(icons[visibleIndexes[i]]),
          label: Text(labels[visibleIndexes[i]]),
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
              onDestinationSelected: (i) =>
                  context.go(paths[visibleIndexes[i]]),
              destinations: List.generate(
                visibleIndexes.length,
                (i) => NavigationDestination(
                  icon: Icon(icons[visibleIndexes[i]]),
                  label: labels[visibleIndexes[i]],
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
