import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/domain/models/vehicle.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';
import 'package:spendwise/presentation/categories/vehicle/vehicle_screen.dart';

void main() {
  testWidgets('la modalità multi-acquisto prepara almeno due piani', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddInstallmentScreen())),
    );

    await tester.tap(find.text('Più acquisti'));
    await tester.pump();

    expect(find.text('Acquisto 1'), findsOneWidget);
    expect(find.text('Acquisto 2'), findsOneWidget);
    expect(find.text('Prodotto / negozio *'), findsNWidgets(2));
  });

  testWidgets('il piano singolo mostra prima rata e scadenza finale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddInstallmentScreen())),
    );

    await tester.scrollUntilVisible(
      find.text('Scadenza finale calcolata'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Data iniziale / prima rata'), findsOneWidget);
    expect(find.text('Scadenza finale calcolata'), findsOneWidget);
  });

  testWidgets('il pieno completo usa la capacità del serbatoio', (
    tester,
  ) async {
    final vehicle = Vehicle(
      id: 'vehicle-1',
      userId: 'user-1',
      name: 'Auto',
      fuelType: FuelType.gasoline,
      tankCapacityLiters: 45,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiclesProvider.overrideWith((ref) async => [vehicle]),
        ],
        child: const MaterialApp(home: AddFuelScreen(vehicleId: 'vehicle-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pieno completo'));
    await tester.pumpAndSettle();

    expect(find.text('Dettagliato'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
  });
}
