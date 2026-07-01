import 'dart:convert';

import 'package:dio/dio.dart' show Dio, Options;
import 'package:flutter/gestures.dart';
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
import 'package:spendwise/domain/models/vehicle.dart';
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
final accessoryEntriesProvider = FutureProvider.autoDispose
    .family<List<VehicleMaintenance>, String>(
      (ref, id) => ref.watch(vehiclesApiProvider).accessories(id),
    );

String _money(num value) =>
    NumberFormat.currency(locale: 'it_IT', symbol: '€').format(value);

class _DesktopHorizontalScroll extends StatefulWidget {
  const _DesktopHorizontalScroll({required this.child});
  final Widget child;

  @override
  State<_DesktopHorizontalScroll> createState() =>
      _DesktopHorizontalScrollState();
}

class _DesktopHorizontalScrollState extends State<_DesktopHorizontalScroll> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _wheel(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent || !controller.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(signal, (_) {
      final delta = signal.scrollDelta.dy != 0
          ? signal.scrollDelta.dy
          : signal.scrollDelta.dx;
      controller.jumpTo(
        (controller.offset + delta).clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _wheel,
    child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: widget.child,
        ),
      ),
    ),
  );
}

String _date(DateTime value) =>
    DateFormat('dd/MM/yyyy').format(value.toLocal());

