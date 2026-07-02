import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/daily_expense.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/l10n/app_localizations.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';
import 'package:spendwise/presentation/dashboard/dashboard_layout_provider.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_preview.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_storage.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';
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
  Future<List<T>> safeList<T>(Future<List<T>> request) async {
    try {
      return await request.timeout(const Duration(seconds: 8));
    } catch (_) {
      return <T>[];
    }
  }

  final settings = ref.watch(settingsProvider);
  final modules = settings.visibleModules;
  final dio = ref.watch(dioClientProvider).dio;
  final now = DateTime.now();
  final from = DateTime(now.year, now.month - 11, 1);
  final results = await Future.wait([
    safeList<DailyExpense>(
      ExpensesApiClient(dio).getExpenses(
        settings.cloudBackupEnabled ? from.toIso8601String() : null,
        settings.cloudBackupEnabled ? now.toIso8601String() : null,
        null,
      ),
    ),
    safeList<dynamic>(SubscriptionsApiClient(dio).getAll()),
    safeList<dynamic>(InstallmentsApiClient(dio).getAll()),
    safeList<dynamic>(VehiclesApiClient(dio).getAll()),
  ]);
  final expenses = results[0] as List<DailyExpense>;
  final subscriptions = results[1];
  final installments = results[2];
  final vehicles = results[3];
  final vehicleApi = VehiclesApiClient(dio);
  final fuelLists = await Future.wait(
    vehicles.map((vehicle) => safeList(vehicleApi.fuel(vehicle.id as String))),
  );
  final maintenanceLists = await Future.wait(
    vehicles.map(
      (vehicle) => safeList(vehicleApi.maintenance(vehicle.id as String)),
    ),
  );
  final accessoryLists = await Future.wait(
    vehicles.map(
      (vehicle) => safeList(vehicleApi.accessories(vehicle.id as String)),
    ),
  );
  final monthTotals = List<double>.filled(12, 0);
  int monthIndex(DateTime date) =>
      (date.year - from.year) * 12 + date.month - from.month;

  if (modules.contains('daily')) {
    for (final expense in expenses) {
      final index = monthIndex(expense.date);
      if (index >= 0 && index < 12) monthTotals[index] += expense.amount;
    }
  }
  if (modules.contains('installments')) {
    for (final plan in installments) {
      if (plan.nextDueDate == null || plan.isActive != true) continue;
      final index = monthIndex(plan.nextDueDate as DateTime);
      if (index >= 0 && index < 12) {
        monthTotals[index] += plan.installmentAmount as double;
      }
    }
  }
  var vehicleMonth = 0.0;
  if (modules.contains('vehicle')) {
    for (final entries in fuelLists) {
      for (final entry in entries) {
        final index = monthIndex(entry.date);
        if (index >= 0 && index < 12) monthTotals[index] += entry.totalCost;
        if (entry.date.year == now.year && entry.date.month == now.month) {
          vehicleMonth += entry.totalCost;
        }
      }
    }
    for (final entries in maintenanceLists) {
      for (final entry in entries) {
        final index = monthIndex(entry.date);
        if (index >= 0 && index < 12) monthTotals[index] += entry.totalCost;
        if (entry.date.year == now.year && entry.date.month == now.month) {
          vehicleMonth += entry.totalCost;
        }
      }
    }
    for (final entries in accessoryLists) {
      for (final entry in entries) {
        final index = monthIndex(entry.date);
        if (index >= 0 && index < 12) monthTotals[index] += entry.totalCost;
        if (entry.date.year == now.year && entry.date.month == now.month) {
          vehicleMonth += entry.totalCost;
        }
      }
    }
  }
  final dailyMonth = modules.contains('daily')
      ? expenses
            .where(
              (expense) =>
                  expense.date.year == now.year &&
                  expense.date.month == now.month,
            )
            .fold<double>(0, (sum, expense) => sum + expense.amount)
      : 0.0;
  final subscriptionMonth = modules.contains('subscriptions')
      ? subscriptions
            .where((item) => item.isActive == true)
            .fold<double>(
              0,
              (sum, item) =>
                  sum +
                  switch (item.billingCycle as BillingCycle) {
                    BillingCycle.weekly => (item.amount as double) * 52 / 12,
                    BillingCycle.monthly =>
                      (item.amount as double) /
                          ((item.recurrenceMonths as int?) ?? 1),
                    BillingCycle.yearly => (item.amount as double) / 12,
                  },
            )
      : 0.0;
  final installmentMonth = modules.contains('installments')
      ? installments
            .where((item) => item.isActive == true)
            .fold<double>(
              0,
              (sum, item) => sum + (item.installmentAmount as double),
            )
      : 0.0;
  expenses.sort((a, b) => b.date.compareTo(a.date));
  return DashboardData(
    categories: [dailyMonth, subscriptionMonth, installmentMonth, vehicleMonth],
    months: monthTotals,
    recent: modules.contains('daily') ? expenses.take(6).toList() : const [],
  );
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  static const _securityPromptKey = 'initial_security_prompt_seen_v1';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerSecuritySetup());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _syncNow() async {
    final automatic = ref.read(settingsProvider).cloudBackupEnabled;
    showAppMessage(context, 'Sincronizzazione in corso…');
    final before = ref.read(syncInfoProvider).pending;
    final completed = await ref
        .read(syncServiceProvider)
        .sync(force: !automatic);
    if (!mounted) return;
    final info = ref.read(syncInfoProvider);
    showAppMessage(
      context,
      completed
          ? before > 0
                ? '$before modifiche salvate online.'
                : automatic
                ? 'Tutti i dati sono già sincronizzati.'
                : 'Backup manuale completato. La modalità locale resta attiva.'
          : info.error ?? 'Sincronizzazione non riuscita.',
    );
  }

  Future<void> _offerSecuritySetup() async {
    final preferences = await SharedPreferences.getInstance();
    final lock = ref.read(localUnlockProvider);
    if (!mounted ||
        lock.loading ||
        lock.protectionEnabled ||
        (preferences.getBool(_securityPromptKey) ?? false)) {
      return;
    }
    await preferences.setBool(_securityPromptKey, true);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Proteggi SpendWise',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Imposta un PIN e, se disponibile, Face ID o biometria per '
                'proteggere i dati salvati su questo dispositivo.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    this.context.push('/settings');
                  },
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: const Text('Configura sicurezza'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Più tardi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncServiceProvider);
    final sync = ref.watch(syncStatusProvider);
    final syncInfo = ref.watch(syncInfoProvider);
    final data = ref.watch(dashboardDataProvider);
    final layout = ref.watch(dashboardLayoutProvider);
    final settings = ref.watch(settingsProvider);
    final modules = settings.visibleModules;
    final avatarConfig =
        ref.watch(avatarBuilderConfigProvider).valueOrNull ??
        const AvatarBuilderConfig();
    final strings = AppLocalizations.of(context)!;
    final syncLabel = switch (sync) {
      SyncStatus.synced => strings.syncSynced,
      SyncStatus.pending =>
        syncInfo.pending > 0
            ? '${syncInfo.pending} modifiche in attesa'
            : strings.syncPending,
      SyncStatus.syncing => strings.syncInProgress,
      SyncStatus.offline => strings.syncOffline,
      SyncStatus.error => syncInfo.error ?? strings.syncError,
    };

    return Scaffold(
      body: SafeArea(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DashboardError(
            expired: error.toString().contains('401'),
            onRetry: () => ref.invalidate(dashboardDataProvider),
            onLogout: () => ref.read(authStateProvider.notifier).logout(),
          ),
          data: (summary) => Scrollbar(
            controller: _scrollController,
            thumbVisibility: MediaQuery.sizeOf(context).width >= 600,
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dashboardDataProvider.future),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Panoramica',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(letterSpacing: -.8),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          switch (sync) {
                                            SyncStatus.offline =>
                                              Icons.cloud_off_rounded,
                                            SyncStatus.error =>
                                              Icons.sync_problem_rounded,
                                            SyncStatus.syncing =>
                                              Icons.cloud_sync_rounded,
                                            _ => Icons.cloud_done_rounded,
                                          },
                                          size: 15,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            syncLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Invia al server le modifiche salvate sul dispositivo',
                                onPressed: sync == SyncStatus.syncing
                                    ? null
                                    : _syncNow,
                                icon: Icon(
                                  sync == SyncStatus.syncing
                                      ? Icons.sync_rounded
                                      : Icons.refresh_rounded,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Analisi',
                                onPressed: () => context.push('/analytics'),
                                icon: const Icon(Icons.insights_rounded),
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message: 'Profilo e impostazioni',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => context.push('/settings'),
                                  child: _DashboardAvatar(
                                    settings: settings,
                                    config: avatarConfig,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: DashboardOverview(
                      data: summary,
                      modules: modules,
                      onOpen: (path) => context.go(path),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                'Personalizzazione',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _showWidgetEditor(context),
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Modifica'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: LayoutBuilder(
                          builder: (context, constraints) => _WidgetGrid(
                            width: constraints.maxWidth,
                            configs: layout
                                .where((item) => item.visible)
                                .toList(),
                            builder: (config) =>
                                _buildWidget(config.id, summary, modules),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: modules.contains('daily')
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/daily/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuova spesa'),
            )
          : null,
    );
  }

  Widget _buildWidget(String id, DashboardData data, Set<String> modules) =>
      switch (id) {
        'quick' => _QuickActionsWidget(modules: modules),
        'categories' => _CategoriesWidget(data: data, modules: modules),
        'trend' => _TrendWidget(data: data),
        'recent' => _RecentWidget(data: data),
        _ => const SizedBox.shrink(),
      };

  Future<void> _showWidgetEditor(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const DashboardWidgetEditorSheet(),
      );
}

class _DashboardAvatar extends StatelessWidget {
  const _DashboardAvatar({required this.settings, required this.config});

  final SettingsState settings;
  final AvatarBuilderConfig config;

  @override
  Widget build(BuildContext context) {
    final photo = settings.avatarData;
    if (photo != null) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(photo.split(',').last),
            width: 46,
            height: 46,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        // In caso di foto corrotta viene usato l'avatar configurato.
      }
    }
    return SizedBox.square(
      dimension: 46,
      child: AvatarBuilderPreview(config: config, overrideSize: 46),
    );
  }
}

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    required this.data,
    required this.modules,
    required this.onOpen,
    super.key,
  });

  final DashboardData data;
  final Set<String> modules;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final cards = <({String title, double value, Color color, String path})>[
      (
        title: 'Spese del mese',
        value: data.total,
        color: const Color(0xFF1378F5),
        path: '/analytics',
      ),
      if (modules.contains('daily'))
        (
          title: 'Spese quotidiane',
          value: data.categories[0],
          color: AppColors.daily,
          path: '/daily',
        ),
      if (modules.contains('subscriptions'))
        (
          title: 'Abbonamenti',
          value: data.categories[1],
          color: AppColors.subscription,
          path: '/subscriptions',
        ),
      if (modules.contains('installments'))
        (
          title: 'Rate',
          value: data.categories[2],
          color: AppColors.installment,
          path: '/installments',
        ),
      if (modules.contains('vehicle'))
        (
          title: 'Veicoli',
          value: data.categories[3],
          color: AppColors.vehicle,
          path: '/vehicle',
        ),
    ];
    Widget buildCard(int index, double width) => SizedBox(
      width: width,
      height: 176,
      child: _OverviewCard(
        data: cards[index],
        primary: index == 0,
        onTap: () => onOpen(cards[index].path),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SizedBox(
            height: 176,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => buildCard(index, 260),
            ),
          );
        }
        const gap = 12.0;
        final available = math.min(constraints.maxWidth, 1180) - 40;
        final columns = available >= 1050
            ? cards.length
            : available >= 720
            ? 3
            : 2;
        final cardWidth = (available - gap * (columns - 1)) / columns;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < cards.length; index++)
                    buildCard(index, cardWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.data,
    required this.primary,
    required this.onTap,
  });

  final ({String title, double value, Color color, String path}) data;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: primary
        ? data.color
        : Theme.of(context).colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(
        color: primary
            ? data.color
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  primary
                      ? Icons.account_balance_wallet_rounded
                      : Icons.arrow_outward_rounded,
                  size: 20,
                  color: primary ? Colors.white : data.color,
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: primary
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.title,
              style: TextStyle(
                color: primary
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currency(data.value),
              style: TextStyle(
                color: primary
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WidgetGrid extends StatelessWidget {
  const _WidgetGrid({
    required this.width,
    required this.configs,
    required this.builder,
  });

  final double width;
  final List<DashboardWidgetConfig> configs;
  final Widget Function(DashboardWidgetConfig config) builder;

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    final contentWidth = math.max(0, width - 40).toDouble();
    final columns = width >= 900 ? 4 : 2;
    final unit = (contentWidth - gap * (columns - 1)) / columns;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final config in configs)
            SizedBox(
              width: config.size == DashboardWidgetSize.wide
                  ? contentWidth
                  : width >= 900
                  ? unit * 2 + gap
                  : unit,
              height: config.size == DashboardWidgetSize.wide
                  ? (width >= 700 ? 250 : 230)
                  : width >= 900
                  ? unit * .78
                  : unit * 1.08,
              child: builder(config),
            ),
        ],
      ),
    );
  }
}

