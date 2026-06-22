import 'package:freezed_annotation/freezed_annotation.dart';
part 'fuel_entry.freezed.dart';
part 'fuel_entry.g.dart';
@freezed
class FuelEntry with _$FuelEntry {
  const factory FuelEntry({required String id, required String vehicleId, required String userId, required DateTime date, required double liters, required double pricePerLiter, required double totalCost, String? stationName, int? kmOdometer, @Default(true) bool isFullTank, String? note, required DateTime createdAt, @Default(false) bool synced}) = _FuelEntry;
  factory FuelEntry.fromJson(Map<String, dynamic> json) => _$FuelEntryFromJson(json);
}
