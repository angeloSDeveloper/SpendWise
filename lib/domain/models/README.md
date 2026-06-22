# Domain Models

L'agente deve creare i seguenti file usando il package `freezed`:

## File da creare:

### user.dart
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    required DateTime createdAt,
  }) = _User;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### daily_expense.dart
Campi: id, userId, categoryId, amount, description, date, note, createdAt, updatedAt, synced

### subscription.dart
Campi: id, userId, name, amount, currency, billingCycle (enum: weekly/monthly/yearly),
billingDay, startDate, endDate, url, icon, color, isActive, note, createdAt, updatedAt, synced

### installment_plan.dart
Campi: id, userId, name, provider, totalAmount, installmentAmount, totalInstallments,
paidInstallments, frequency (enum), startDate, nextDueDate, isActive, note

### installment_payment.dart
Campi: id, planId, userId, installmentNumber, amount, dueDate, paidDate, status (enum)

### vehicle.dart
Campi: id, userId, name, plate, brand, model, year, fuelType (enum), createdAt

### fuel_entry.dart
Campi: id, vehicleId, userId, date, liters, pricePerLiter, totalCost, stationName,
kmOdometer, isFullTank, note, createdAt, synced

### vehicle_maintenance.dart
Campi: id, vehicleId, userId, date, itemName, partCode, category (enum: tagliando/
pneumatici/freni/elettrico/altro), price, quantity, totalCost, shopName, shopUrl,
kmAtService, nextServiceKm, nextServiceDate, warrantyMonths, receiptUrl, note, createdAt, synced

### auth_tokens.dart
Campi: accessToken, refreshToken, expiresAt

NOTA: Tutti i modelli devono avere `@freezed` annotation e generare i file `.g.dart` e `.freezed.dart`
