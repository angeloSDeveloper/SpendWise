import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/domain/models/enums.dart';
part 'subscription.freezed.dart';
part 'subscription.g.dart';
@freezed
class Subscription with _$Subscription {
  const factory Subscription({required String id, required String userId, required String name, required double amount, @Default('EUR') String currency, required BillingCycle billingCycle, int? billingDay, required DateTime startDate, DateTime? endDate, String? url, String? icon, String? color, @Default(true) bool isActive, String? note, required DateTime createdAt, required DateTime updatedAt, @Default(false) bool synced}) = _Subscription;
  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}
