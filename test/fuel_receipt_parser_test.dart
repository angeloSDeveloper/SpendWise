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
}
