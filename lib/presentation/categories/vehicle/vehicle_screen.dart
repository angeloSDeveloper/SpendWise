import 'dart:convert';

import 'package:dio/dio.dart' show Dio, Options;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/domain/models/fuel_entry.dart';
import 'package:spendwise/domain/models/vehicle_maintenance.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';
import 'package:url_launcher/url_launcher.dart';

final vehiclesApiProvider = Provider(
  (ref) => VehiclesApiClient(ref.watch(dioClientProvider).dio),
);
final vehiclesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(vehiclesApiProvider).getAll(),
);
final fuelEntriesProvider = FutureProvider.autoDispose
    .family<List<FuelEntry>, String>(
      (ref, id) => ref.watch(vehiclesApiProvider).fuel(id),
    );
final maintenanceEntriesProvider = FutureProvider.autoDispose
    .family<List<VehicleMaintenance>, String>(
      (ref, id) => ref.watch(vehiclesApiProvider).maintenance(id),
    );

String _money(num value) =>
    NumberFormat.currency(locale: 'it_IT', symbol: '€').format(value);
String _date(DateTime value) =>
    DateFormat('dd/MM/yyyy').format(value.toLocal());

class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(vehiclesProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CategoryHeader(
                color: AppColors.vehicle,
                title: 'I tuoi veicoli',
                value: vehicles.valueOrNull?.length.toString() ?? '–',
                subtitle: 'Auto e moto registrate',
              ),
            ),
            vehicles.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Text('Impossibile caricare i veicoli: $error'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.directions_car,
                        message: 'Aggiungi il tuo primo veicolo',
                        action: () => context.push('/vehicle/add'),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final vehicle = items[index];
                          final details = <String>[
                            if (vehicle.plate?.isNotEmpty == true)
                              vehicle.plate!,
                            if (vehicle.brand?.isNotEmpty == true)
                              vehicle.brand!,
                            if (vehicle.model?.isNotEmpty == true)
                              vehicle.model!,
                            if (vehicle.year != null) '${vehicle.year}',
                          ];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.directions_car),
                              ),
                              title: Text(vehicle.name),
                              subtitle: details.isEmpty
                                  ? null
                                  : Text(details.join(' · ')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/vehicle/${vehicle.id}'),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.vehicle,
        onPressed: () => context.push('/vehicle/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});
  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final plate = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final year = TextEditingController();
  String fuelType = 'gasoline';
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [name, plate, brand, model, year]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final vehicle = await ref.read(vehiclesApiProvider).create({
        'name': name.text.trim(),
        'plate': plate.text.trim().toUpperCase(),
        'brand': brand.text.trim(),
        'model': model.text.trim(),
        'year': int.tryParse(year.text),
        'fuelType': fuelType,
      });
      ref.invalidate(vehiclesProvider);
      if (mounted) context.go('/vehicle/${vehicle.id}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvataggio non riuscito: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuovo veicolo')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Targa *',
              prefixIcon: Icon(Icons.pin),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Inserisci la targa'
                : null,
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Riconoscimento automatico dalla targa'),
              subtitle: Text(
                'Richiede il collegamento a un fornitore autorizzato di dati veicolo. Per ora completa i dati manualmente.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _requiredField(name, 'Nome / descrizione', 'Es. Auto di Angelo'),
          _field(brand, 'Marca', hint: 'Es. Fiat'),
          _field(model, 'Modello e allestimento', hint: 'Es. Panda 1.2 Lounge'),
          TextFormField(
            controller: year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Anno di immatricolazione',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final parsed = int.tryParse(value);
              return parsed == null ||
                      parsed < 1900 ||
                      parsed > DateTime.now().year + 1
                  ? 'Anno non valido'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: fuelType,
            decoration: const InputDecoration(labelText: 'Alimentazione'),
            items:
                const {
                      'gasoline': 'Benzina',
                      'diesel': 'Diesel',
                      'electric': 'Elettrica',
                      'hybrid': 'Ibrida',
                      'lpg': 'GPL',
                    }.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged: (value) => fuelType = value!,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Salva veicolo'),
          ),
        ],
      ),
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  String? hint,
  TextInputType? keyboard,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    keyboardType: keyboard,
    decoration: InputDecoration(labelText: label, hintText: hint),
  ),
);
Widget _requiredField(
  TextEditingController controller,
  String label,
  String hint,
) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: '$label *', hintText: hint),
    validator: (value) =>
        value == null || value.trim().isEmpty ? 'Campo obbligatorio' : null,
  ),
);