class _DashboardWidgetCard extends StatelessWidget {
  const _DashboardWidgetCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _QuickActionsWidget extends StatelessWidget {
  const _QuickActionsWidget({required this.modules});

  final Set<String> modules;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (modules.contains('daily'))
        ('Spesa', Icons.receipt_long_rounded, '/daily/add'),
      if (modules.contains('subscriptions'))
        ('Abbonamento', Icons.autorenew_rounded, '/subscriptions/add'),
      if (modules.contains('installments'))
        ('Piano rateale', Icons.credit_card_rounded, '/installments/add'),
      if (modules.contains('vehicle'))
        ('Veicolo', Icons.directions_car_rounded, '/vehicle/add'),
    ];
    return _DashboardWidgetCard(
      title: 'Azioni rapide',
      icon: Icons.bolt_rounded,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              FilledButton.tonalIcon(
                onPressed: () => context.push(action.$3),
                icon: Icon(action.$2),
                label: Text(action.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesWidget extends ConsumerWidget {
  const _CategoriesWidget({required this.data, required this.modules});

  final DashboardData data;
  final Set<String> modules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = [
      settings.moduleColor('daily'),
      settings.moduleColor('subscriptions'),
      settings.moduleColor('installments'),
      settings.moduleColor('vehicle'),
    ];
    final visible = [
      if (modules.contains('daily')) 0,
      if (modules.contains('subscriptions')) 1,
      if (modules.contains('installments')) 2,
      if (modules.contains('vehicle')) 3,
    ];
    return _DashboardWidgetCard(
      title: 'Categorie',
      icon: Icons.donut_large_rounded,
      onTap: () => context.push('/analytics'),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 30,
                sectionsSpace: 3,
                sections: [
                  for (final index in visible)
                    PieChartSectionData(
                      value: data.categories[index] <= 0
                          ? .001
                          : data.categories[index],
                      color: colors[index],
                      radius: 20,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final index in visible)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: colors[index]),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            ['Spese', 'Abbonamenti', 'Rate', 'Veicoli'][index],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'it_IT',
                            symbol: '€',
                          ).format(data.categories[index]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendWidget extends StatelessWidget {
  const _TrendWidget({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final values = data.months.length > 6
        ? data.months.sublist(data.months.length - 6)
        : data.months;
    final now = DateTime.now();
    return _DashboardWidgetCard(
      title: 'Ultimi 6 mesi',
      icon: Icons.show_chart_rounded,
      onTap: () => context.push('/analytics'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 6),
        child: LineChart(
          LineChartData(
            minY: 0,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
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
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime(
                      now.year,
                      now.month - values.length + 1 + value.toInt(),
                    );
                    return Text(DateFormat('MMM', 'it').format(date));
                  },
                ),
              ),
            ),
            lineTouchData: const LineTouchData(enabled: true),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var index = 0; index < values.length; index++)
                    FlSpot(index.toDouble(), values[index]),
                ],
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentWidget extends StatelessWidget {
  const _RecentWidget({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) => _DashboardWidgetCard(
    title: 'Ultime spese',
    icon: Icons.history_rounded,
    onTap: () => context.go('/daily'),
    child: data.recent.isEmpty
        ? const Center(child: Text('Nessuna spesa recente'))
        : ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(data.recent.length, 3),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = data.recent[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.daily.withValues(alpha: .14),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.daily,
                  ),
                ),
                title: Text(
                  expense.description ?? 'Spesa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('dd MMM', 'it').format(expense.date.toLocal()),
                ),
                trailing: Text(
                  _currency(expense.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
  );
}

class DashboardWidgetEditorSheet extends ConsumerWidget {
  const DashboardWidgetEditorSheet({super.key});

  static const metadata = {
    'quick': ('Azioni rapide', Icons.bolt_rounded),
    'categories': ('Categorie', Icons.donut_large_rounded),
    'trend': ('Ultimi 6 mesi', Icons.show_chart_rounded),
    'recent': ('Ultime spese', Icons.history_rounded),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(dashboardLayoutProvider);
    return SafeArea(
      child: SizedBox(
        height: math.min(MediaQuery.sizeOf(context).height * .82, 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personalizza panoramica',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(dashboardLayoutProvider.notifier).reset(),
                    child: const Text('Ripristina'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Trascina per riordinare e scegli 4×4 o 4×8.'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: layout.length,
                onReorderItem: (oldIndex, newIndex) => ref
                    .read(dashboardLayoutProvider.notifier)
                    .reorder(oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final item = layout[index];
                  final details = metadata[item.id]!;
                  return Card(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator_rounded),
                          const SizedBox(width: 8),
                          Icon(
                            details.$2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(details.$1)),
                          SegmentedButton<DashboardWidgetSize>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: DashboardWidgetSize.square,
                                label: Text('4×4'),
                              ),
                              ButtonSegment(
                                value: DashboardWidgetSize.wide,
                                label: Text('4×8'),
                              ),
                            ],
                            selected: {item.size},
                            onSelectionChanged: (value) => ref
                                .read(dashboardLayoutProvider.notifier)
                                .setSize(item.id, value.first),
                          ),
                          Switch(
                            value: item.visible,
                            onChanged: (value) => ref
                                .read(dashboardLayoutProvider.notifier)
                                .setVisible(item.id, value),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.expired,
    required this.onRetry,
    required this.onLogout,
  });

  final bool expired;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired ? Icons.lock_clock_rounded : Icons.cloud_off_rounded,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              expired
                  ? 'La sessione è scaduta'
                  : 'Panoramica temporaneamente non disponibile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              expired
                  ? 'Accedi nuovamente per proteggere i tuoi dati.'
                  : 'Controlla la connessione e riprova.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: expired ? onLogout : onRetry,
              icon: Icon(expired ? Icons.login_rounded : Icons.refresh_rounded),
              label: Text(expired ? 'Torna al login' : 'Riprova'),
            ),
          ],
        ),
      ),
    ),
  );
}

String _currency(double value) =>
    NumberFormat.currency(locale: 'it_IT', symbol: '€').format(value);
