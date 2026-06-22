import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/app/app.dart';

void main() {
  testWidgets('mostra la schermata iniziale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpendWiseApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
