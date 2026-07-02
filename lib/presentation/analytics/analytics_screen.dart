import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends ConsumerState<AnalyticsScreen> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final modules = settings.visibleModules;
    final data = ref.watch(dashboardDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analisi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('1 mese', maxLines: 1)),
                ButtonSegment(value: 1, label: Text('3 mesi')),
                ButtonSegment(value: 2, label: Text('6 mesi')),
                ButtonSegment(value: 3, label: Text('Anno')),
              ],
              selected: {period},
              onSelectionChanged: (value) =>
                  setState(() => period = value.first),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Dati di analisi non disponibili: $error'),
                ),
              ),
              data: (value) => _AnalyticsContent(
                data: value,
                modules: modules,
                moduleColors: settings.moduleColors,
                period: period,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.data,
    required this.modules,
    required this.moduleColors,
    required this.period,
  });

  final DashboardData data;
  final Set<String> modules;
  final Map<String, int> moduleColors;
  final int period;

  static const labels = [
    'Spese quotidiane',
    'Abbonamenti',
    'Rate e finanziamenti',
    'Veicoli',
  ];
  @override
  Widget build(BuildContext context) {
    final colors = [
      Color(moduleColors['daily'] ?? AppColors.daily.toARGB32()),
      Color(moduleColors['subscriptions'] ?? AppColors.subscription.toARGB32()),
      Color(moduleColors['installments'] ?? AppColors.installment.toARGB32()),
      Color(moduleColors['vehicle'] ?? AppColors.vehicle.toARGB32()),
    ];
    final visible = [
      if (modules.contains('daily')) 0,
      if (modules.contains('subscriptions')) 1,
      if (modules.contains('installments')) 2,
      if (modules.contains('vehicle')) 3,
    ];
    final count = [1, 3, 6, 12][period];
    final selectedMonths = data.months.sublist(
      math.max(0, data.months.length - count),
    );
    final maxY = selectedMonths.fold<double>(
      0,
      (maximum, value) => math.max(maximum, value),
    );
    final categoryTotal = visible.fold<double>(
      0,
      (sum, index) => sum + data.categories[index],
    );
    final now = DateTime.now();
    final firstMonth = DateTime(
      now.year,
      now.month - selectedMonths.length + 1,
    );
    final currency = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Distribuzione mensile stimata',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Confronta le aree che incidono di più sul mese corrente.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (categoryTotal <= 0)
            const _EmptyAnalysis(message: 'Nessuna spesa nel periodo.')
          else ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 52,
                  sectionsSpace: 4,
                  sections: [
                    for (final index in visible)
                      if (data.categories[index] > 0)
                        PieChartSectionData(
                          value: data.categories[index],
                          color: colors[index],
                          radius: 42,
                          title:
                              '${(data.categories[index] / categoryTotal * 100).round()}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final index in visible)
                  _LegendDot(
                    color: colors[index],
                    label: labels[index],
                    value: currency.format(data.categories[index]),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Spesa nel tempo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Totali realmente registrati per ciascun mese.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (maxY <= 0)
            const _EmptyAnalysis(
              message: 'Non ci sono movimenti registrati in questo intervallo.',
            )
          else
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime(
                            firstMonth.year,
                            firstMonth.month + value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('MMM', 'it').format(date)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < selectedMonths.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: selectedMonths[index],
                            width: selectedMonths.length > 6 ? 12 : 22,
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Totale del periodo'),
              subtitle: Text('${selectedMonths.length} mesi considerati'),
              trailing: Text(
                currency.format(
                  selectedMonths.fold<double>(0, (a, b) => a + b),
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(radius: 5, backgroundColor: color),
      const SizedBox(width: 6),
      Text('$label · $value'),
    ],
  );
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
