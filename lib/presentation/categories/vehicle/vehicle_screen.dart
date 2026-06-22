import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: CategoryHeader(
            color: AppColors.vehicle,
            title: 'I tuoi veicoli',
            value: '0',
            subtitle: 'Auto e moto registrate',
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.directions_car,
            message: 'Aggiungi il tuo primo veicolo',
            action: () => context.go('/vehicle/add'),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.vehicle,
      onPressed: () => context.go('/vehicle/add'),
      child: const Icon(Icons.add),
    ),
  );
}

class VehicleDetailScreen extends StatefulWidget {
  const VehicleDetailScreen({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailState();
}

class _VehicleDetailState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this);
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Veicolo ${widget.vehicleId}'),
      bottom: TabBar(
        controller: tabs,
        tabs: const [
          Tab(text: 'Rifornimenti'),
          Tab(text: 'Manutenzione'),
        ],
      ),
    ),
    body: TabBarView(
      controller: tabs,
      children: [
        _FuelTab(id: widget.vehicleId),
        _MaintenanceTab(id: widget.vehicleId),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.go(
        '/vehicle/${widget.vehicleId}/${tabs.index == 0 ? 'fuel' : 'maintenance'}/add',
      ),
      child: const Icon(Icons.add),
    ),
  );
}

class _FuelTab extends StatelessWidget {
  const _FuelTab({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Row(
        children: [
          Expanded(
            child: Card(
              child: ListTile(title: Text('Totale'), subtitle: Text('€ 0,00')),
            ),
          ),
          Expanded(
            child: Card(
              child: ListTile(title: Text('Litri'), subtitle: Text('0 L')),
            ),
          ),
        ],
      ),
      SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 1,
            minY: 0,
            maxY: 2,
            lineBarsData: [
              LineChartBarData(
                spots: const [FlSpot(0, 0), FlSpot(1, 0)],
                color: AppColors.vehicle,
              ),
            ],
          ),
        ),
      ),
      const ListTile(
        leading: Icon(Icons.local_gas_station),
        title: Text('Nessun rifornimento'),
      ),
    ],
  );
}

class _MaintenanceTab extends StatelessWidget {
  const _MaintenanceTab({required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Wrap(
        spacing: 8,
        children:
            ['Tutti', 'Tagliando', 'Pneumatici', 'Freni', 'Elettrico', 'Altro']
                .map(
                  (x) => FilterChip(
                    label: Text(x),
                    selected: x == 'Tutti',
                    onSelected: (_) {},
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 24),
      const ListTile(
        leading: Icon(Icons.build),
        title: Text('Nessuna manutenzione registrata'),
      ),
    ],
  );
}
