import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/daily_expense.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/widgets/category_page.dart';

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
                    return Card(
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

class AddDailyExpenseScreen extends ConsumerStatefulWidget {
  const AddDailyExpenseScreen({super.key});
  @override
  ConsumerState<AddDailyExpenseScreen> createState() => _AddDailyExpenseState();
}

class _AddDailyExpenseState extends ConsumerState<AddDailyExpenseScreen> {
  final description = TextEditingController(),
      amount = TextEditingController(),
      note = TextEditingController();
  String category = 'altro';
  bool automatic = true, saving = false;
  @override
  void initState() {
    super.initState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci descrizione e importo validi')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await ref.read(expensesApiProvider).createExpense({
        'amount': value,
        'description': description.text.trim(),
        'date': DateTime.now().millisecondsSinceEpoch,
        'note': 'categoria:$category\n${note.text.trim()}',
      });
      ref.invalidate(dailyExpensesProvider);
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
    appBar: AppBar(title: const Text('Nuova spesa')),
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
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Importo *'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: automatic,
          title: const Text('Riconosci automaticamente la categoria'),
          subtitle: Text('Rilevata: ${expenseCategories[category]!.$1}'),
          onChanged: (v) => setState(() {
            automatic = v;
            if (v) category = inferCategory(description.text);
          }),
        ),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: expenseCategories.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(e.value.$2),
                      const SizedBox(width: 10),
                      Text(e.value.$1),
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
