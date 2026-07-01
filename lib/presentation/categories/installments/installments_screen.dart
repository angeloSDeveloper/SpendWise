import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/domain/models/installment_plan.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';
import 'package:spendwise/presentation/shared/widgets/swipe_reveal_delete.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';

final installmentsApiProvider = Provider(
  (ref) => InstallmentsApiClient(ref.watch(dioClientProvider).dio),
);
final installmentsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(installmentsApiProvider).getAll(),
);

String _money(num value) =>
    NumberFormat.currency(locale: 'it_IT', symbol: '€').format(value);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _addMonthsClamped(DateTime date, int months) {
  final zeroBasedMonth = date.month - 1 + months;
  final year = date.year + zeroBasedMonth ~/ 12;
  final month = zeroBasedMonth % 12 + 1;
  final day = date.day.clamp(1, _lastDayOfMonth(year, month));
  return DateTime(year, month, day);
}

DateTime installmentDueDate(
  DateTime startDate,
  InstallmentFrequency frequency,
  int installmentIndex,
) {
  final start = _dateOnly(startDate);
  final safeIndex = installmentIndex < 0 ? 0 : installmentIndex;
  return switch (frequency) {
    InstallmentFrequency.weekly => start.add(Duration(days: 7 * safeIndex)),
    InstallmentFrequency.biweekly => start.add(Duration(days: 14 * safeIndex)),
    InstallmentFrequency.monthly => _addMonthsClamped(start, safeIndex),
  };
}

DateTime installmentFinalDueDate(
  DateTime startDate,
  InstallmentFrequency frequency,
  int totalInstallments,
) => installmentDueDate(startDate, frequency, totalInstallments - 1);

String _readableSaveError(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'Sessione scaduta, accedi di nuovo.';
    }
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final message = body['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (error.message?.isNotEmpty == true) return error.message!;
  }
  return 'Salvataggio non riuscito. Riprova.';
}

class InstallmentsScreen extends ConsumerWidget {
  const InstallmentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(installmentsProvider);
    final items = async.valueOrNull ?? const <InstallmentPlan>[];
    final settings = ref.watch(settingsProvider);
    final dueSoon = settings.notificationsEnabled
        ? items.where((item) {
            if (!item.isActive || item.nextDueDate == null) return false;
            final days = item.nextDueDate!.difference(DateTime.now()).inDays;
            return days >= 0 && days <= settings.notificationDaysBefore;
          }).toList()
        : const <InstallmentPlan>[];
    final residual = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.installmentAmount *
              (item.totalInstallments - item.paidInstallments),
    );
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(installmentsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CategoryHeader(
                color: AppColors.installment,
                title: 'Rateizzazioni',
                value: '${_money(residual)} residui',
                subtitle:
                    '${items.where((item) => item.isActive).length} piani attivi',
              ),
            ),
            if (dueSoon.isNotEmpty)
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text('${dueSoon.length} rate in scadenza'),
                    subtitle: Text(
                      dueSoon
                          .map(
                            (item) =>
                                '${item.name}: ${DateFormat('dd/MM').format(item.nextDueDate!)}',
                          )
                          .join(' · '),
                    ),
                  ),
                ),
              ),
            if (async.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.credit_card,
                  message: 'Nessun piano rateale attivo',
                  action: () => context.push('/installments/add'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return SwipeRevealDelete(
                      key: ValueKey('installment-${item.id}'),
                      deletedMessage: 'Piano rateale rimosso',
                      onDelete: () async {
                        await ref.read(installmentsApiProvider).delete(item.id);
                        ref.invalidate(installmentsProvider);
                      },
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.credit_card),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.paidInstallments}/${item.totalInstallments} rate · prossima ${item.nextDueDate == null ? 'non indicata' : DateFormat('dd/MM/yyyy').format(item.nextDueDate!.toLocal())}',
                          ),
                          trailing: Text(_money(item.installmentAmount)),
                          onTap: () => _showPlan(context, ref, item),
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
        backgroundColor: AppColors.installment,
        onPressed: () => context.push('/installments/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showPlan(
  BuildContext context,
  WidgetRef ref,
  InstallmentPlan item,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
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
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddInstallmentScreen(existing: item),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                color: Theme.of(context).colorScheme.error,
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Eliminare il piano rateale?'),
                      content: const Text(
                        'Il piano e il relativo storico verranno eliminati.',
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
                  await ref.read(installmentsApiProvider).delete(item.id);
                  ref.invalidate(installmentsProvider);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${item.paidInstallments}/${item.totalInstallments} rate',
            ),
            subtitle: Text('Importo rata ${_money(item.installmentAmount)}'),
            trailing: Text('Totale ${_money(item.totalAmount)}'),
          ),
          if (item.nextDueDate != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Prossima scadenza'),
              trailing: Text(
                DateFormat('dd/MM/yyyy').format(item.nextDueDate!.toLocal()),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag),
            title: const Text('Scadenza finale'),
            trailing: Text(
              DateFormat('dd/MM/yyyy').format(
                (item.endDate ??
                        installmentFinalDueDate(
                          item.startDate,
                          item.frequency,
                          item.totalInstallments,
                        ))
                    .toLocal(),
              ),
            ),
          ),
          if (item.isActive)
            FilledButton.icon(
              onPressed: () async {
                await ref.read(installmentsApiProvider).pay(item.id);
                ref.invalidate(installmentsProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.check),
              label: const Text('SEGNA UNA RATA COME PAGATA'),
            ),
          if (item.paidInstallments > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(installmentsApiProvider).unpay(item.id);
                ref.invalidate(installmentsProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.undo),
              label: const Text('ANNULLA ULTIMO PAGAMENTO'),
            ),
          ],
        ],
      ),
    ),
  ),
);

