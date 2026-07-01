import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/domain/models/enums.dart';
part 'installment_plan.freezed.dart';
part 'installment_plan.g.dart';

@freezed
abstract class InstallmentPlan with _$InstallmentPlan {
  const factory InstallmentPlan({
    required String id,
    required String userId,
    required String name,
    String? provider,
    required double totalAmount,
    required double installmentAmount,
    required int totalInstallments,
    @Default(0) int paidInstallments,
    required InstallmentFrequency frequency,
    required DateTime startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    @Default(true) bool isActive,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool synced,
  }) = _InstallmentPlan;
  factory InstallmentPlan.fromJson(Map<String, dynamic> json) =>
      _$InstallmentPlanFromJson(json);
}
