import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/shared/widgets/swipe_reveal_delete.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lo swipe mostra il cestino senza eliminare', (tester) async {
    var deletions = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              onDelete: () async => deletions++,
              child: const SizedBox(
                height: 72,
                child: ListTile(title: Text('Movimento')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Movimento'), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Elimina'), findsOneWidget);
    expect(deletions, 0);
  });

  testWidgets('il cestino attende dieci secondi e consente annulla', (
    tester,
  ) async {
    var deletions = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              onDelete: () async => deletions++,
              child: const SizedBox(
                height: 72,
                child: ListTile(title: Text('Movimento')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Movimento'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pump();
    expect(deletions, 0);
    expect(find.text('ANNULLA'), findsOneWidget);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump(const Duration(seconds: 11));
    expect(deletions, 0);

    await tester.drag(find.text('Movimento'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pump(const Duration(seconds: 11));
    expect(deletions, 1);
  });

  testWidgets('un tap su un altro elemento richiude lo swipe', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SwipeRevealDelete(
                  onDelete: () async {},
                  child: const SizedBox(
                    height: 72,
                    child: ListTile(title: Text('Primo')),
                  ),
                ),
                SwipeRevealDelete(
                  onDelete: () async {},
                  child: const SizedBox(
                    height: 72,
                    child: ListTile(title: Text('Secondo')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final initialX = tester.getTopLeft(find.text('Primo')).dx;
    await tester.drag(find.text('Primo'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Primo')).dx, lessThan(initialX));

    await tester.tap(find.text('Secondo'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Primo')).dx, initialX);
  });

  testWidgets('la direzione può essere impostata a destra', (tester) async {
    SharedPreferences.setMockInitialValues({'swipe_direction': 'right'});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              onDelete: () async {},
              child: const SizedBox(
                height: 72,
                child: ListTile(title: Text('Movimento')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialX = tester.getTopLeft(find.text('Movimento')).dx;
    await tester.drag(find.text('Movimento'), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Movimento')).dx, greaterThan(initialX));
  });

  testWidgets('durata zero elimina senza mostrare banner', (tester) async {
    SharedPreferences.setMockInitialValues({'banner_duration_seconds': 0});
    var deletions = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SwipeRevealDelete(
              onDelete: () async => deletions++,
              child: const SizedBox(
                height: 72,
                child: ListTile(title: Text('Movimento')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('Movimento'), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pump();
    expect(deletions, 1);
    expect(find.byType(SnackBar), findsNothing);
  });
}