class AddInstallmentScreen extends ConsumerStatefulWidget {
  const AddInstallmentScreen({this.existing, super.key});
  final InstallmentPlan? existing;
  @override
  ConsumerState<AddInstallmentScreen> createState() => _AddInstallmentState();
}

class _InstallmentDraft {
  _InstallmentDraft();

  final name = TextEditingController();
  final total = TextEditingController();
  final installment = TextEditingController();

  void dispose() {
    name.dispose();
    total.dispose();
    installment.dispose();
  }
}

class _AddInstallmentState extends ConsumerState<AddInstallmentScreen> {
  final provider = TextEditingController(),
      count = TextEditingController(),
      note = TextEditingController();
  final drafts = <_InstallmentDraft>[];
  InstallmentFrequency frequency = InstallmentFrequency.monthly;
  DateTime startDate = DateTime.now();
  bool saving = false, multiple = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    final first = _InstallmentDraft();
    drafts.add(first);
    if (item != null) {
      first.name.text = item.name;
      provider.text = item.provider ?? '';
      first.total.text = item.totalAmount.toStringAsFixed(2);
      first.installment.text = item.installmentAmount.toStringAsFixed(2);
      count.text = '${item.totalInstallments}';
      note.text = item.note ?? '';
      frequency = item.frequency;
      startDate = item.startDate.toLocal();
    }
  }

  int get _countValue => int.tryParse(count.text) ?? 0;

  int get _paidInstallments => widget.existing?.paidInstallments ?? 0;

  DateTime get _nextDue =>
      installmentDueDate(startDate, frequency, _paidInstallments);

  DateTime get _finalDue => installmentFinalDueDate(
    startDate,
    frequency,
    _countValue < 1 ? 1 : _countValue,
  );

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  Map<String, dynamic> _bodyFor(_InstallmentDraft draft, int countValue) => {
    'name': draft.name.text.trim(),
    'provider': provider.text.trim(),
    'totalAmount': _number(draft.total),
    'installmentAmount': _number(draft.installment),
    'totalInstallments': countValue,
    'paidInstallments': _paidInstallments,
    'frequency': frequency.name,
    'startDate': _dateOnly(startDate).millisecondsSinceEpoch,
    'nextDueDate': _nextDue.millisecondsSinceEpoch,
    'endDate': _finalDue.millisecondsSinceEpoch,
    'isActive': _paidInstallments < countValue ? 1 : 0,
    'note': note.text.trim(),
  };

  Future<void> save() async {
    final countValue = int.tryParse(count.text) ?? 0;
    final invalidDraft = drafts.any(
      (draft) =>
          draft.name.text.trim().isEmpty ||
          _number(draft.total) <= 0 ||
          _number(draft.installment) <= 0,
    );
    if (invalidDraft || countValue < 1 || (multiple && drafts.length < 2)) {
      showAppMessage(context, 'Completa tutti i dati obbligatori');
      return;
    }
    setState(() => saving = true);
    try {
      final api = ref.read(installmentsApiProvider);
      if (multiple) {
        await api.createBatch({
          'plans': drafts.map((draft) => _bodyFor(draft, countValue)).toList(),
        });
      } else {
        final body = _bodyFor(drafts.single, countValue);
        widget.existing == null
            ? await api.create(body)
            : await api.update(widget.existing!.id, body);
      }
      ref.invalidate(installmentsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showAppMessage(context, _readableSaveError(error));
      if (error is DioException && error.response?.statusCode == 401) {
        await ref.read(authStateProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    for (final draft in drafts) {
      draft.dispose();
    }
    for (final controller in [provider, count, note]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setMultiple(bool value) {
    if (multiple == value) return;
    setState(() {
      multiple = value;
      if (multiple && drafts.length == 1) {
        drafts.add(_InstallmentDraft());
      } else if (!multiple) {
        for (final draft in drafts.skip(1)) {
          draft.dispose();
        }
        drafts.removeRange(1, drafts.length);
      }
    });
  }

  Widget _draftFields(_InstallmentDraft draft, int index) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  multiple ? 'Acquisto ${index + 1}' : 'Dati acquisto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (multiple && drafts.length > 2)
                IconButton(
                  tooltip: 'Rimuovi acquisto',
                  onPressed: () => setState(() {
                    drafts.removeAt(index).dispose();
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          TextField(
            controller: draft.name,
            decoration: const InputDecoration(
              labelText: 'Prodotto / negozio *',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.total,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Totale *'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.installment,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Importo rata *',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Nuovo piano rateale' : 'Modifica piano',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.existing == null) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Un acquisto')),
              ButtonSegment(value: true, label: Text('Più acquisti')),
            ],
            selected: {multiple},
            onSelectionChanged: (value) => _setMultiple(value.first),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: provider,
          decoration: const InputDecoration(
            labelText: 'Gestore rateale',
            hintText: 'Es. Klarna',
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < drafts.length; index++)
          _draftFields(drafts[index], index),
        if (multiple) ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => drafts.add(_InstallmentDraft())),
            icon: const Icon(Icons.add),
            label: const Text('AGGIUNGI ACQUISTO'),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Numero rate *'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<InstallmentFrequency>(
                initialValue: frequency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Frequenza'),
                items: InstallmentFrequency.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(switch (value) {
                          InstallmentFrequency.weekly => 'Settimanale',
                          InstallmentFrequency.biweekly => 'Ogni 2 settimane',
                          InstallmentFrequency.monthly => 'Mensile',
                        }),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => frequency = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final value = await showDatePicker(
              context: context,
              locale: const Locale('it', 'IT'),
              initialDate: startDate,
              firstDate: DateTime.now().subtract(const Duration(days: 3650)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (value != null) setState(() => startDate = value);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data iniziale / prima rata',
              prefixIcon: Icon(Icons.calendar_month),
            ),
            child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Prossima scadenza',
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_nextDue)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Scadenza finale calcolata',
                  prefixIcon: Icon(Icons.flag),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_finalDue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note'),
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
          label: Text(multiple ? 'SALVA TUTTI I PIANI' : 'SALVA PIANO'),
        ),
      ],
    ),
  );
}