class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailState();
}

class _VehicleDetailState extends ConsumerState<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref
        .watch(vehiclesProvider)
        .valueOrNull
        ?.where((item) => item.id == widget.vehicleId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle?.name ?? 'Veicolo'),
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: 'Rifornimenti'),
            Tab(icon: Icon(Icons.build), text: 'Manutenzione'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final type = tabs.index == 0 ? 'fuel' : 'maintenance';
          await context.push('/vehicle/${widget.vehicleId}/$type/add');
        },
        icon: const Icon(Icons.add),
        label: Text(tabs.index == 0 ? 'Rifornimento' : 'Manutenzione'),
      ),
    );
  }
}

class _FuelTab extends ConsumerWidget {
  const _FuelTab({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(fuelEntriesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (items) {
          final total = items.fold<double>(
            0,
            (sum, item) => sum + item.totalCost,
          );
          final liters = items.fold<double>(
            0,
            (sum, item) => sum + item.liters,
          );
          return RefreshIndicator(
            onRefresh: () => ref.refresh(fuelEntriesProvider(id).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(child: _summary('Spesa totale', _money(total))),
                    Expanded(
                      child: _summary(
                        'Carburante',
                        '${liters.toStringAsFixed(1)} L',
                      ),
                    ),
                  ],
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text('Nessun rifornimento registrato'),
                    ),
                  ),
                for (final item in items)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_gas_station),
                      title: Text(
                        item.liters > 0
                            ? '${item.liters.toStringAsFixed(2)} L · ${_money(item.totalCost)}'
                            : 'Rifornimento · ${_money(item.totalCost)}',
                      ),
                      subtitle: Text(
                        [
                          _date(item.date),
                          if (item.stationName?.isNotEmpty == true)
                            item.stationName!,
                          if (item.kmOdometer != null) '${item.kmOdometer} km',
                        ].join(' · '),
                      ),
                      trailing: item.pricePerLiter > 0
                          ? Text('${item.pricePerLiter.toStringAsFixed(3)} €/L')
                          : const Text('Semplificato'),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

Widget _summary(String title, String value) => Card(
  child: ListTile(
    title: Text(title),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
);

class _MaintenanceTab extends ConsumerWidget {
  const _MaintenanceTab({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(maintenanceEntriesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(maintenanceEntriesProvider(id).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _summary(
                'Totale manutenzione',
                _money(
                  items.fold<double>(0, (sum, item) => sum + item.totalCost),
                ),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('Nessuna manutenzione registrata')),
                ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                if (MediaQuery.sizeOf(context).width >= 900)
                  _MaintenanceRegister(
                    items: items,
                    onOpen: (item) => _showMaintenanceDetails(context, item),
                  )
                else
                  for (final item in items)
                    _MaintenanceCard(
                      item: item,
                      onOpen: () => _showMaintenanceDetails(context, item),
                    ),
              ],
            ],
          ),
        ),
      );
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.item, required this.onOpen});
  final VehicleMaintenance item;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: _maintenanceImage(item.receiptUrl),
      title: Text(item.itemName),
      subtitle: Text(
        [
          _date(item.date),
          if (item.kmAtService != null) '${item.kmAtService} km',
          if (item.partCode?.isNotEmpty == true) 'Cod. ${item.partCode}',
          if (item.shopName?.isNotEmpty == true) item.shopName!,
        ].join(' · '),
      ),
      trailing: Text(_money(item.totalCost)),
      onTap: onOpen,
    ),
  );
}

