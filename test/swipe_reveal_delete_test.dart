import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/shared/widgets/swipe_reveal_delete.dart';

void main() {
  testWidgets('lo swipe mostra il cestino senza eliminare', (tester) async {
    var deletions = 0;
    await tester.pumpWidget(
      MaterialApp(
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
    );

    await tester.drag(find.text('Movimento'), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Elimina'), findsOneWidget);
    expect(deletions, 0);
  });

  testWidgets('il cestino attende dieci secondi e consente annulla', (
    tester,
  ) async {
    var deletions = 0;
    await tester.pumpWidget(
      MaterialApp(
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
    );

    await tester.drag(find.text('Movimento'), const Offset(100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pump();
    expect(deletions, 0);
    expect(find.text('ANNULLA'), findsOneWidget);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump(const Duration(seconds: 11));
    expect(deletions, 0);

    await tester.drag(find.text('Movimento'), const Offset(100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina'));
    await tester.pump(const Duration(seconds: 11));
    expect(deletions, 1);
  });
}
