class FuelReceiptValues {
  const FuelReceiptValues({this.total, this.pricePerLiter, this.liters});
  final double? total;
  final double? pricePerLiter;
  final double? liters;
  bool get hasValues =>
      total != null || pricePerLiter != null || liters != null;
}

FuelReceiptValues parseFuelReceipt(String text) {
  final normalized = text.toLowerCase().replaceAll(',', '.');
  double? find(List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(normalized);
      final raw = match?.group(1);
      if (raw != null) return double.tryParse(raw);
    }
    return null;
  }

  final price = find([
    RegExp(
      r'(?:€/l|eur/l|prezzo\s*(?:€\s*)?(?:per|al)\s*litro)[^\d\r\n]{0,16}(\d{1,2}\.\d{2,3})',
    ),
    RegExp(
      r'(\d{1,2}\.\d{2,3})[^\d\r\n]{0,16}(?:€/l|eur/l|prezzo\s*(?:€\s*)?(?:per|al)\s*litro)',
    ),
  ]);
  final liters = find([
    RegExp(r'(?:litri|liters|volume)[^\d\r\n]{0,12}(\d{1,3}\.\d{1,3})'),
    RegExp(r'(\d{1,3}\.\d{1,3})[^\d\r\n]{0,12}(?:litri|liters|volume|\bl\b)'),
  ]);
  final total = find([
    RegExp(r'(?:totale|importo|pagato)[^\d\r\n]{0,12}(\d{1,4}\.\d{2})'),
    RegExp(r'(\d{1,4}\.\d{2})[^\d\r\n]{0,12}(?:totale|importo|pagato|€|eur)'),
  ]);
  return FuelReceiptValues(total: total, pricePerLiter: price, liters: liters);
}
