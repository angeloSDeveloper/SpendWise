import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/domain/models/enums.dart';
part 'installment_payment.freezed.dart';
part 'installment_payment.g.dart';
@freezed
class InstallmentPayment with _$InstallmentPayment {
  const factory InstallmentPayment({required String id, required String planId, required String userId, required int installmentNumber, required double amount, required DateTime dueDate, DateTime? paidDate, @Default(PaymentStatus.pending) PaymentStatus status}) = _InstallmentPayment;
  factory InstallmentPayment.fromJson(Map<String, dynamic> json) => _$InstallmentPaymentFromJson(json);
}
