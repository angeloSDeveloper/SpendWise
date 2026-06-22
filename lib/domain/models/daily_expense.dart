import 'package:freezed_annotation/freezed_annotation.dart';
part 'daily_expense.freezed.dart';
part 'daily_expense.g.dart';

@freezed
abstract class DailyExpense with _$DailyExpense {
  const factory DailyExpense({
    required String id,
    required String userId,
    String? categoryId,
    required double amount,
    String? description,
    required DateTime date,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool synced,
  }) = _DailyExpense;
  factory DailyExpense.fromJson(Map<String, dynamic> json) =>
      _$DailyExpenseFromJson(json);
}