class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key});

  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen> {
  bool showArchived = false;

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: const Text('Eliminare definitivamente il veicolo?'),
        content: Text(
          'Eliminando “${vehicle.name}” verranno eliminati anche tutti i rifornimenti, gli accessori e gli interventi di manutenzione associati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ELIMINA TUTTO'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(vehiclesApiProvider).delete(vehicle.id);
    ref.invalidate(vehiclesProvider);
  }

  Future<void> _archiveVehicle(Vehicle vehicle) async {
    await ref.read(vehiclesApiProvider).update(vehicle.id, {
      'isArchived': vehicle.isArchived ? 0 : 1,
    });
    ref.invalidate(vehiclesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final all = vehicles.valueOrNull ?? const <Vehicle>[];
    final visible = all
        .where((vehicle) => vehicle.isArchived == showArchived)
        .toList();
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
                value: visible.length.toString(),
                subtitle: showArchived
                    ? 'Veicoli archiviati'
                    : 'Auto e moto registrate',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.directions_car),
                      label: Text('Attivi'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.archive_outlined),
                      label: Text('Archiviati'),
                    ),
                  ],
                  selected: {showArchived},
                  onSelectionChanged: (value) =>
                      setState(() => showArchived = value.first),
                ),
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
              data: (_) => visible.isEmpty
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
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final vehicle = visible[index];
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
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'open') {
                                    context.push('/vehicle/${vehicle.id}');
                                  } else if (action == 'edit') {
                                    await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddVehicleScreen(existing: vehicle),
                                      ),
                                    );
                                  } else if (action == 'archive') {
                                    await _archiveVehicle(vehicle);
                                  } else if (action == 'delete') {
                                    await _deleteVehicle(vehicle);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: Text('Apri dettaglio'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifica'),
                                  ),
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Text(
                                      vehicle.isArchived
                                          ? 'Ripristina'
                                          : 'Archivia',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Elimina'),
                                  ),
                                ],
                              ),
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
  const AddVehicleScreen({this.existing, super.key});
  final Vehicle? existing;
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
  final tankCapacity = TextEditingController();
  String fuelType = 'gasoline';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.existing;
    if (vehicle != null) {
      name.text = vehicle.name;
      plate.text = vehicle.plate ?? '';
      brand.text = vehicle.brand ?? '';
      model.text = vehicle.model ?? '';
      year.text = vehicle.year?.toString() ?? '';
      tankCapacity.text = vehicle.tankCapacityLiters?.toString() ?? '';
      fuelType = vehicle.fuelType?.name ?? 'gasoline';
    }
  }

  @override
  void dispose() {
    for (final controller in [name, plate, brand, model, year, tankCapacity]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final body = {
        'name': name.text.trim(),
        'plate': plate.text.trim().toUpperCase(),
        'brand': brand.text.trim(),
        'model': model.text.trim(),
        'year': int.tryParse(year.text),
        'fuelType': fuelType,
        'tankCapacityLiters': tankCapacity.text.trim().isEmpty
            ? null
            : double.tryParse(tankCapacity.text.replaceAll(',', '.')),
      };
      final api = ref.read(vehiclesApiProvider);
      final vehicle = widget.existing == null
          ? await api.create(body)
          : await api.update(widget.existing!.id, body);
      ref.invalidate(vehiclesProvider);
      if (mounted) {
        if (widget.existing == null) {
          context.go('/vehicle/${vehicle.id}');
        } else {
          Navigator.pop(context, true);
        }
      }
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
        widget.existing == null ? 'Nuovo veicolo' : 'Modifica veicolo',
      ),
    ),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: tankCapacity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Capacità serbatoio (litri)',
              hintText: 'Es. 45',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              return parsed == null || parsed <= 0 || parsed > 1000
                  ? 'Inserisci una capacità valida (massimo 1000 litri)'
                  : null;
            },
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
  late final TabController tabs = TabController(length: 3, vsync: this)
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
            Tab(icon: Icon(Icons.auto_awesome), text: 'Accessori'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          _FuelTab(id: widget.vehicleId),
          _MaintenanceTab(id: widget.vehicleId),
          _AccessoriesTab(id: widget.vehicleId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final type = tabs.index == 0
              ? 'fuel'
              : tabs.index == 1
              ? 'maintenance'
              : 'accessories';
          await context.push('/vehicle/${widget.vehicleId}/$type/add');
        },
        icon: const Icon(Icons.add),
        label: Text(
          tabs.index == 0
              ? 'Rifornimento'
              : tabs.index == 1
              ? 'Manutenzione'
              : 'Accessorio',
        ),
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

Map<String, dynamic> _accessoryMeta(VehicleMaintenance item) {
  try {
    final decoded = jsonDecode(item.itemsJson ?? '');
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

String _accessoryCategoryLabel(String? value) => switch (value) {
  'estetica' => 'Estetica',
  'interni' => 'Interni',
  'elettronica' => 'Elettronica',
  'ruote' => 'Ruote e cerchi',
  'sicurezza' => 'Sicurezza',
  'pulizia' => 'Pulizia e cura',
  _ => 'Altro',
};

String _accessoryStatusLabel(String? value) => switch (value) {
  'installed' => 'Installato',
  'removed' => 'Rimosso',
  _ => 'Acquistato',
};

class _AccessoriesTab extends ConsumerWidget {
  const _AccessoriesTab({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(accessoryEntriesProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(accessoryEntriesProvider(id).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summary(
                      'Totale accessori',
                      _money(
                        items.fold<double>(
                          0,
                          (sum, item) => sum + item.totalCost,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _summary('Accessori registrati', '${items.length}'),
                  ),
                ],
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('Nessun accessorio registrato')),
                ),
              for (final item in items) _AccessoryCard(item: item),
            ],
          ),
        ),
      );
}

class _AccessoryCard extends ConsumerWidget {
  const _AccessoryCard({required this.item});
  final VehicleMaintenance item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _accessoryMeta(item);
    return Card(
      child: ListTile(
        leading: _maintenanceImage(item.receiptUrl),
        title: Text(item.itemName),
        subtitle: Text(
          [
            _accessoryCategoryLabel(meta['accessoryCategory'] as String?),
            _date(item.date),
            _accessoryStatusLabel(meta['status'] as String?),
            if (item.shopName?.isNotEmpty == true) item.shopName!,
          ].join(' · '),
        ),
        trailing: Text(
          _money(item.totalCost),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => _showAccessoryDetails(context, ref, item),
      ),
    );
  }
}

Future<void> _showAccessoryDetails(
  BuildContext context,
  WidgetRef ref,
  VehicleMaintenance item,
) async {
  final meta = _accessoryMeta(item);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Modifica',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AddAccessoryScreen(
                          vehicleId: item.vehicleId,
                          existing: item,
                        ),
                      ),
                    );
                    if (changed == true) {
                      ref.invalidate(accessoryEntriesProvider(item.vehicleId));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Elimina',
                  color: Theme.of(context).colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Eliminare questo accessorio?'),
                        content: Text('“${item.itemName}” verrà eliminato.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('ANNULLA'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('ELIMINA'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref
                        .read(vehiclesApiProvider)
                        .deleteAccessory(item.vehicleId, item.id);
                    ref.invalidate(accessoryEntriesProvider(item.vehicleId));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.receiptUrl?.isNotEmpty == true)
              SizedBox(
                height: 220,
                child: _maintenanceImage(item.receiptUrl, height: 210),
              ),
            _AccessoryDetailRow(
              label: 'Categoria',
              value: _accessoryCategoryLabel(
                meta['accessoryCategory'] as String?,
              ),
            ),
            _AccessoryDetailRow(
              label: 'Stato',
              value: _accessoryStatusLabel(meta['status'] as String?),
            ),
            _AccessoryDetailRow(
              label: 'Data acquisto',
              value: _date(item.date),
            ),
            if (meta['installationDate'] is String)
              _AccessoryDetailRow(
                label: 'Data installazione',
                value: DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.parse(meta['installationDate'] as String)),
              ),
            _AccessoryDetailRow(
              label: 'Marca / modello / codice',
              value: item.partCode ?? 'Non indicato',
            ),
            _AccessoryDetailRow(label: 'Quantità', value: '${item.quantity}'),
            _AccessoryDetailRow(
              label: 'Prezzo complessivo',
              value: _money(item.totalCost),
            ),
            if (item.shopName?.isNotEmpty == true)
              _AccessoryDetailRow(label: 'Venditore', value: item.shopName!),
            if (item.note?.isNotEmpty == true)
              _AccessoryDetailRow(label: 'Note', value: item.note!),
          ],
        ),
      ),
    ),
  );
}

