import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/data/local/database.dart';
import 'package:spendwise/data/local/offline_store.dart';
import 'package:spendwise/domain/models/daily_expense.dart';

void main() {
  late AppDatabase database;
  late OfflineStore store;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = OfflineStore(database);
  });

  tearDown(() => database.close());

  test('conserva una risposta per utente e percorso', () async {
    final uri = Uri(path: '/expenses');
    await store.cache('user-1', uri, [
      {'id': 'expense-1', 'amount': 10},
    ]);

    expect(await store.read('user-1', uri), [
      {'id': 'expense-1', 'amount': 10},
    ]);
    expect(await store.read('user-2', uri), isNull);
  });

  test('applica creazione e cancellazione alla copia locale', () async {
    final uri = Uri(path: '/expenses');
    await store.cache('user-1', uri, <dynamic>[]);

    final created =
        await store.applyLocalMutation(
              userId: 'user-1',
              method: 'POST',
              uri: uri,
              data: {
                'amount': 12.5,
                'description': 'Offline',
                'date': DateTime(2026, 7, 1).millisecondsSinceEpoch,
              },
            )
            as Map<String, dynamic>;
    expect(created['id'], isNotEmpty);
    expect(DailyExpense.fromJson(created).userId, 'user-1');
    expect((await store.read('user-1', uri) as List), hasLength(1));

    await store.applyLocalMutation(
      userId: 'user-1',
      method: 'DELETE',
      uri: Uri(path: '/expenses/${created['id']}'),
    );
    expect(await store.read('user-1', uri), isEmpty);
  });

  test('mantiene in ordine le operazioni da inviare al backup', () async {
    await store.enqueue(
      userId: 'user-1',
      method: 'POST',
      uri: Uri(path: '/expenses'),
      data: {'id': 'one'},
    );
    await store.enqueue(
      userId: 'user-1',
      method: 'DELETE',
      uri: Uri(path: '/expenses/one'),
    );

    final queue = await database.pendingOfflineRequests('user-1');
    expect(queue.map((item) => item.method), ['POST', 'DELETE']);
    expect(await database.offlineRequestCount('user-1'), 2);
  });
}
