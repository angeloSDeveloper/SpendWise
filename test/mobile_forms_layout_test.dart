import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/categories/daily/daily_expenses_screen.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';
import 'package:spendwise/presentation/categories/subscriptions/subscriptions_screen.dart';
import 'package:spendwise/presentation/categories/vehicle/vehicle_screen.dart';
import 'package:spendwise/presentation/analytics/analytics_screen.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';

void main() {
  Future<void> pumpMobile(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardDataProvider.overrideWith(
            (ref) async => const DashboardData(
              categories: [0, 0, 0, 0],
              months: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              recent: [],
            ),
          ),
        ],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pump();
  }

  void expectSameRow(WidgetTester tester, String first, String second) {
    final firstRows = find
        .ancestor(of: find.text(first).first, matching: find.byType(Row))
        .evaluate()
        .toSet();
    final secondRows = find
        .ancestor(of: find.text(second).first, matching: find.byType(Row))
        .evaluate()
        .toSet();
    expect(firstRows.intersection(secondRows), isNotEmpty);
  }

  testWidgets('nuova spesa affianca data e importo', (tester) async {
    await pumpMobile(tester, const AddDailyExpenseScreen());
    expectSameRow(tester, 'Data', 'Importo *');
  });

  testWidgets('nuovo abbonamento usa righe compatte', (tester) async {
    await pumpMobile(tester, const AddSubscriptionScreen());
    expectSameRow(tester, 'Prossima scadenza *', 'Fine contratto');
    await tester.tap(find.text('Mensile').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personalizzata').last);
    await tester.pumpAndSettle();
    expect(find.text('Ripeti ogni quanti mesi? *'), findsOneWidget);
  });

  testWidgets('nuovo piano affianca numero rate e frequenza', (tester) async {
    await pumpMobile(tester, const AddInstallmentScreen());
    await tester.scrollUntilVisible(
      find.text('Numero rate *'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expectSameRow(tester, 'Numero rate *', 'Frequenza');
  });

  testWidgets('nuovo veicolo affianca alimentazione e serbatoio', (
    tester,
  ) async {
    await pumpMobile(tester, const AddVehicleScreen());
    await tester.scrollUntilVisible(
      find.text('Alimentazione'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expectSameRow(tester, 'Alimentazione', 'Capacità serbatoio');
  });

  testWidgets('nuovo accessorio rende leggibili prezzo e montaggio', (
    tester,
  ) async {
    await pumpMobile(tester, const AddAccessoryScreen(vehicleId: 'vehicle'));
    await tester.scrollUntilVisible(
      find.text('Prezzo (€) *'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prezzo (€) *'), findsOneWidget);
    expect(find.text('Montaggio (€)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analisi mantiene 1 mese su una sola riga', (tester) async {
    await pumpMobile(tester, const AnalyticsScreen());
    final label = tester.widget<Text>(find.text('1 mese'));
    expect(label.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}
