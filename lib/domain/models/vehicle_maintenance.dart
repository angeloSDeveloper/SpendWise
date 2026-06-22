import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/domain/models/enums.dart';
part 'vehicle_maintenance.freezed.dart';
part 'vehicle_maintenance.g.dart';

@freezed
abstract class VehicleMaintenance with _$VehicleMaintenance {
  const factory VehicleMaintenance({
    required String id,
    required String vehicleId,
    required String userId,
    required DateTime date,
    required String itemName,
    String? partCode,
    MaintenanceCategory? category,
    required double price,
    @Default(1) int quantity,
    required double totalCost,
    String? shopName,
    String? shopUrl,
    int? kmAtService,
    int? nextServiceKm,
    DateTime? nextServiceDate,
    int? warrantyMonths,
    String? receiptUrl,
    String? note,
    required DateTime createdAt,
    @Default(false) bool synced,
  }) = _VehicleMaintenance;
  factory VehicleMaintenance.fromJson(Map<String, dynamic> json) =>
      _$VehicleMaintenanceFromJson(json);
}
