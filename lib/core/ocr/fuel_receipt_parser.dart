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
    RegExp(r'(?:€/l|eur/l|prezzo\s*(?:al\s*)?litro)\D{0,12}(\d{1,2}\.\d{2,3})'),
    RegExp(r'(\d{1,2}\.\d{3})\s*(?:€/l|eur/l)'),
  ]);
  final liters = find([
    RegExp(r'(?:litri|liters|volume)\D{0,12}(\d{1,3}\.\d{1,3})'),
    RegExp(r'(\d{1,3}\.\d{1,3})\s*l(?:\s|$)'),
  ]);
  final total = find([
    RegExp(r'(?:totale|importo|pagato)\D{0,12}(\d{1,4}\.\d{2})'),
    RegExp(r'(\d{1,4}\.\d{2})\s*(?:€|eur)'),
  ]);
  return FuelReceiptValues(total: total, pricePerLiter: price, liters: liters);
}
