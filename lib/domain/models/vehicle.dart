import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/domain/models/enums.dart';
part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String userId,
    required String name,
    String? plate,
    String? brand,
    String? model,
    int? year,
    FuelType? fuelType,
    double? tankCapacityLiters,
    @Default(false) bool isArchived,
    required DateTime createdAt,
  }) = _Vehicle;
  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}
