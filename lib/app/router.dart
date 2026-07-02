import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/presentation/analytics/analytics_screen.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/presentation/auth/login/login_screen.dart';
import 'package:spendwise/presentation/auth/register/register_screen.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';
import 'package:spendwise/presentation/auth/pin_unlock_screen.dart';
import 'package:spendwise/presentation/categories/daily/daily_expenses_screen.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';
import 'package:spendwise/presentation/categories/subscriptions/subscriptions_screen.dart';
import 'package:spendwise/presentation/categories/vehicle/vehicle_screen.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/manual/manual_screen.dart';
import 'package:spendwise/presentation/onboarding/onboarding_provider.dart';
import 'package:spendwise/presentation/onboarding/onboarding_screen.dart';
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
      final lock = ref.read(localUnlockProvider);
      final onboarding = ref.read(onboardingProvider);
      final signedIn = auth is Authenticated;
      final welcomeRoute = state.matchedLocation == '/welcome';
      final unlockRoute = state.matchedLocation == '/unlock';
      final authRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (onboarding.loading || auth is AuthInitial || auth is AuthLoading) {
        return null;
      }
      if (!onboarding.completed && !welcomeRoute) return '/welcome';
      if (onboarding.completed && welcomeRoute) {
        return signedIn ? '/dashboard' : '/login';
      }
      if (welcomeRoute) return null;
      if (!signedIn && !authRoute) {
        return '/login';
      }
      if (signedIn &&
          !lock.loading &&
          lock.protectionEnabled &&
          !lock.unlocked &&
          !unlockRoute) {
        return '/unlock';
      }
      if (signedIn && unlockRoute && lock.unlocked) return '/dashboard';
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
      GoRoute(path: '/welcome', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/unlock', builder: (c, s) => const PinUnlockScreen()),
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
    ref.listen(localUnlockProvider, (_, __) => notifyListeners());
    ref.listen(onboardingProvider, (_, __) => notifyListeners());
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
    '/tester',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.autorenew,
    Icons.credit_card,
    Icons.directions_car_outlined,
    Icons.science_outlined,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(settingsProvider).visibleModules;
    final user = ref.watch(currentUserProvider);
    final tester = user != null && {'tester', 'admin'}.contains(user.role);
    final visibleIndexes = <int>[
      0,
      if (modules.contains('daily')) 1,
      if (modules.contains('subscriptions')) 2,
      if (modules.contains('installments')) 3,
      if (modules.contains('vehicle')) 4,
      if (tester) 5,
    ];
    final location = GoRouterState.of(context).matchedLocation;
    final absoluteIndex = paths.indexWhere(location.startsWith).clamp(0, 5);
    final index = visibleIndexes
        .indexOf(absoluteIndex)
        .clamp(0, visibleIndexes.length - 1);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth > 1024;
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.dashboard,
      strings.expensesNav,
      strings.subscriptions,
      strings.installments,
      strings.vehicle,
      'Test',
    ];
    final compactLabels = [
      strings.dashboard,
      strings.expensesNav,
      'Abbon.',
      'Rate',
      strings.vehicle,
      'Test',
    ];
    final useCompactLabels = screenWidth < 480 && visibleIndexes.length >= 4;
    final nav = NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(paths[visibleIndexes[i]]),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      indicatorColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: .18),
      useIndicator: true,
      labelType: NavigationRailLabelType.all,
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
          if (wide)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: nav,
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: .9),
                      width: 1.25,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23.5),
                    child: NavigationBar(
                      selectedIndex: index,
                      onDestinationSelected: (i) =>
                          context.go(paths[visibleIndexes[i]]),
                      destinations: List.generate(
                        visibleIndexes.length,
                        (i) => NavigationDestination(
                          icon: Icon(icons[visibleIndexes[i]]),
                          selectedIcon: Icon(
                            [
                              Icons.home_rounded,
                              Icons.receipt_long_rounded,
                              Icons.autorenew_rounded,
                              Icons.credit_card_rounded,
                              Icons.directions_car_rounded,
                              Icons.science_rounded,
                            ][visibleIndexes[i]],
                          ),
                          label: (useCompactLabels
                              ? compactLabels
                              : labels)[visibleIndexes[i]],
                        ),
                      ),
                    ),
                  ),
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
