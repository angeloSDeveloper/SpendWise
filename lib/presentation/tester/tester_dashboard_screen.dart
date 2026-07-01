import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/core/notifications/notification_test_service.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

final testerApiProvider = Provider(
  (ref) => TesterApiClient(ref.watch(dioClientProvider).dio),
);

final testerResultsProvider = FutureProvider.autoDispose((ref) async {
  final rows = await ref.watch(testerApiProvider).getResults();
  return {for (final row in rows) row.testKey: row.status};
});

const _notificationTests = <String, (String, String)>{
  'installment_due': (
    'Rata in scadenza',
    'La tua rata Klarna scade tra pochi giorni.',
  ),
  'installment_overdue': (
    'Rata scaduta',
    'Una rata risulta scaduta e non ancora pagata.',
  ),
  'subscription_due': (
    'Abbonamento in rinnovo',
    'Un abbonamento verrà addebitato tra pochi giorni.',
  ),
  'subscription_ending': (
    'Fine contratto',
    'Un abbonamento sta raggiungendo la fine del contratto.',
  ),
};

class TesterDashboardScreen extends ConsumerWidget {
  const TesterDashboardScreen({super.key});

  Future<void> _testNotification(
    BuildContext context,
    String title,
    String body,
  ) async {
    try {
      await NotificationTestService.instance.show(title, body);
      if (context.mounted) {
        showAppMessage(context, 'Notifica di test inviata al dispositivo');
      }
    } catch (error) {
      if (context.mounted) {
        showAppMessage(context, 'Test non riuscito: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allowed =
        user != null &&
        ({'tester', 'admin'}.contains(user.role) ||
            user.email == 'acampione97@gmail.com');
    if (!allowed) {
      return const Scaffold(
        body: Center(child: Text('Area riservata ai tester')),
      );
    }
    final results = ref.watch(testerResultsProvider);
    final statuses = results.valueOrNull ?? const <String, String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard tester')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(testerResultsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const ListTile(
                leading: Icon(Icons.science_outlined),
                title: Text('Test notifiche sul dispositivo corrente'),
                subtitle: Text(
                  'Questi pulsanti verificano permessi e visualizzazione locale. '
                  'Le push in background richiedono ancora Web Push/FCM e la '
                  'registrazione del dispositivo.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in _notificationTests.entries)
              _TestCard(
                testKey: entry.key,
                title: entry.value.$1,
                body: entry.value.$2,
                status: statuses[entry.key] ?? 'pending',
                onTest: () =>
                    _testNotification(context, entry.value.$1, entry.value.$2),
                onStatus: (status) async {
                  try {
                    await ref.read(testerApiProvider).setResult(entry.key, {
                      'status': status,
                    });
                    ref.invalidate(testerResultsProvider);
                  } catch (_) {
                    if (context.mounted) {
                      showAppMessage(
                        context,
                        'Il salvataggio esiti sarà disponibile dopo il deploy.',
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.testKey,
    required this.title,
    required this.body,
    required this.status,
    required this.onTest,
    required this.onStatus,
  });

  final String testKey, title, body, status;
  final VoidCallback onTest;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey(testKey),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(title),
            subtitle: Text(body),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('INVIA TEST'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Esito'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Da testare'),
                    ),
                    DropdownMenuItem(value: 'passed', child: Text('Superato')),
                    DropdownMenuItem(value: 'partial', child: Text('Parziale')),
                    DropdownMenuItem(value: 'ko', child: Text('KO')),
                  ],
                  onChanged: (value) => onStatus(value!),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
