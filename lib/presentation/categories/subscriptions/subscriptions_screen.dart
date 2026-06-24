import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/domain/models/subscription.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';

final subscriptionsApiProvider = Provider(
  (ref) => SubscriptionsApiClient(ref.watch(dioClientProvider).dio),
);
final subscriptionsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(subscriptionsApiProvider).getAll(),
);

const commonServices = <String>[
  'Amazon Prime',
  'Spotify',
  'Netflix',
  'YouTube Premium',
  'Disney+',
  'Apple Music',
  'Apple TV+',
  'Apple One',
  'iCloud+',
  'Google One',
  'ChatGPT Plus',
  'Claude Pro',
  'Microsoft 365',
  'Adobe Creative Cloud',
  'Dropbox',
  'OneDrive',
  'Google Workspace',
  'Canva Pro',
  'Figma',
  'Notion',
  'GitHub',
  'GitLab',
  'LinkedIn Premium',
  'X Premium',
  'Meta Verified',
  'Twitch',
  'DAZN',
  'Sky',
  'NOW',
  'Paramount+',
  'Discovery+',
  'Mediaset Infinity',
  'RaiPlay',
  'Audible',
  'Kindle Unlimited',
  'Storytel',
  'Kobo Plus',
  'PlayStation Plus',
  'Xbox Game Pass',
  'Nintendo Switch Online',
  'Steam',
  'GeForce NOW',
  'EA Play',
  'Ubisoft+',
  'Crunchyroll',
  'Duolingo',
  'Babbel',
  'Coursera',
  'Udemy',
  'Skillshare',
  'Headspace',
  'Calm',
  'Strava',
  'Freeletics',
  'MyFitnessPal',
  'Fitbit Premium',
  'Revolut',
  'N26',
  'PayPal',
  'Klarna',
  'Satispay',
  'Telepass',
  'MooneyGo',
  'Trenitalia',
  'Italo',
  'FlixBus',
  'Uber One',
  'Deliveroo Plus',
  'Glovo Prime',
  'Just Eat',
  'HelloFresh',
  'Everli',
  'Esselunga',
  'Coop',
  'Conad',
  'IKEA Family',
  'eBay',
  'AliExpress',
  'Temu',
  'Zalando Plus',
  'Shein',
  'Vinted',
  'Aruba',
  'Register.it',
  'SiteGround',
  'Hostinger',
  'Cloudflare',
  'NordVPN',
  'Surfshark',
  'ExpressVPN',
  'Bitwarden',
  '1Password',
  'Dashlane',
  'Todoist',
  'Evernote',
  'Grammarly',
  'DeepL Pro',
  'Midjourney',
  'Perplexity Pro',
  'Copilot Pro',
];

String _cycleLabel(BillingCycle cycle) => switch (cycle) {
  BillingCycle.weekly => 'Settimanale',
  BillingCycle.monthly => 'Mensile',
  BillingCycle.yearly => 'Annuale',
};

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsState();
}

