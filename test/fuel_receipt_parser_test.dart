import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/ocr/fuel_receipt_parser.dart';

void main() {
  test('riconosce totale litri e prezzo dal display carburante', () {
    final values = parseFuelReceipt(
      'TOTALE 50,00 EUR\nLITRI 27,793 L\nPREZZO/LITRO 1,799 €/L',
    );
    expect(values.total, 50);
    expect(values.liters, 27.793);
    expect(values.pricePerLiter, 1.799);
  });

  test('riconosce il display con valori prima delle etichette', () {
    final values = parseFuelReceipt(
      '50.14 IMPORTO €\n27.12 LITRI\n1.849 PREZZO € PER LITRO',
    );
    expect(values.total, 50.14);
    expect(values.liters, 27.12);
    expect(values.pricePerLiter, 1.849);
  });
}
