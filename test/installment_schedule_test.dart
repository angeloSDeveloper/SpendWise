import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/domain/models/enums.dart';
import 'package:spendwise/presentation/categories/installments/installments_screen.dart';

void main() {
  group('installment schedule', () {
    test('calcola la scadenza finale di tre rate mensili', () {
      final start = DateTime(2026, 6, 29);

      expect(
        installmentFinalDueDate(start, InstallmentFrequency.monthly, 3),
        DateTime(2026, 8, 29),
      );
    });

    test('mantiene il giorno valido quando il mese e piu corto', () {
      final start = DateTime(2026, 1, 31);

      expect(
        installmentDueDate(start, InstallmentFrequency.monthly, 1),
        DateTime(2026, 2, 28),
      );
    });

    test('calcola la scadenza finale settimanale', () {
      expect(
        installmentFinalDueDate(
          DateTime(2026, 7, 16),
          InstallmentFrequency.weekly,
          3,
        ),
        DateTime(2026, 7, 30),
      );
    });

    test('calcola la scadenza finale bisettimanale', () {
      expect(
        installmentFinalDueDate(
          DateTime(2026, 7, 16),
          InstallmentFrequency.biweekly,
          3,
        ),
        DateTime(2026, 8, 13),
      );
    });

    test('calcola il fine mese dalla data iniziale originale', () {
      expect(
        installmentFinalDueDate(
          DateTime(2026, 1, 31),
          InstallmentFrequency.monthly,
          3,
        ),
        DateTime(2026, 3, 31),
      );
    });

    test('calcola la prossima rata in base alle rate gia pagate', () {
      final start = DateTime(2026, 6, 29);

      expect(
        installmentDueDate(start, InstallmentFrequency.weekly, 2),
        DateTime(2026, 7, 13),
      );
    });
  });
}
