import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/shared/italian_decimal_input_formatter.dart';

void main() {
  TextEditingValue value(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  test('standardizza il punto in virgola con due decimali', () {
    final formatter = ItalianDecimalInputFormatter();
    expect(
      formatter.formatEditUpdate(value('12'), value('12.34')).text,
      '12,34',
    );
    expect(
      formatter.formatEditUpdate(value('12,34'), value('12,345')).text,
      '12,34',
    );
  });

  test('consente tre decimali per il prezzo carburante', () {
    final formatter = ItalianDecimalInputFormatter(decimalDigits: 3);
    expect(
      formatter.formatEditUpdate(value('1'), value('1.849')).text,
      '1,849',
    );
  });
}
