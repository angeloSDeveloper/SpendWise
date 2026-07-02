import 'package:flutter/services.dart';

/// Accetta punto o virgola, visualizza sempre la virgola italiana e limita
/// le cifre decimali senza modificare il valore numerico.
class ItalianDecimalInputFormatter extends TextInputFormatter {
  ItalianDecimalInputFormatter({this.decimalDigits = 2});

  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text.replaceAll('.', ',');
    final pattern = RegExp('^\\d*(,\\d{0,$decimalDigits})?\$');
    if (!pattern.hasMatch(normalized)) return oldValue;
    return newValue.copyWith(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
      composing: TextRange.empty,
    );
  }
}
