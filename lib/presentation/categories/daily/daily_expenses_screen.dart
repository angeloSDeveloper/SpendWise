import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/daily_expense.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';
import 'package:spendwise/presentation/shared/widgets/swipe_reveal_delete.dart';

final expensesApiProvider = Provider(
  (ref) => ExpensesApiClient(ref.watch(dioClientProvider).dio),
);
final dailyExpensesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(expensesApiProvider).getExpenses(null, null, null),
);

const expenseCategories = <String, (String, IconData)>{
  'spesa': ('Spesa e alimentari', Icons.shopping_cart),
  'frutta': ('Frutta e verdura', Icons.apple),
  'casa': ('Casa', Icons.home),
  'attrezzi': ('Attrezzi e fai-da-te', Icons.handyman),
  'ristorante': ('Ristoranti', Icons.restaurant),
  'trasporti': ('Trasporti', Icons.directions_bus),
  'salute': ('Salute', Icons.medical_services),
  'abbigliamento': ('Abbigliamento', Icons.checkroom),
  'svago': ('Svago', Icons.movie),
  'bollette': ('Bollette', Icons.receipt_long),
  'animali': ('Animali', Icons.pets),
  'altro': ('Altro', Icons.category),
};

String inferCategory(String text) {
  final value = text.toLowerCase();
  if (RegExp(
    r'mel[ae]|banana|frutta|verdura|acqua|pane|latte|supermercato|spesa',
  ).hasMatch(value)) {
    return value.contains('mel') ? 'frutta' : 'spesa';
  }
  if (RegExp(
    r'trapano|vite|martello|chiave|attrezz|brico|leroy',
  ).hasMatch(value)) {
    return 'attrezzi';
  }
  if (RegExp(r'benzina|diesel|bus|treno|taxi|parcheggio').hasMatch(value)) {
    return 'trasporti';
  }
  if (RegExp(r'farmacia|medico|visita|medicina').hasMatch(value)) {
    return 'salute';
  }
  if (RegExp(r'pizza|ristorante|bar|caffè|caffe').hasMatch(value)) {
    return 'ristorante';
  }
  if (RegExp(r'luce|gas|internet|telefono|bolletta').hasMatch(value)) {
    return 'bollette';
  }
  if (RegExp(r'casa|mobile|pulizia').hasMatch(value)) return 'casa';
  return 'altro';
}

String categoryFrom(DailyExpense item) {
  final match = RegExp(r'^categoria:([^\n]+)').firstMatch(item.note ?? '');
  return match?.group(1) ?? inferCategory(item.description ?? '');
}

class DailyExpensesScreen extends ConsumerStatefulWidget {
  const DailyExpensesScreen({super.key});
  @override
  ConsumerState<DailyExpensesScreen> createState() => _State();
}

