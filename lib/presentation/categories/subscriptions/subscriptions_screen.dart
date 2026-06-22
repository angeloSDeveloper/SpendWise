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
    final monthly = all
        .where((item) => item.isActive)
        .fold<double>(
          0,
          (sum, item) =>
              sum +
              switch (item.billingCycle) {
                BillingCycle.weekly => item.amount * 52 / 12,
                BillingCycle.monthly => item.amount,
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
                          '${_cycleLabel(item.billingCycle)} · dal ${DateFormat('dd/MM/yyyy').format(item.startDate)}${item.endDate == null ? '' : ' al ${DateFormat('dd/MM/yyyy').format(item.endDate!)}'}',
                        ),
                        trailing: Text(
                          NumberFormat.currency(
                            locale: 'it_IT',
                            symbol: '€',
                          ).format(item.amount),
                        ),
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

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({super.key});
  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends ConsumerState<AddSubscriptionScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      amount = TextEditingController(),
      url = TextEditingController(),
      note = TextEditingController();
  BillingCycle cycle = BillingCycle.monthly;
  int duration = 0;
  bool saving = false;
  @override
  void dispose() {
    for (final c in [name, amount, url, note]) {
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
      await ref.read(subscriptionsApiProvider).create({
        'name': name.text.trim(),
        'amount': double.parse(amount.text.replaceAll(',', '.')),
        'currency': 'EUR',
        'billingCycle': cycle.name,
        'billingDay': start.day,
        'startDate': start.millisecondsSinceEpoch,
        'endDate': duration == 0
            ? null
            : DateTime(
                start.year,
                start.month + duration,
                start.day,
              ).millisecondsSinceEpoch,
        'url': url.text.trim(),
        'isActive': 1,
        'note': note.text.trim(),
      });
      ref.invalidate(subscriptionsProvider);
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
    appBar: AppBar(title: const Text('Nuovo abbonamento')),
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
            onChanged: (x) => cycle = x!,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: duration,
            decoration: const InputDecoration(labelText: 'Durata / range'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Senza scadenza')),
              DropdownMenuItem(value: 3, child: Text('3 mesi')),
              DropdownMenuItem(value: 6, child: Text('6 mesi')),
              DropdownMenuItem(value: 12, child: Text('12 mesi')),
              DropdownMenuItem(value: 24, child: Text('24 mesi')),
            ],
            onChanged: (x) => duration = x!,
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