class _MaintenanceRegister extends StatelessWidget {
  const _MaintenanceRegister({required this.items, required this.onOpen});
  final List<VehicleMaintenance> items;
  final ValueChanged<VehicleMaintenance> onOpen;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.table_chart),
              const SizedBox(width: 10),
              Text(
                'Registro manutenzione',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const Text('Scorri orizzontalmente e seleziona una riga'),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columns: const [
              DataColumn(label: Text('DATA')),
              DataColumn(label: Text('KM')),
              DataColumn(label: Text('INTERVENTO')),
              DataColumn(label: Text('VENDITORE / NEGOZIO')),
              DataColumn(label: Text('MANODOPERA / OFFICINA')),
              DataColumn(label: Text('OLIO')),
              DataColumn(label: Text('FILTRI / RICAMBI')),
              DataColumn(label: Text('DISTRIBUZIONE')),
              DataColumn(label: Text('FRENI')),
              DataColumn(label: Text('ALTRO / NOTE')),
              DataColumn(label: Text('TOTALE')),
            ],
            rows: items.map((item) {
              final details = _MaintenanceDetails.from(item);
              DataCell cell(String value, {double width = 150}) => DataCell(
                SizedBox(
                  width: width,
                  child: Text(
                    value.isEmpty ? '—' : value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
              return DataRow(
                onSelectChanged: (_) => onOpen(item),
                cells: [
                  cell(_date(item.date), width: 82),
                  cell(item.kmAtService?.toString() ?? '', width: 72),
                  cell(item.itemName, width: 190),
                  cell(details.seller, width: 160),
                  cell(details.labor, width: 180),
                  cell(details.oil, width: 180),
                  cell(details.filters, width: 220),
                  cell(details.distribution, width: 220),
                  cell(details.brakes, width: 220),
                  cell(details.other, width: 220),
                  cell(_money(item.totalCost), width: 90),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

class _MaintenanceDetails {
  const _MaintenanceDetails({
    required this.labor,
    required this.seller,
    required this.oil,
    required this.filters,
    required this.distribution,
    required this.brakes,
    required this.other,
  });
  final String labor, seller, oil, filters, distribution, brakes, other;

  factory _MaintenanceDetails.from(VehicleMaintenance item) {
    final groups = <String, List<String>>{
      'labor': [],
      'seller': [],
      'oil': [],
      'filters': [],
      'distribution': [],
      'brakes': [],
      'other': [],
    };
    final pieces = (item.note ?? '')
        .split(RegExp(r'[;\n]|\.\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    for (final part in pieces) {
      final text = part.toLowerCase();
      final target = RegExp(r'olio|selenia|motul|actual|5w|10w').hasMatch(text)
          ? 'oil'
          : RegExp(
              r'filtro|ufi|sofima|zaffo|ox\d|lx\d|lh\d|la\d',
            ).hasMatch(text)
          ? 'filters'
          : RegExp(
              r'distribuz|cinghia|galoppin|pompa|dayco|repkit|valeo',
            ).hasMatch(text)
          ? 'distribution'
          : RegExp(
              r'fren|pastigl|pattin|dischi|brembo|ferodo|bosch|bp337',
            ).hasMatch(text)
          ? 'brakes'
          : RegExp(
              r'aiello|tonino|sellia|folino|buffa|calabra|manodopera',
            ).hasMatch(text)
          ? 'labor'
          : 'other';
      groups[target]!.add(part);
    }
    if (item.shopName?.isNotEmpty == true) {
      groups['seller']!.add(item.shopName!);
    }
    if (item.partCode?.isNotEmpty == true) {
      groups['filters']!.add('Codice: ${item.partCode}');
    }
    return _MaintenanceDetails(
      labor: groups['labor']!.join('\n'),
      seller: groups['seller']!.join('\n'),
      oil: groups['oil']!.join('\n'),
      filters: groups['filters']!.join('\n'),
      distribution: groups['distribution']!.join('\n'),
      brakes: groups['brakes']!.join('\n'),
      other: groups['other']!.join('\n'),
    );
  }
}

Future<void> _showMaintenanceDetails(
  BuildContext context,
  VehicleMaintenance item,
) {
  final panel = _MaintenanceDetailPanel(item: item);
  if (MediaQuery.sizeOf(context).width >= 700) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 820),
          child: panel,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(heightFactor: .92, child: panel),
  );
}

class _MaintenanceDetailPanel extends ConsumerWidget {
  const _MaintenanceDetailPanel({required this.item});
  final VehicleMaintenance item;

  Future<void> edit(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AddMaintenanceScreen(vehicleId: item.vehicleId, existing: item),
      ),
    );
    if (changed == true && context.mounted) Navigator.pop(context);
  }

  Future<void> delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Eliminare questo intervento?'),
        content: Text(
          '“${item.itemName}” verrà eliminato definitivamente dal registro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(vehiclesApiProvider)
          .deleteMaintenance(item.vehicleId, item.id);
      ref.invalidate(maintenanceEntriesProvider(item.vehicleId));
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eliminazione non riuscita: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = _MaintenanceDetails.from(item);
    final sections = <(String, String, Color, IconData)>[
      (
        'VENDITORE / NEGOZIO',
        details.seller,
        const Color(0xFFBFC8F2),
        Icons.storefront,
      ),
      (
        'MANODOPERA / OFFICINA',
        details.labor,
        const Color(0xFFE8A5A5),
        Icons.engineering,
      ),
      ('OLIO', details.oil, const Color(0xFFB8DDD3), Icons.oil_barrel),
      (
        'FILTRI E RICAMBI',
        details.filters,
        const Color(0xFFAEDDE5),
        Icons.filter_alt,
      ),
      (
        'DISTRIBUZIONE',
        details.distribution,
        const Color(0xFFF0C27B),
        Icons.settings,
      ),
      ('FRENI', details.brakes, const Color(0xFFD5D8CE), Icons.album),
      ('ALTRO / NOTE', details.other, const Color(0xFFD7C7E8), Icons.notes),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 12, 18),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              const Icon(Icons.build_circle, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      _categoryLabel(
                        item.category ?? MaintenanceCategory.altro,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modifica',
                onPressed: () => edit(context),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Elimina',
                onPressed: () => delete(context, ref),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              IconButton(
                tooltip: 'Chiudi',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoBox(
                      icon: Icons.calendar_today,
                      label: 'DATA',
                      value: _date(item.date),
                    ),
                    _InfoBox(
                      icon: Icons.speed,
                      label: 'CHILOMETRAGGIO',
                      value: item.kmAtService == null
                          ? 'Non indicato'
                          : '${NumberFormat.decimalPattern('it_IT').format(item.kmAtService)} km',
                    ),
                    _InfoBox(
                      icon: Icons.euro,
                      label: 'COSTO TOTALE',
                      value: _money(item.totalCost),
                    ),
                    _InfoBox(
                      icon: Icons.inventory_2,
                      label: 'QUANTITÀ',
                      value: '${item.quantity}',
                    ),
                  ],
                ),
                if (item.receiptUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 240,
                    child: Center(
                      child: _maintenanceImage(
                        item.receiptUrl,
                        width: 320,
                        height: 230,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 900
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth >= 580
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final section in sections)
                          SizedBox(
                            width: width,
                            child: _DetailSection(
                              title: section.$1,
                              text: section.$2,
                              color: section.$3,
                              icon: section.$4,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                if (item.shopUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(item.shopUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apri il sito del prodotto'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    width: 245,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.text,
    required this.color,
    required this.icon,
  });
  final String title, text;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 150),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SelectableText(text.isEmpty ? 'Nessun dato registrato' : text),
        ),
      ],
    ),
  );
}

Widget _maintenanceImage(
  String? source, {
  double width = 48,
  double height = 48,
}) {
  if (source == null || source.isEmpty) {
    return const Icon(Icons.build_circle_outlined);
  }
  if (source.startsWith('data:image')) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(source.split(',').last),
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {}
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.build_circle_outlined),
    ),
  );
}

class AddFuelScreen extends ConsumerStatefulWidget {
  const AddFuelScreen({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  ConsumerState<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends ConsumerState<AddFuelScreen> {
  final formKey = GlobalKey<FormState>();
  final liters = TextEditingController(),
      price = TextEditingController(),
      total = TextEditingController(),
      station = TextEditingController(),
      km = TextEditingController(),
      note = TextEditingController();
  bool fullTank = true, saving = false, detailed = false, calculating = false;
  String calculateField = 'total';
  double number(TextEditingController value) =>
      double.tryParse(value.text.replaceAll(',', '.')) ?? 0;

  @override
  void initState() {
    super.initState();
    for (final controller in [liters, price, total]) {
      controller.addListener(calculate);
    }
  }

  void calculate() {
    if (calculating || !detailed) return;
    calculating = true;
    final l = number(liters), p = number(price), t = number(total);
    final result = switch (calculateField) {
      'liters' => p > 0 && t > 0 ? t / p : 0,
      'price' => l > 0 && t > 0 ? t / l : 0,
      _ => l > 0 && p > 0 ? l * p : 0,
    };
    final target = switch (calculateField) {
      'liters' => liters,
      'price' => price,
      _ => total,
    };
    final text = result > 0
        ? result.toStringAsFixed(calculateField == 'price' ? 3 : 2)
        : '';
    if (target.text != text) target.text = text;
    calculating = false;
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [liters, price, total, station, km, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (number(total) <= 0 ||
        (detailed && (number(liters) <= 0 || number(price) <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa i valori del rifornimento')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await ref.read(vehiclesApiProvider).addFuel(widget.vehicleId, {
        'date': DateTime.now().millisecondsSinceEpoch,
        'liters': detailed ? number(liters) : 0.0,
        'pricePerLiter': detailed ? number(price) : 0.0,
        'totalCost': number(total),
        'stationName': station.text.trim(),
        'kmOdometer': int.tryParse(km.text),
        'isFullTank': fullTank ? 1 : 0,
        'note': note.text.trim(),
      });
      ref.invalidate(fuelEntriesProvider(widget.vehicleId));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvataggio non riuscito: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuovo rifornimento')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.flash_on),
                label: Text('Semplificato'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.calculate),
                label: Text('Dettagliato'),
              ),
            ],
            selected: {detailed},
            onSelectionChanged: (value) => setState(() {
              detailed = value.first;
              calculate();
            }),
          ),
          const SizedBox(height: 16),
          if (detailed) ...[
            const Text('Scegli quale valore calcolare automaticamente:'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'total', label: Text('Totale')),
                ButtonSegment(value: 'liters', label: Text('Litri')),
                ButtonSegment(value: 'price', label: Text('€/L')),
              ],
              selected: {calculateField},
              onSelectionChanged: (value) => setState(() {
                calculateField = value.first;
                calculate();
              }),
            ),
            const SizedBox(height: 16),
            _fuelNumber(liters, 'Litri', enabled: calculateField != 'liters'),
            _fuelNumber(
              price,
              'Prezzo al litro (€)',
              enabled: calculateField != 'price',
            ),
          ],
          _fuelNumber(
            total,
            'Importo totale (€)',
            enabled: !detailed || calculateField != 'total',
          ),
          if (!detailed)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Inserisci soltanto quanto hai speso. Usa la modalità dettagliata quando conosci litri e prezzo.',
              ),
            ),
          _field(station, 'Distributore'),
          _field(km, 'Chilometraggio', keyboard: TextInputType.number),
          SwitchListTile(
            value: fullTank,
            onChanged: (value) => setState(() => fullTank = value),
            title: const Text('Pieno completo'),
          ),
          _field(note, 'Note'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save),
            label: const Text('Salva rifornimento'),
          ),
        ],
      ),
    ),
  );
}