class _AccessoryDetailRow extends StatelessWidget {
  const _AccessoryDetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.item, required this.onOpen});
  final VehicleMaintenance item;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(item.itemName),
      subtitle: Text(_date(item.date)),
      trailing: Text(
        _money(item.totalCost),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
            ],
          ),
        ),
        DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: const [
            DataColumn(label: Text('DATA')),
            DataColumn(label: Text('INTERVENTO')),
            DataColumn(label: Text('PREZZO'), numeric: true),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  onSelectChanged: (_) => onOpen(item),
                  cells: [
                    DataCell(Text(_date(item.date))),
                    DataCell(Text(item.itemName)),
                    DataCell(Text(_money(item.totalCost))),
                  ],
                ),
              )
              .toList(),
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
    final pieces = [
      ..._maintenanceItems(item).map(
        (line) => [
          line['name'],
          line['code'],
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
      ),
      ...(item.note ?? '').split(RegExp(r'[;\n]|\.\s+')),
    ].map((part) => part.trim()).where((part) => part.isNotEmpty);
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 800 ? 4 : 2;
                    const spacing = 10.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _InfoBox(
                          width: width,
                          icon: Icons.calendar_today,
                          label: 'DATA',
                          value: _date(item.date),
                        ),
                        _InfoBox(
                          width: width,
                          icon: Icons.speed,
                          label: 'CHILOMETRAGGIO',
                          value: item.kmAtService == null
                              ? 'Non indicato'
                              : '${NumberFormat.decimalPattern('it_IT').format(item.kmAtService)} km',
                        ),
                        _InfoBox(
                          width: width,
                          icon: Icons.euro,
                          label: 'COSTO TOTALE',
                          value: _money(item.totalCost),
                        ),
                        _InfoBox(
                          width: width,
                          icon: Icons.inventory_2,
                          label: 'QUANTITÀ',
                          value: '${item.quantity}',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MaintenanceItemsTable(item: item),
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
    this.width = 245,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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

class AddAccessoryScreen extends ConsumerStatefulWidget {
  const AddAccessoryScreen({required this.vehicleId, this.existing, super.key});
  final String vehicleId;
  final VehicleMaintenance? existing;

  @override
  ConsumerState<AddAccessoryScreen> createState() => _AddAccessoryScreenState();
}

class _AddAccessoryScreenState extends ConsumerState<AddAccessoryScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      model = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      price = TextEditingController(),
      installationCost = TextEditingController(),
      seller = TextEditingController(),
      link = TextEditingController(),
      km = TextEditingController(),
      warranty = TextEditingController(),
      note = TextEditingController();
  DateTime purchaseDate = DateTime.now();
  DateTime? installationDate;
  String category = 'estetica';
  String status = 'purchased';
  String? imageData;
  bool saving = false;

  double get total =>
      (double.tryParse(price.text.replaceAll(',', '.')) ?? 0) *
          (int.tryParse(quantity.text) ?? 0) +
      (double.tryParse(installationCost.text.replaceAll(',', '.')) ?? 0);

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      final meta = _accessoryMeta(item);
      name.text = item.itemName;
      model.text = item.partCode ?? '';
      quantity.text = '${item.quantity}';
      price.text = item.price.toStringAsFixed(2);
      installationCost.text =
          ((meta['installationCost'] as num?)?.toDouble() ?? 0) > 0
          ? (meta['installationCost'] as num).toStringAsFixed(2)
          : '';
      seller.text = item.shopName ?? '';
      link.text = item.shopUrl ?? '';
      km.text = item.kmAtService?.toString() ?? '';
      warranty.text = item.warrantyMonths?.toString() ?? '';
      note.text = item.note ?? '';
      purchaseDate = item.date.toLocal();
      category = meta['accessoryCategory'] as String? ?? 'altro';
      status = meta['status'] as String? ?? 'purchased';
      installationDate = meta['installationDate'] is String
          ? DateTime.tryParse(meta['installationDate'] as String)
          : null;
      imageData = item.receiptUrl;
    }
    for (final controller in [price, quantity, installationCost]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    locale: const Locale('it', 'IT'),
    initialDate: initial,
    firstDate: DateTime(1900),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
    helpText: 'SELEZIONA LA DATA',
    cancelText: 'ANNULLA',
    confirmText: 'CONFERMA',
  );

  Future<void> _pickImage(ImageSource source) async {
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

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.isNotEmpty) model.text = code;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final unitPrice = double.parse(price.text.replaceAll(',', '.'));
      final body = <String, dynamic>{
        'date': purchaseDate.millisecondsSinceEpoch,
        'itemName': name.text.trim(),
        'partCode': model.text.trim(),
        'category': 'altro',
        'price': unitPrice,
        'quantity': int.parse(quantity.text),
        'totalCost': total,
        'shopName': seller.text.trim(),
        'shopUrl': link.text.trim(),
        'kmAtService': int.tryParse(km.text),
        'warrantyMonths': int.tryParse(warranty.text),
        'receiptUrl': imageData,
        'itemsJson': jsonEncode({
          'accessoryCategory': category,
          'status': status,
          'installationDate': installationDate?.toIso8601String(),
          'installationCost':
              double.tryParse(installationCost.text.replaceAll(',', '.')) ?? 0,
        }),
        'note': note.text.trim(),
      };
      final api = ref.read(vehiclesApiProvider);
      if (widget.existing == null) {
        await api.addAccessory(widget.vehicleId, body);
      } else {
        await api.updateAccessory(widget.vehicleId, widget.existing!.id, body);
      }
      ref.invalidate(accessoryEntriesProvider(widget.vehicleId));
      if (mounted) Navigator.pop(context, true);
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
  void dispose() {
    for (final controller in [
      name,
      model,
      quantity,
      price,
      installationCost,
      seller,
      link,
      km,
      warranty,
      note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Nuovo accessorio' : 'Modifica accessorio',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Nome accessorio *',
              hintText: 'Es. Alettone, cerchi in lega, dashcam',
              prefixIcon: Icon(Icons.auto_awesome),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Inserisci un nome'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items:
                      const {
                            'estetica': 'Estetica',
                            'interni': 'Interni',
                            'elettronica': 'Elettronica',
                            'ruote': 'Ruote e cerchi',
                            'sicurezza': 'Sicurezza',
                            'pulizia': 'Pulizia e cura',
                            'altro': 'Altro',
                          }.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Stato'),
                  items:
                      const {
                            'purchased': 'Acquistato',
                            'installed': 'Installato',
                            'removed': 'Rimosso',
                          }.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => status = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: model,
            decoration: const InputDecoration(
              labelText: 'Marca / modello / codice',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galleria'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Scatta foto'),
              ),
              OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Codice a barre'),
              ),
            ],
          ),
          if (imageData != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 150, child: _maintenanceImage(imageData)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantità *'),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Non valida'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prezzo unitario (€) *',
                  ),
                  validator: (value) =>
                      double.tryParse((value ?? '').replaceAll(',', '.')) ==
                          null
                      ? 'Non valido'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: installationCost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Montaggio (€)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Totale acquisto e montaggio'),
              trailing: Text(
                _money(total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AccessoryDateField(
                  label: 'Data acquisto',
                  date: purchaseDate,
                  onTap: () async {
                    final value = await _pickDate(purchaseDate);
                    if (value != null) setState(() => purchaseDate = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccessoryDateField(
                  label: 'Data installazione',
                  date: installationDate,
                  onTap: () async {
                    final value = await _pickDate(
                      installationDate ?? purchaseDate,
                    );
                    if (value != null) setState(() => installationDate = value);
                  },
                  onClear: installationDate == null
                      ? null
                      : () => setState(() => installationDate = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: seller,
            decoration: const InputDecoration(labelText: 'Venditore / negozio'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: link,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link del prodotto',
              hintText: 'https://…',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: km,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Km all’installazione',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: warranty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Garanzia (mesi)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: note,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('SALVA ACCESSORIO'),
          ),
        ],
      ),
    ),
  );
}

class _AccessoryDateField extends StatelessWidget {
  const _AccessoryDateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month),
        suffixIcon: onClear == null
            ? const Icon(Icons.arrow_drop_down)
            : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
      ),
      child: Text(
        date == null ? 'Non indicata' : DateFormat('dd/MM/yyyy').format(date!),
      ),
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
  bool fullTank = false, saving = false, detailed = false, calculating = false;
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

  Future<void> setFullTank(bool value) async {
    setState(() => fullTank = value);
    if (!value) return;
    final vehicles =
        ref.read(vehiclesProvider).valueOrNull ??
        await ref.read(vehiclesProvider.future) ??
        const <Vehicle>[];
    final capacity = vehicles
        .where((vehicle) => vehicle.id == widget.vehicleId)
        .firstOrNull
        ?.tankCapacityLiters;
    if (!mounted || capacity == null) return;
    setState(() {
      detailed = true;
      calculateField = 'total';
      liters.text = capacity.toStringAsFixed(
        capacity == capacity.roundToDouble() ? 0 : 2,
      );
    });
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
            onChanged: setFullTank,
            title: const Text('Pieno completo'),
            subtitle: const Text(
              'Usa automaticamente la capacità indicata nel veicolo',
            ),
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

String _categoryLabel(MaintenanceCategory category) => switch (category) {
  MaintenanceCategory.tagliando => 'TAGLIANDO',
  MaintenanceCategory.pneumatici => 'PNEUMATICI',
  MaintenanceCategory.freni => 'FRENI',
  MaintenanceCategory.elettrico => 'ELETTRICO',
  MaintenanceCategory.batteria => 'BATTERIA',
  MaintenanceCategory.carrozzeria => 'CARROZZERIA',
  MaintenanceCategory.altro => 'ALTRO',
};

MaintenanceCategory? _inferMaintenanceCategory(String value) {
  final text = value.toLowerCase();
  if (RegExp(
    r'ferodo|\bfdb\d*|brembo|pastigl|pattin|disch[io].*fren|fren[io]|pinza',
  ).hasMatch(text)) {
    return MaintenanceCategory.freni;
  }
  if (RegExp(
    r'pneumatic|gomm[ae]|cerch|equilibratura|convergenza',
  ).hasMatch(text)) {
    return MaintenanceCategory.pneumatici;
  }
  if (RegExp(r'batteria|accumulatore|agm|efb').hasMatch(text)) {
    return MaintenanceCategory.batteria;
  }
  if (RegExp(
    r'motorino|alternatore|elettric|lampad|fusibil|sensore',
  ).hasMatch(text)) {
    return MaintenanceCategory.elettrico;
  }
  if (RegExp(
    r'carrozzer|paraurti|vernici|sportello|parafango',
  ).hasMatch(text)) {
    return MaintenanceCategory.carrozzeria;
  }
  if (RegExp(
    r'tagliando|olio|filtr|cinghia|distribuzione|liquido',
  ).hasMatch(text)) {
    return MaintenanceCategory.tagliando;
  }
  return null;
}

class _MaintenanceItemsTable extends StatelessWidget {
  const _MaintenanceItemsTable({required this.item});
  final VehicleMaintenance item;
  @override
  Widget build(BuildContext context) {
    final rows = _maintenanceItems(item);
    final payload = _maintenanceItemsPayload(item);
    final hasOverallPrice = payload?['pricingMode'] == 'total';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasOverallPrice
                        ? 'PEZZI E INTERVENTI · TOTALE ${_money(item.totalCost)}'
                        : 'PEZZI, PRODOTTI E INTERVENTI',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_left_alt,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SCORRI',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _DesktopHorizontalScroll(
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 58,
              columns: const [
                DataColumn(label: Text('DESCRIZIONE')),
                DataColumn(label: Text('CODICE / MODELLO')),
                DataColumn(label: Text('QTÀ')),
                DataColumn(label: Text('PREZZO')),
                DataColumn(label: Text('TOTALE')),
                DataColumn(label: Text('VENDITORE')),
              ],
              rows: rows.map((row) {
                final quantity = (row['quantity'] as num?)?.toInt() ?? 1;
                final price = (row['price'] as num?)?.toDouble() ?? 0;
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Text(row['name'] as String? ?? '—'),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(row['code'] as String? ?? '—'),
                      ),
                    ),
                    DataCell(Text('$quantity')),
                    DataCell(
                      Text(hasOverallPrice ? 'Nel totale' : _money(price)),
                    ),
                    DataCell(
                      Text(hasOverallPrice ? '—' : _money(price * quantity)),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                (row['seller'] as String?)?.trim().isNotEmpty ==
                                        true
                                    ? row['seller'] as String
                                    : '—',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if ((row['link'] as String?)?.trim().isNotEmpty ==
                                true)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.link, size: 17),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceLineDraft {
  _MaintenanceLineDraft({
    String name = '',
    String code = '',
    String seller = '',
    String link = '',
    int quantity = 1,
    double price = 0,
  }) : name = TextEditingController(text: name),
       code = TextEditingController(text: code),
       seller = TextEditingController(text: seller),
       link = TextEditingController(text: link),
       quantity = TextEditingController(text: quantity.toString()),
       price = TextEditingController(
         text: price > 0 ? price.toStringAsFixed(2) : '',
       );

  final TextEditingController name, code, seller, link, quantity, price;
  int get quantityValue => int.tryParse(quantity.text) ?? 0;
  double get priceValue =>
      double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
  double get total => quantityValue * priceValue;

  Map<String, dynamic> toJson() => {
    'name': name.text.trim(),
    'code': code.text.trim(),
    'seller': seller.text.trim(),
    'link': link.text.trim(),
    'quantity': quantityValue,
    'price': priceValue,
  };

  void dispose() {
    name.dispose();
    code.dispose();
    seller.dispose();
    link.dispose();
    quantity.dispose();
    price.dispose();
  }
}

class _MaintenanceLineEditorRow extends StatelessWidget {
  const _MaintenanceLineEditorRow({
    required this.index,
    required this.line,
    required this.wide,
    required this.canRemove,
    required this.onRemove,
    required this.unitPrices,
    required this.onPurchase,
  });
  final int index;
  final _MaintenanceLineDraft line;
  final bool wide, canRemove, unitPrices;
  final VoidCallback onRemove, onPurchase;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: wide ? _wide(context) : _narrow(context),
  );

  Widget _wide(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _number(),
      const SizedBox(width: 8),
      Expanded(flex: 4, child: _text(line.name, 'Pezzo / intervento', true)),
      const SizedBox(width: 8),
      Expanded(flex: 3, child: _text(line.code, 'Codice / modello', false)),
      const SizedBox(width: 8),
      SizedBox(width: 78, child: _numeric(line.quantity, 'Qtà', true)),
      const SizedBox(width: 8),
      if (unitPrices)
        SizedBox(width: 112, child: _numeric(line.price, 'Prezzo €', false))
      else
        const SizedBox(width: 112, child: Center(child: Text('Nel totale'))),
      SizedBox(
        width: 100,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            unitPrices ? _money(line.total) : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      _purchaseButton(),
      _removeButton(),
    ],
  );

  Widget _narrow(BuildContext context) => Column(
    children: [
      Row(
        children: [
          _number(),
          const Spacer(),
          _purchaseButton(),
          _removeButton(),
        ],
      ),
      _text(line.name, 'Pezzo / intervento', true),
      const SizedBox(height: 8),
      _text(line.code, 'Codice / modello', false),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _numeric(line.quantity, 'Quantità', true)),
          const SizedBox(width: 8),
          if (unitPrices)
            Expanded(child: _numeric(line.price, 'Prezzo unitario €', false))
          else
            const Expanded(child: Center(child: Text('Prezzo nel totale'))),
          const SizedBox(width: 12),
          Text(
            unitPrices ? _money(line.total) : '—',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
  );

  Widget _number() => CircleAvatar(
    radius: 14,
    child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
  );

  Widget _removeButton() => IconButton(
    tooltip: 'Rimuovi riga',
    onPressed: canRemove ? onRemove : null,
    icon: const Icon(Icons.remove_circle_outline),
  );

  Widget _purchaseButton() => IconButton(
    tooltip: line.seller.text.trim().isEmpty && line.link.text.trim().isEmpty
        ? 'Venditore e link della riga'
        : 'Modifica venditore e link',
    onPressed: onPurchase,
    icon: Icon(
      line.seller.text.trim().isEmpty && line.link.text.trim().isEmpty
          ? Icons.store_outlined
          : Icons.store,
    ),
  );

  Widget _text(TextEditingController controller, String label, bool required) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Obbligatorio' : null
            : null,
      );

  Widget _numeric(
    TextEditingController controller,
    String label,
    bool integer,
  ) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    decoration: InputDecoration(labelText: label, isDense: true),
    validator: (value) {
      final normalized = (value ?? '').replaceAll(',', '.');
      final parsed = integer
          ? int.tryParse(normalized)?.toDouble()
          : double.tryParse(normalized);
      return parsed == null || (integer ? parsed < 1 : parsed < 0)
          ? 'Non valido'
          : null;
    },
  );
}

List<Map<String, dynamic>> _maintenanceItems(VehicleMaintenance item) {
  final raw = item.itemsJson;
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      final values = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (values is List<dynamic>) {
        return values.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
  }
  return [
    {
      'name': item.itemName,
      'code': item.partCode ?? '',
      'quantity': item.quantity,
      'price': item.price,
    },
  ];
}

Map<String, dynamic>? _maintenanceItemsPayload(VehicleMaintenance item) {
  final raw = item.itemsJson;
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

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
  final title = TextEditingController(),
      shop = TextEditingController(),
      url = TextEditingController(),
      overallPrice = TextEditingController(),
      km = TextEditingController(),
      nextKm = TextEditingController(),
      warranty = TextEditingController(),
      note = TextEditingController();
  final lines = <_MaintenanceLineDraft>[];
  late MaintenanceCategory category;
  late DateTime selectedDate;
  MaintenanceCategory? suggestedCategory;
  bool categoryChosenManually = false;
  bool saving = false, lookingUp = false;
  String pricingMode = 'unit';
  String? imageData;
  double get totalAmount => pricingMode == 'total'
      ? double.tryParse(overallPrice.text.replaceAll(',', '.')) ?? 0
      : lines.fold(0, (total, line) => total + line.total);
  int get totalQuantity =>
      lines.fold(0, (total, line) => total + line.quantityValue);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    category = existing?.category ?? MaintenanceCategory.tagliando;
    selectedDate = existing?.date.toLocal() ?? DateTime.now();
    if (existing != null) {
      title.text = existing.itemName;
      final payload = _maintenanceItemsPayload(existing);
      pricingMode = payload?['pricingMode'] as String? ?? 'unit';
      if (pricingMode == 'total') {
        overallPrice.text =
            ((payload?['totalPrice'] as num?)?.toDouble() ?? existing.totalCost)
                .toStringAsFixed(2);
      }
      for (final value in _maintenanceItems(existing)) {
        _addLine(
          _MaintenanceLineDraft(
            name: value['name'] as String? ?? '',
            code: value['code'] as String? ?? '',
            seller: value['seller'] as String? ?? '',
            link: value['link'] as String? ?? '',
            quantity: (value['quantity'] as num?)?.toInt() ?? 1,
            price: (value['price'] as num?)?.toDouble() ?? 0,
          ),
          notify: false,
        );
      }
      shop.text = existing.shopName ?? '';
      url.text = existing.shopUrl ?? '';
      km.text = existing.kmAtService?.toString() ?? '';
      nextKm.text = existing.nextServiceKm?.toString() ?? '';
      warranty.text = existing.warrantyMonths?.toString() ?? '';
      note.text = existing.note ?? '';
      imageData = existing.receiptUrl;
      categoryChosenManually = true;
    } else {
      _addLine(_MaintenanceLineDraft(), notify: false);
    }
    suggestedCategory = _detectCategory();
    note.addListener(_updateCategorySuggestion);
    overallPrice.addListener(_updateCategorySuggestion);
  }

  MaintenanceCategory? _detectCategory() => _inferMaintenanceCategory(
    '${lines.map((line) => '${line.name.text} ${line.code.text}').join('\n')}\n${note.text}',
  );

  void _addLine(_MaintenanceLineDraft line, {bool notify = true}) {
    lines.add(line);
    for (final controller in [
      line.name,
      line.code,
      line.quantity,
      line.price,
    ]) {
      controller.addListener(_updateCategorySuggestion);
    }
    if (notify && mounted) setState(() {});
  }

  void _removeLine(int index) {
    if (lines.length == 1) return;
    lines.removeAt(index).dispose();
    _updateCategorySuggestion();
  }

  Future<void> _editLinePurchase(_MaintenanceLineDraft line) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.storefront),
        title: Text(
          'Acquisto: ${line.name.text.isEmpty ? 'riga' : line.name.text}',
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: line.seller,
                decoration: const InputDecoration(
                  labelText: 'Venditore / negozio',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: line.link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link del prodotto',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CHIUDI'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  void _updateCategorySuggestion() {
    final detected = _detectCategory();
    if (!mounted) return;
    setState(() {
      suggestedCategory = detected;
      if (!categoryChosenManually && detected != null) category = detected;
    });
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('it', 'IT'),
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELEZIONA LA DATA',
      cancelText: 'ANNULLA',
      confirmText: 'CONFERMA',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: const Size(420, 720)),
        child: child!,
      ),
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
    lines.first.code.text = barcode;
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
          lines.first.name.text = productName;
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
      title,
      shop,
      url,
      overallPrice,
      km,
      nextKm,
      warranty,
      note,
    ]) {
      if (c == note) {
        c.removeListener(_updateCategorySuggestion);
      }
      c.dispose();
    }
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final body = <String, dynamic>{
        'date': selectedDate.millisecondsSinceEpoch,
        'itemName': title.text.trim(),
        'partCode': lines
            .map((line) => line.code.text.trim())
            .where((value) => value.isNotEmpty)
            .join(', '),
        'category': category.name,
        'price': totalAmount,
        'quantity': totalQuantity,
        'totalCost': totalAmount,
        'shopName': shop.text.trim(),
        'shopUrl': url.text.trim(),
        'kmAtService': int.tryParse(km.text),
        'nextServiceKm': int.tryParse(nextKm.text),
        'warrantyMonths': int.tryParse(warranty.text),
        'receiptUrl': imageData,
        'itemsJson': jsonEncode({
          'pricingMode': pricingMode,
          'totalPrice': pricingMode == 'total' ? totalAmount : null,
          'items': lines.map((line) => line.toJson()).toList(),
        }),
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

  Widget _lineItemsEditor(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pezzi, prodotti e interventi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'unit',
              icon: Icon(Icons.price_change_outlined),
              label: Text('Prezzo per pezzo'),
            ),
            ButtonSegment(
              value: 'total',
              icon: Icon(Icons.receipt_long_outlined),
              label: Text('Prezzo complessivo'),
            ),
          ],
          selected: {pricingMode},
          onSelectionChanged: (selection) {
            final next = selection.first;
            if (next == 'total' && overallPrice.text.trim().isEmpty) {
              final current = lines.fold<double>(
                0,
                (sum, line) => sum + line.total,
              );
              if (current > 0) overallPrice.text = current.toStringAsFixed(2);
            }
            setState(() => pricingMode = next);
          },
        ),
        const SizedBox(height: 8),
        for (final entry in lines.asMap().entries) ...[
          _MaintenanceLineEditorRow(
            index: entry.key,
            line: entry.value,
            wide: constraints.maxWidth >= 760,
            canRemove: lines.length > 1,
            onRemove: () => _removeLine(entry.key),
            unitPrices: pricingMode == 'unit',
            onPurchase: () => _editLinePurchase(entry.value),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            onPressed: () => _addLine(_MaintenanceLineDraft()),
            icon: const Icon(Icons.add),
            label: const Text('AGGIUNGI RIGA'),
          ),
        ),
        if (pricingMode == 'total') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: overallPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Prezzo complessivo (€)',
              prefixIcon: Icon(Icons.euro),
              isDense: true,
            ),
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              return parsed == null || parsed < 0
                  ? 'Inserisci un prezzo valido'
                  : null;
            },
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.calculate),
            title: Text('${lines.length} righe · $totalQuantity pezzi'),
            trailing: Text(
              _money(totalAmount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ],
    ),
  );

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
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titolo manutenzione *',
              hintText: 'Es. Tagliando completo, Freni anteriori',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Inserisci un titolo'
                : null,
          ),
          const SizedBox(height: 12),
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
          _lineItemsEditor(context),
          const SizedBox(height: 12),
          DropdownButtonFormField<MaintenanceCategory>(
            key: ValueKey(category),
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
            onChanged: (v) => setState(() {
              category = v!;
              categoryChosenManually = true;
            }),
          ),
          if (suggestedCategory != null && suggestedCategory != category) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(
                  'Categoria rilevata: ${_categoryLabel(suggestedCategory!)}',
                ),
                subtitle: const Text(
                  'Riconosciuta da nome, codice ricambio e note.',
                ),
                trailing: TextButton(
                  onPressed: () => setState(() {
                    category = suggestedCategory!;
                    categoryChosenManually = true;
                  }),
                  child: const Text('APPLICA'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
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
          _field(shop, 'Venditore generale / officina'),
          TextFormField(
            controller: url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link generale dell’acquisto',
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
          const SizedBox(height: 20),
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
          TextFormField(
            controller: note,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Note',
              alignLabelWithHint: true,
              hintText: 'Es. Ferodo FDB1394 €28 (non cambiate)',
            ),
          ),
          const SizedBox(height: 24),
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
