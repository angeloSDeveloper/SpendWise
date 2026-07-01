import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

void main() {
  testWidgets('un tap sul banner lo chiude', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppMessage(
                context,
                'Messaggio di prova',
                durationSeconds: 15,
              ),
              child: const Text('Mostra'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostra'));
    await tester.pump();
    expect(find.text('Messaggio di prova'), findsOneWidget);

    final dismiss = find
        .ancestor(
          of: find.text('Messaggio di prova'),
          matching: find.byWidgetPredicate(
            (widget) => widget is GestureDetector && widget.onTap != null,
          ),
        )
        .first;
    tester.widget<GestureDetector>(dismiss).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Messaggio di prova'), findsNothing);
  });

  testWidgets('durata zero non mostra il banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppMessage(
                context,
                'Messaggio nascosto',
                durationSeconds: 0,
              ),
              child: const Text('Mostra'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostra'));
    await tester.pump();
    expect(find.text('Messaggio nascosto'), findsNothing);
  });
}
