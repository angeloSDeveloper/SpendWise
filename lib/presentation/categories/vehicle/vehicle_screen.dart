import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

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
                        '${item.liters.toStringAsFixed(2)} L · ${_money(item.totalCost)}',
                      ),
                      subtitle: Text(
                        [
                          _date(item.date),
                          if (item.stationName?.isNotEmpty == true)
                            item.stationName!,
                          if (item.kmOdometer != null) '${item.kmOdometer} km',
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${item.pricePerLiter.toStringAsFixed(3)} €/L',
                      ),
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
              for (final item in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: Text(item.itemName),
                    subtitle: Text(
                      [
                        _date(item.date),
                        if (item.partCode?.isNotEmpty == true)
                          'Cod. ${item.partCode}',
                        if (item.shopName?.isNotEmpty == true) item.shopName!,
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_money(item.totalCost)),
                        if (item.shopUrl?.isNotEmpty == true)
                          IconButton(
                            tooltip: 'Apri sito',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(
                              Uri.parse(item.shopUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
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
      station = TextEditingController(),
      km = TextEditingController(),
      note = TextEditingController();
  bool fullTank = true, saving = false;
  double number(TextEditingController value) =>
      double.tryParse(value.text.replaceAll(',', '.')) ?? 0;
  @override
  void dispose() {
    for (final c in [liters, price, station, km, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref.read(vehiclesApiProvider).addFuel(widget.vehicleId, {
        'date': DateTime.now().millisecondsSinceEpoch,
        'liters': number(liters),
        'pricePerLiter': number(price),
        'totalCost': number(liters) * number(price),
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
          _numberRequired(liters, 'Litri'),
          _numberRequired(price, 'Prezzo al litro (€)'),
          ListenableBuilder(
            listenable: Listenable.merge([liters, price]),
            builder: (_, __) => Card(
              child: ListTile(
                title: const Text('Totale calcolato'),
                trailing: Text(_money(number(liters) * number(price))),
              ),
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

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  const AddMaintenanceScreen({required this.vehicleId, super.key});
  final String vehicleId;
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
  MaintenanceCategory category = MaintenanceCategory.tagliando;
  bool saving = false;
  double amount() => double.tryParse(price.text.replaceAll(',', '.')) ?? 0;
  int qty() => int.tryParse(quantity.text) ?? 1;
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
      await ref.read(vehiclesApiProvider).addMaintenance(widget.vehicleId, {
        'date': DateTime.now().millisecondsSinceEpoch,
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
        'note': note.text.trim(),
      });
      ref.invalidate(maintenanceEntriesProvider(widget.vehicleId));
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
    appBar: AppBar(title: const Text('Nuova manutenzione')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _requiredField(
            item,
            'Ricambio, liquido o intervento',
            'Es. Olio motore 5W-30',
          ),
          DropdownButtonFormField<MaintenanceCategory>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: MaintenanceCategory.values
                .map((v) => DropdownMenuItem(value: v, child: Text(v.name)))
                .toList(),
            onChanged: (v) => category = v!,
          ),
          const SizedBox(height: 12),
          _field(code, 'Codice / modello ricambio'),
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
          _field(shop, 'Negozio / sito di acquisto'),
          TextFormField(
            controller: url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link del prodotto',
              hintText: 'https://...',
            ),
            validator: (value) =>
                value != null &&
                    value.isNotEmpty &&
                    Uri.tryParse(value)?.hasAbsolutePath != true
                ? 'Link non valido'
                : null,
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
            label: const Text('Salva manutenzione'),
          ),
        ],
      ),
    ),
  );
}