class _SubscriptionsState extends ConsumerState<SubscriptionsScreen> {
  BillingCycle? filter;
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscriptionsProvider);
    final all = async.valueOrNull ?? const <Subscription>[];
    final visible = filter == null
        ? all
        : all.where((item) => item.billingCycle == filter).toList();
    final settings = ref.watch(settingsProvider);
    final dueSoon = settings.notificationsEnabled
        ? all.where((item) {
            final days = _nextSubscriptionDue(
              item,
            ).difference(DateTime.now()).inDays;
            return item.isActive &&
                days >= 0 &&
                days <= settings.notificationDaysBefore;
          }).toList()
        : const <Subscription>[];
    final monthly = all
        .where((item) => item.isActive)
        .fold<double>(
          0,
          (sum, item) =>
              sum +
              switch (item.billingCycle) {
                BillingCycle.weekly => item.amount * 52 / 12,
                BillingCycle.monthly =>
                  item.amount / (item.recurrenceMonths ?? 1),
                BillingCycle.yearly => item.amount / 12,
              },
        );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(subscriptionsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CategoryHeader(
                color: AppColors.subscription,
                title: 'Abbonamenti',
                value:
                    '${NumberFormat.currency(locale: 'it_IT', symbol: '€').format(monthly)} / mese',
                subtitle:
                    '${all.where((x) => x.isActive).length} abbonamenti attivi',
              ),
            ),
            if (dueSoon.isNotEmpty)
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text(
                      '${dueSoon.length} abbonamenti vicini alla scadenza',
                    ),
                    subtitle: Text(
                      dueSoon
                          .map(
                            (item) =>
                                '${item.name}: ${DateFormat('dd/MM').format(_nextSubscriptionDue(item))}',
                          )
                          .join(' · '),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tutti'),
                      selected: filter == null,
                      onSelected: (_) => setState(() => filter = null),
                    ),
                    for (final cycle in BillingCycle.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(_cycleLabel(cycle)),
                          selected: filter == cycle,
                          onSelected: (_) => setState(() => filter = cycle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (async.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (async.hasError)
              SliverFillRemaining(
                child: Center(child: Text('Errore: ${async.error}')),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.autorenew,
                  message: 'Non hai ancora abbonamenti',
                  action: () => context.push('/subscriptions/add'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (_, index) {
                    final item = visible[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item.name.characters.first.toUpperCase()),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${_cycleLabel(item.billingCycle)} · dal ${DateFormat('dd/MM/yyyy').format(item.startDate.toLocal())}${item.endDate == null ? '' : ' al ${DateFormat('dd/MM/yyyy').format(item.endDate!.toLocal())}'}',
                        ),
                        trailing: Text(
                          NumberFormat.currency(
                            locale: 'it_IT',
                            symbol: '€',
                          ).format(item.amount),
                        ),
                        onTap: () => _showSubscription(context, ref, item),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.subscription,
        onPressed: () => context.push('/subscriptions/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

DateTime _nextSubscriptionDue(Subscription item) {
  var due = (item.nextDueDate ?? item.startDate).toLocal();
  final now = DateTime.now();
  while (due.isBefore(DateTime(now.year, now.month, now.day))) {
    if (item.billingCycle == BillingCycle.weekly) {
      due = due.add(const Duration(days: 7));
    } else {
      final months =
          item.recurrenceMonths ??
          (item.billingCycle == BillingCycle.yearly ? 12 : 1);
      due = DateTime(due.year, due.month + months, due.day);
    }
  }
  return due;
}

Future<void> _showSubscription(
  BuildContext context,
  WidgetRef ref,
  Subscription item,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Modifica',
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddSubscriptionScreen(existing: item),
                    ),
                  );
                  if (changed == true) ref.invalidate(subscriptionsProvider);
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Elimina',
                color: Theme.of(context).colorScheme.error,
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Eliminare l’abbonamento?'),
                      content: Text(
                        '“${item.name}” verrà eliminato definitivamente.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('ANNULLA'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('ELIMINA'),
                        ),
                      ],
                    ),
                  );
                  if (yes != true) return;
                  await ref.read(subscriptionsApiProvider).delete(item.id);
                  ref.invalidate(subscriptionsProvider);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.euro),
            title: const Text('Importo'),
            trailing: Text(
              NumberFormat.currency(
                locale: 'it_IT',
                symbol: '€',
              ).format(item.amount),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_repeat),
            title: Text(_cycleLabel(item.billingCycle)),
            subtitle: item.recurrenceMonths != null
                ? Text('Ogni ${item.recurrenceMonths} mesi')
                : null,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Prossima scadenza'),
            trailing: Text(
              DateFormat('dd/MM/yyyy').format(_nextSubscriptionDue(item)),
            ),
          ),
          if (item.endDate != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: const Text('Fine contratto'),
              trailing: Text(
                DateFormat('dd/MM/yyyy').format(item.endDate!.toLocal()),
              ),
            ),
          if (item.note?.isNotEmpty == true)
            Text(item.note!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  ),
);

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({this.existing, super.key});
  final Subscription? existing;
  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends ConsumerState<AddSubscriptionScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      amount = TextEditingController(),
      customMonths = TextEditingController(),
      url = TextEditingController(),
      note = TextEditingController();
  BillingCycle cycle = BillingCycle.monthly;
  int duration = 0;
  int recurrence = 1;
  DateTime nextDueDate = DateTime.now();
  DateTime? endDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      name.text = item.name;
      amount.text = item.amount.toStringAsFixed(2);
      url.text = item.url ?? '';
      note.text = item.note ?? '';
      cycle = item.billingCycle;
      recurrence =
          item.recurrenceMonths ??
          (item.billingCycle == BillingCycle.yearly ? 12 : 1);
      nextDueDate = item.nextDueDate?.toLocal() ?? item.startDate.toLocal();
      endDate = item.endDate?.toLocal();
      if (![1, 3, 12].contains(recurrence)) {
        customMonths.text = '$recurrence';
        recurrence = -1;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [name, amount, customMonths, url, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scegli o scrivi il nome del servizio')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final start = DateTime.now();
      final recurrenceMonths = cycle == BillingCycle.weekly
          ? null
          : recurrence == -1
          ? int.tryParse(customMonths.text)
          : recurrence;
      final body = {
        'name': name.text.trim(),
        'amount': double.parse(amount.text.replaceAll(',', '.')),
        'currency': 'EUR',
        'billingCycle': cycle.name,
        'billingDay': start.day,
        'startDate': start.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
        'nextDueDate': nextDueDate.millisecondsSinceEpoch,
        'recurrenceMonths': recurrenceMonths,
        'url': url.text.trim(),
        'isActive': 1,
        'note': note.text.trim(),
      };
      final api = ref.read(subscriptionsApiProvider);
      if (widget.existing == null) {
        await api.create(body);
      } else {
        await api.update(widget.existing!.id, body);
      }
      ref.invalidate(subscriptionsProvider);
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Nuovo abbonamento' : 'Modifica abbonamento',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownMenu<String>(
            controller: name,
            enableFilter: true,
            requestFocusOnTap: true,
            label: const Text('Servizio *'),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: commonServices
                .map((x) => DropdownMenuEntry(value: x, label: x))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Importo *'),
            validator: (v) =>
                (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0
                ? 'Importo non valido'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BillingCycle>(
            initialValue: cycle,
            decoration: const InputDecoration(labelText: 'Periodicità'),
            items: BillingCycle.values
                .map(
                  (x) =>
                      DropdownMenuItem(value: x, child: Text(_cycleLabel(x))),
                )
                .toList(),
            onChanged: (x) => setState(() {
              cycle = x!;
              if (cycle == BillingCycle.yearly) recurrence = 12;
              if (cycle == BillingCycle.monthly && recurrence == 12) {
                recurrence = 1;
              }
            }),
          ),
          const SizedBox(height: 12),
          if (cycle != BillingCycle.weekly)
            DropdownButtonFormField<int>(
              initialValue: recurrence,
              decoration: const InputDecoration(
                labelText: 'Rinnovo / addebito',
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Ogni 1 mese')),
                DropdownMenuItem(value: 3, child: Text('Ogni 3 mesi')),
                DropdownMenuItem(value: 12, child: Text('Ogni 1 anno')),
                DropdownMenuItem(value: -1, child: Text('Personalizzato')),
              ],
              onChanged: (x) => setState(() => recurrence = x!),
            ),
          if (cycle != BillingCycle.weekly && recurrence == -1) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: customMonths,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numero di mesi *',
                hintText: 'Es. 7 oppure 8',
              ),
              validator: (value) =>
                  recurrence == -1 && (int.tryParse(value ?? '') ?? 0) < 1
                  ? 'Inserisci almeno 1 mese'
                  : null,
            ),
          ],
          const SizedBox(height: 12),
          _SubscriptionDateField(
            label: 'Prossima scadenza / pagamento *',
            date: nextDueDate,
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                locale: const Locale('it', 'IT'),
                initialDate: nextDueDate,
                firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                helpText: 'SELEZIONA LA PROSSIMA SCADENZA',
                cancelText: 'ANNULLA',
                confirmText: 'CONFERMA',
              );
              if (value != null) setState(() => nextDueDate = value);
            },
          ),
          const SizedBox(height: 12),
          _SubscriptionDateField(
            label: 'Fine contratto (opzionale)',
            date: endDate,
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                locale: const Locale('it', 'IT'),
                initialDate: endDate ?? nextDueDate,
                firstDate: nextDueDate,
                lastDate: DateTime.now().add(const Duration(days: 36500)),
                helpText: 'SELEZIONA LA FINE DEL CONTRATTO',
                cancelText: 'ANNULLA',
                confirmText: 'CONFERMA',
              );
              if (value != null) setState(() => endDate = value);
            },
            onClear: endDate == null
                ? null
                : () => setState(() => endDate = null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Sito / gestione abbonamento',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.save),
            label: const Text('Salva abbonamento'),
          ),
        ],
      ),
    ),
  );
}

class _SubscriptionDateField extends StatelessWidget {
  const _SubscriptionDateField({
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
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month),
        suffixIcon: onClear == null
            ? const Icon(Icons.arrow_drop_down)
            : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
      ),
      child: Text(
        date == null ? 'Non impostata' : DateFormat('dd/MM/yyyy').format(date!),
      ),
    ),
  );
}
