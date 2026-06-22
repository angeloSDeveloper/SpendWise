import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/daily_expense.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';

class DashboardData {
  const DashboardData({
    required this.categories,
    required this.months,
    required this.recent,
  });
  final List<double> categories;
  final List<double> months;
  final List<DailyExpense> recent;
  double get total => categories.fold(0, (sum, value) => sum + value);
}

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final dio = ref.watch(dioClientProvider).dio;
  final now = DateTime.now();
  final from = DateTime(now.year, now.month - 5, 1);
  final results = await Future.wait([
    ExpensesApiClient(
      dio,
    ).getExpenses(from.toIso8601String(), now.toIso8601String(), null),
    SubscriptionsApiClient(dio).getAll(),
    VehiclesApiClient(dio).getAll(),
  ]);
  final expenses = results[0] as List<DailyExpense>;
  final subscriptions = results[1] as List<dynamic>;
  final vehicles = results[2] as List<dynamic>;
  final vehicleApi = VehiclesApiClient(dio);
  final fuelLists = await Future.wait(
    vehicles.map((v) => vehicleApi.fuel(v.id as String)),
  );
  final maintenanceLists = await Future.wait(
    vehicles.map((v) => vehicleApi.maintenance(v.id as String)),
  );
  final accessoryLists = await Future.wait(
    vehicles.map((v) => vehicleApi.accessories(v.id as String)),
  );
  final monthTotals = List<double>.filled(6, 0);
  int monthIndex(DateTime date) =>
      (date.year - from.year) * 12 + date.month - from.month;
  for (final expense in expenses) {
    final index = monthIndex(expense.date);
    if (index >= 0 && index < 6) monthTotals[index] += expense.amount;
  }
  var vehicleMonth = 0.0;
  for (final list in fuelLists) {
    for (final entry in list) {
      final index = monthIndex(entry.date);
      if (index >= 0 && index < 6) monthTotals[index] += entry.totalCost;
      if (entry.date.year == now.year && entry.date.month == now.month) {
        vehicleMonth += entry.totalCost;
      }
    }
  }
  for (final list in maintenanceLists) {
    for (final entry in list) {
      final index = monthIndex(entry.date);
      if (index >= 0 && index < 6) monthTotals[index] += entry.totalCost;
      if (entry.date.year == now.year && entry.date.month == now.month) {
        vehicleMonth += entry.totalCost;
      }
    }
  }
  for (final list in accessoryLists) {
    for (final entry in list) {
      final index = monthIndex(entry.date);
      if (index >= 0 && index < 6) monthTotals[index] += entry.totalCost;
      if (entry.date.year == now.year && entry.date.month == now.month) {
        vehicleMonth += entry.totalCost;
      }
    }
  }
  final dailyMonth = expenses
      .where((x) => x.date.year == now.year && x.date.month == now.month)
      .fold<double>(0, (sum, x) => sum + x.amount);
  final subscriptionMonth = subscriptions
      .where((x) => x.isActive == true)
      .fold<double>(
        0,
        (sum, x) =>
            sum +
            switch (x.billingCycle as BillingCycle) {
              BillingCycle.weekly => (x.amount as double) * 52 / 12,
              BillingCycle.monthly => x.amount as double,
              BillingCycle.yearly => (x.amount as double) / 12,
            },
      );
  expenses.sort((a, b) => b.date.compareTo(a.date));
  return DashboardData(
    categories: [dailyMonth, subscriptionMonth, 0, vehicleMonth],
    months: monthTotals,
    recent: expenses.take(5).toList(),
  );
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  int touched = -1;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final sync = ref.watch(syncStatusProvider);
    final data = ref.watch(dashboardDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ciao, ${user?.displayName ?? 'utente'}!'),
            Text(
              DateFormat.yMMMMd('it').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: sync.name,
            child: Icon(
              sync == SyncStatus.offline
                  ? Icons.cloud_off
                  : sync == SyncStatus.syncing
                  ? Icons.sync
                  : Icons.cloud_done,
            ),
          ),
          IconButton(
            tooltip: 'Analisi',
            onPressed: () => context.push('/analytics'),
            icon: const Icon(Icons.insights),
          ),
          IconButton(
            tooltip: 'Manuale',
            onPressed: () => context.push('/manual'),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardDataProvider.future),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            final expired = error.toString().contains('401');
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                expired ? Icons.lock_clock : Icons.cloud_off,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                expired
                                    ? 'La sessione è scaduta'
                                    : 'Dashboard temporaneamente non disponibile',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                expired
                                    ? 'Accedi nuovamente per proteggere i tuoi dati.'
                                    : 'Controlla la connessione e riprova.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: expired
                                    ? () => ref
                                          .read(authStateProvider.notifier)
                                          .logout()
                                    : () =>
                                          ref.invalidate(dashboardDataProvider),
                                icon: Icon(
                                  expired ? Icons.login : Icons.refresh,
                                ),
                                label: Text(
                                  expired ? 'Torna al login' : 'Riprova',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spese stimate questo mese'),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(
                          locale: 'it_IT',
                          symbol: '€',
                        ).format(summary.total),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth > 750
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _categoryChart(summary)),
                          const SizedBox(width: 16),
                          Expanded(child: _monthlyChart(summary)),
                        ],
                      )
                    : Column(
                        children: [
                          _categoryChart(summary),
                          const SizedBox(height: 16),
                          _monthlyChart(summary),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ultime spese',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (summary.recent.isEmpty)
                const Card(child: ListTile(title: Text('Nessuna transazione'))),
              for (final expense in summary.recent)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(expense.description ?? 'Spesa'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(expense.date.toLocal()),
                    ),
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'it_IT',
                        symbol: '€',
                      ).format(expense.amount),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/daily/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _categoryChart(DashboardData data) {
    const labels = ['Spese', 'Abbonamenti', 'Rate', 'Veicolo'];
    const colors = [
      AppColors.daily,
      AppColors.subscription,
      AppColors.installment,
      AppColors.vehicle,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Distribuzione del mese',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (_, response) => setState(
                      () => touched =
                          response?.touchedSection?.touchedSectionIndex ?? -1,
                    ),
                  ),
                  sections: List.generate(4, (index) {
                    final value = data.categories[index];
                    return PieChartSectionData(
                      value: value <= 0 ? .001 : value,
                      color: colors[index],
                      radius: touched == index ? 70 : 58,
                      title: value <= 0
                          ? ''
                          : NumberFormat.compactCurrency(
                              locale: 'it_IT',
                              symbol: '€',
                            ).format(value),
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  }),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              children: List.generate(
                4,
                (i) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 12, color: colors[i]),
                    const SizedBox(width: 4),
                    Text(labels[i]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyChart(DashboardData data) {
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Andamento ultimi 6 mesi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: true),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final date = DateTime(
                            now.year,
                            now.month - 5 + value.toInt(),
                          );
                          return Text(DateFormat.MMM('it').format(date));
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    6,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.months[i],
                          color: AppColors.primary,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