class _State extends ConsumerState<DailyExpensesScreen> {
  int period = 2;
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyExpensesProvider);
    final now = DateTime.now();
    final items = (async.valueOrNull ?? const <DailyExpense>[])
        .where(
          (item) => switch (period) {
            0 => DateUtils.isSameDay(item.date, now),
            1 => now.difference(item.date).inDays < 7,
            2 => item.date.year == now.year && item.date.month == now.month,
            _ => item.date.year == now.year,
          },
        )
        .toList();
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dailyExpensesProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CategoryHeader(
                color: AppColors.daily,
                title: 'Spese quotidiane',
                value: NumberFormat.currency(
                  locale: 'it_IT',
                  symbol: '€',
                ).format(total),
                subtitle: '${items.length} movimenti nel periodo',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Oggi')),
                    ButtonSegment(value: 1, label: Text('Settimana')),
                    ButtonSegment(value: 2, label: Text('Mese')),
                    ButtonSegment(value: 3, label: Text('Anno')),
                  ],
                  selected: {period},
                  onSelectionChanged: (v) => setState(() => period = v.first),
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
                  icon: Icons.receipt_long,
                  message: 'Nessuna spesa nel periodo selezionato',
                  action: () => context.push('/daily/add'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index],
                        key = categoryFrom(item),
                        category =
                            expenseCategories[key] ??
                            expenseCategories['altro']!;
                    return SwipeRevealDelete(
                      key: ValueKey('expense-${item.id}'),
                      deletedMessage: 'Spesa rimossa',
                      onDelete: () async {
                        await ref
                            .read(expensesApiProvider)
                            .deleteExpense(item.id);
                        final synced = await ref
                            .read(syncServiceProvider)
                            .sync();
                        if (synced) ref.invalidate(dailyExpensesProvider);
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(category.$2)),
                          title: Text(
                            item.description?.isNotEmpty == true
                                ? item.description!
                                : category.$1,
                          ),
                          subtitle: Text(
                            '${category.$1} · ${DateFormat('dd/MM/yyyy').format(item.date.toLocal())}',
                          ),
                          trailing: Text(
                            NumberFormat.currency(
                              locale: 'it_IT',
                              symbol: '€',
                            ).format(item.amount),
                          ),
                          onTap: () => _showExpense(context, ref, item),
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
        backgroundColor: AppColors.daily,
        onPressed: () => context.push('/daily/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _showExpense(
  BuildContext context,
  WidgetRef ref,
  DailyExpense item,
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
                  item.description ?? 'Spesa',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddDailyExpenseScreen(existing: item),
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
                      title: const Text('Eliminare questa spesa?'),
                      content: const Text(
                        'Il movimento verrà eliminato definitivamente.',
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
                  await ref.read(expensesApiProvider).deleteExpense(item.id);
                  ref.invalidate(dailyExpensesProvider);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.euro),
            title: Text(
              NumberFormat.currency(
                locale: 'it_IT',
                symbol: '€',
              ).format(item.amount),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy').format(item.date.toLocal()),
            ),
          ),
          if (item.note?.isNotEmpty == true)
            Text(item.note!.replaceFirst(RegExp(r'^categoria:[^\n]+\n?'), '')),
        ],
      ),
    ),
  ),
);

class AddDailyExpenseScreen extends ConsumerStatefulWidget {
  const AddDailyExpenseScreen({this.existing, super.key});
  final DailyExpense? existing;
  @override
  ConsumerState<AddDailyExpenseScreen> createState() => _AddDailyExpenseState();
}

class _AddDailyExpenseState extends ConsumerState<AddDailyExpenseScreen> {
  final description = TextEditingController(),
      amount = TextEditingController(),
      note = TextEditingController();
  String category = 'altro';
  DateTime date = DateTime.now();
  bool automatic = true, saving = false;
  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      description.text = item.description ?? '';
      amount.text = item.amount.toStringAsFixed(2);
      category = categoryFrom(item);
      note.text = (item.note ?? '').replaceFirst(
        RegExp(r'^categoria:[^\n]+\n?'),
        '',
      );
      date = item.date.toLocal();
      automatic = false;
    }
    description.addListener(() {
      if (automatic) setState(() => category = inferCategory(description.text));
    });
  }

  @override
  void dispose() {
    description.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.replaceAll(',', '.')) ?? 0;
    if (description.text.trim().isEmpty || value <= 0) {
      showAppMessage(context, 'Inserisci descrizione e importo validi');
      return;
    }
    setState(() => saving = true);
    try {
      final body = {
        'amount': value,
        'description': description.text.trim(),
        'date': date.millisecondsSinceEpoch,
        'note': 'categoria:$category\n${note.text.trim()}',
      };
      final api = ref.read(expensesApiProvider);
      if (widget.existing == null) {
        await api.createExpense(body);
      } else {
        await api.updateExpense(widget.existing!.id, body);
      }
      ref.invalidate(dailyExpensesProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        showAppMessage(context, 'Salvataggio non riuscito: $error');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Nuova spesa' : 'Modifica spesa'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: description,
          decoration: const InputDecoration(
            labelText: 'Cosa hai acquistato? *',
            hintText: 'Es. cassa d’acqua, mele, trapano',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    locale: const Locale('it', 'IT'),
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selected != null) setState(() => date = selected);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data'),
                  child: Text(DateFormat('dd/MM/yyyy').format(date)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Importo *'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: automatic,
          title: const Text(
            'Riconosci categoria automaticamente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('Rilevata: ${expenseCategories[category]!.$1}'),
          onChanged: (v) => setState(() {
            automatic = v;
            if (v) category = inferCategory(description.text);
          }),
        ),
        DropdownButtonFormField<String>(
          initialValue: category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: expenseCategories.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(e.value.$2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: automatic ? null : (v) => setState(() => category = v!),
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
          icon: const Icon(Icons.save),
          label: const Text('Salva spesa'),
        ),
      ],
    ),
  );
}