Widget _fuelNumber(
  TextEditingController controller,
  String label, {
  required bool enabled,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: '$label *',
      suffixIcon: enabled ? null : const Icon(Icons.auto_awesome),
    ),
  ),
);

Widget _numberRequired(TextEditingController controller, String label) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label *'),
        validator: (value) =>
            (double.tryParse((value ?? '').replaceAll(',', '.')) ?? 0) <= 0
            ? 'Inserisci un valore valido'
            : null,
      ),
    );

String _categoryLabel(MaintenanceCategory category) => switch (category) {
  MaintenanceCategory.tagliando => 'TAGLIANDO',
  MaintenanceCategory.pneumatici => 'PNEUMATICI',
  MaintenanceCategory.freni => 'FRENI',
  MaintenanceCategory.elettrico => 'ELETTRICO',
  MaintenanceCategory.batteria => 'BATTERIA',
  MaintenanceCategory.carrozzeria => 'CARROZZERIA',
  MaintenanceCategory.altro => 'ALTRO',
};

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  const AddMaintenanceScreen({
    required this.vehicleId,
    this.existing,
    super.key,
  });
  final String vehicleId;
  final VehicleMaintenance? existing;
  @override
  ConsumerState<AddMaintenanceScreen> createState() =>
      _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final formKey = GlobalKey<FormState>();
  final item = TextEditingController(),
      code = TextEditingController(),
      price = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      shop = TextEditingController(),
      url = TextEditingController(),
      km = TextEditingController(),
      nextKm = TextEditingController(),
      warranty = TextEditingController(),
      note = TextEditingController();
  late MaintenanceCategory category;
  late DateTime selectedDate;
  bool saving = false, lookingUp = false;
  String? imageData;
  double amount() => double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
  int qty() => int.tryParse(quantity.text) ?? 1;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    category = existing?.category ?? MaintenanceCategory.tagliando;
    selectedDate = existing?.date.toLocal() ?? DateTime.now();
    if (existing != null) {
      item.text = existing.itemName;
      code.text = existing.partCode ?? '';
      price.text = existing.price.toStringAsFixed(2);
      quantity.text = existing.quantity.toString();
      shop.text = existing.shopName ?? '';
      url.text = existing.shopUrl ?? '';
      km.text = existing.kmAtService?.toString() ?? '';
      nextKm.text = existing.nextServiceKm?.toString() ?? '';
      warranty.text = existing.warrantyMonths?.toString() ?? '';
      note.text = existing.note ?? '';
      imageData = existing.receiptUrl;
    }
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELEZIONA LA DATA DELL’INTERVENTO',
      cancelText: 'ANNULLA',
      confirmText: 'CONFERMA',
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 900,
      imageQuality: 55,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    setState(() => imageData = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  Future<void> scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.isEmpty) return;
    code.text = barcode;
    await lookupBarcode(barcode);
  }

  Future<void> lookupBarcode(String barcode) async {
    setState(() => lookingUp = true);
    try {
      final response = await Dio().get<Map<String, dynamic>>(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
        options: Options(headers: {'User-Agent': 'SpendWise/1.0'}),
      );
      final data = response.data;
      final product = data?['product'];
      if (data?['status'] == 1 && product is Map<String, dynamic>) {
        final productName =
            product['product_name_it'] ?? product['product_name'];
        final brand = product['brands'];
        if (productName is String && productName.isNotEmpty) {
          item.text = productName;
        }
        if (product['image_url'] is String) {
          imageData = product['image_url'] as String;
        }
        final details = [
          if (brand is String && brand.isNotEmpty) 'Marca: $brand',
          if (product['quantity'] is String) 'Formato: ${product['quantity']}',
        ];
        if (details.isNotEmpty) {
          note.text =
              '${details.join(' · ')}${note.text.isEmpty ? '' : '\n${note.text}'}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prodotto trovato: dati compilati automaticamente'),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Codice letto, ma prodotto non presente nel catalogo pubblico',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Codice letto. Catalogo non raggiungibile: completa i dati manualmente',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => lookingUp = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      item,
      code,
      price,
      quantity,
      shop,
      url,
      km,
      nextKm,
      warranty,
      note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final body = <String, dynamic>{
        'date': selectedDate.millisecondsSinceEpoch,
        'itemName': item.text.trim(),
        'partCode': code.text.trim(),
        'category': category.name,
        'price': amount(),
        'quantity': qty(),
        'totalCost': amount() * qty(),
        'shopName': shop.text.trim(),
        'shopUrl': url.text.trim(),
        'kmAtService': int.tryParse(km.text),
        'nextServiceKm': int.tryParse(nextKm.text),
        'warrantyMonths': int.tryParse(warranty.text),
        'receiptUrl': imageData,
        'note': note.text.trim(),
      };
      final api = ref.read(vehiclesApiProvider);
      if (widget.existing == null) {
        await api.addMaintenance(widget.vehicleId, body);
      } else {
        await api.updateMaintenance(
          widget.vehicleId,
          widget.existing!.id,
          body,
        );
      }
      ref.invalidate(maintenanceEntriesProvider(widget.vehicleId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvataggio non riuscito: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null
            ? 'Nuova manutenzione'
            : 'Modifica manutenzione',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: selectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data intervento *',
                prefixIcon: Icon(Icons.calendar_month),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                DateFormat('EEEE d MMMM yyyy', 'it').format(selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _requiredField(
            item,
            'Ricambio, liquido o intervento',
            'Es. Olio motore 5W-30',
          ),
          DropdownButtonFormField<MaintenanceCategory>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: MaintenanceCategory.values
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(_categoryLabel(v)),
                  ),
                )
                .toList(),
            onChanged: (v) => category = v!,
          ),
          const SizedBox(height: 12),
          _field(code, 'Codice / modello ricambio'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galleria'),
              ),
              OutlinedButton.icon(
                onPressed: () => pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Scatta foto'),
              ),
              OutlinedButton.icon(
                onPressed: lookingUp ? null : scanBarcode,
                icon: lookingUp
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner),
                label: const Text('Codice a barre'),
              ),
            ],
          ),
          if (imageData != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 140,
                  height: 100,
                  child: _maintenanceImage(imageData),
                ),
              ),
            ),
          _numberRequired(price, 'Prezzo unitario (€)'),
          _field(quantity, 'Quantità', keyboard: TextInputType.number),
          ListenableBuilder(
            listenable: Listenable.merge([price, quantity]),
            builder: (_, __) => Card(
              child: ListTile(
                title: const Text('Totale calcolato'),
                trailing: Text(_money(amount() * qty())),
              ),
            ),
          ),
          _field(shop, 'Venditore / negozio (es. eBay)'),
          TextFormField(
            controller: url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link del prodotto',
              hintText: 'https://...',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final uri = Uri.tryParse(value);
              return uri == null || !uri.hasScheme || uri.host.isEmpty
                  ? 'Link non valido'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          _field(
            km,
            'Km al momento dell’intervento',
            keyboard: TextInputType.number,
          ),
          _field(
            nextKm,
            'Prossimo intervento a km',
            keyboard: TextInputType.number,
          ),
          _field(warranty, 'Garanzia (mesi)', keyboard: TextInputType.number),
          _field(note, 'Note'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save),
            label: Text(
              widget.existing == null
                  ? 'Salva manutenzione'
                  : 'Salva modifiche',
            ),
          ),
        ],
      ),
    ),
  );
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool detected = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inquadra il codice a barre')),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (detected) return;
            final value = capture.barcodes.firstOrNull?.rawValue;
            if (value == null || value.isEmpty) return;
            detected = true;
            Navigator.of(context).pop(value);
          },
        ),
        Center(
          child: Container(
            width: 300,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Positioned(
          left: 24,
          right: 24,
          bottom: 36,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mantieni il codice dentro il riquadro. Se il prodotto è nel catalogo pubblico, nome, marca e foto verranno compilati.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
