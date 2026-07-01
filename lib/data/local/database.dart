import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/data/local/open_database.dart';
part 'database.g.dart';

class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DailyExpensesTable extends Table {
  @override
  String get tableName => 'daily_expenses';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get billingCycle => text()();
  IntColumn get billingDay => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SubscriptionPaymentsTable extends Table {
  @override
  String get tableName => 'subscription_payments';
  TextColumn get id => text()();
  TextColumn get subscriptionId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get paidDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('paid'))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InstallmentPlansTable extends Table {
  @override
  String get tableName => 'installment_plans';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get provider => text().nullable()();
  RealColumn get totalAmount => real()();
  RealColumn get installmentAmount => real()();
  IntColumn get totalInstallments => integer()();
  IntColumn get paidInstallments => integer().withDefault(const Constant(0))();
  TextColumn get frequency => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InstallmentPaymentsTable extends Table {
  @override
  String get tableName => 'installment_payments';
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get userId => text()();
  IntColumn get installmentNumber => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get paidDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VehiclesTable extends Table {
  @override
  String get tableName => 'vehicles';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get plate => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get fuelType => text().nullable()();
  RealColumn get tankCapacityLiters => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FuelEntriesTable extends Table {
  @override
  String get tableName => 'fuel_entries';
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get liters => real()();
  RealColumn get pricePerLiter => real()();
  RealColumn get totalCost => real()();
  TextColumn get stationName => text().nullable()();
  IntColumn get kmOdometer => integer().nullable()();
  BoolColumn get isFullTank => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VehicleMaintenanceTable extends Table {
  @override
  String get tableName => 'vehicle_maintenance';
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get itemName => text()();
  TextColumn get partCode => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get totalCost => real()();
  TextColumn get shopName => text().nullable()();
  TextColumn get shopUrl => text().nullable()();
  IntColumn get kmAtService => integer().nullable()();
  IntColumn get nextServiceKm => integer().nullable()();
  DateTimeColumn get nextServiceDate => dateTime().nullable()();
  IntColumn get warrantyMonths => integer().nullable()();
  TextColumn get receiptUrl => text().nullable()();
  TextColumn get itemsJson => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ApiCacheTable extends Table {
  @override
  String get tableName => 'api_cache';
  TextColumn get cacheKey => text()();
  TextColumn get userId => text()();
  TextColumn get path => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class OfflineRequestsTable extends Table {
  @override
  String get tableName => 'offline_requests';
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get method => text()();
  TextColumn get path => text()();
  TextColumn get query => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CategoriesTable,
    DailyExpensesTable,
    SubscriptionsTable,
    SubscriptionPaymentsTable,
    InstallmentPlansTable,
    InstallmentPaymentsTable,
    VehiclesTable,
    FuelEntriesTable,
    VehicleMaintenanceTable,
    SyncQueueTable,
    ApiCacheTable,
    OfflineRequestsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(openDatabase());
  AppDatabase.forTesting(super.executor);
  static final AppDatabase instance = AppDatabase._();
  @override
  int get schemaVersion => 5;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          vehicleMaintenanceTable,
          vehicleMaintenanceTable.itemsJson,
        );
      }
      if (from < 3) {
        await migrator.addColumn(
          vehiclesTable,
          vehiclesTable.tankCapacityLiters,
        );
      }
      if (from < 4) {
        await migrator.addColumn(
          installmentPlansTable,
          installmentPlansTable.endDate,
        );
      }
      if (from < 5) {
        await migrator.createTable(apiCacheTable);
        await migrator.createTable(offlineRequestsTable);
      }
    },
  );
  Future<List<dynamic>> expensesBetween(DateTime from, DateTime to) =>
      (select(dailyExpensesTable)
            ..where((row) => row.date.isBetweenValues(from, to))
            ..orderBy([(row) => OrderingTerm.desc(row.date)]))
          .get();
  Future<List<dynamic>> activeSubscriptions() => (select(
    subscriptionsTable,
  )..where((row) => row.isActive.equals(true))).get();
  Future<List<dynamic>> activeInstallments() => (select(
    installmentPlansTable,
  )..where((row) => row.isActive.equals(true))).get();
  Future<List<dynamic>> fuelForVehicle(String id) =>
      (select(fuelEntriesTable)
            ..where((row) => row.vehicleId.equals(id))
            ..orderBy([(row) => OrderingTerm.desc(row.date)]))
          .get();
  Future<List<dynamic>> maintenanceForVehicle(String id) =>
      (select(vehicleMaintenanceTable)
            ..where((row) => row.vehicleId.equals(id))
            ..orderBy([(row) => OrderingTerm.desc(row.date)]))
          .get();
  Future<List<dynamic>> pendingSync() => (select(
    syncQueueTable,
  )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
  Future<void> removeSync(Iterable<String> ids) =>
      (delete(syncQueueTable)..where((row) => row.id.isIn(ids))).go();

  Future<ApiCacheTableData?> cachedResponse(String key) => (select(
    apiCacheTable,
  )..where((row) => row.cacheKey.equals(key))).getSingleOrNull();

  Future<void> cacheResponse({
    required String key,
    required String userId,
    required String path,
    required String payload,
  }) => into(apiCacheTable).insertOnConflictUpdate(
    ApiCacheTableCompanion.insert(
      cacheKey: key,
      userId: userId,
      path: path,
      payload: payload,
      updatedAt: DateTime.now(),
    ),
  );

  Future<List<ApiCacheTableData>> cachedPath(String userId, String path) =>
      (select(apiCacheTable)
            ..where((row) => row.userId.equals(userId) & row.path.equals(path)))
          .get();

  Future<void> enqueueOfflineRequest(OfflineRequestsTableCompanion request) =>
      into(offlineRequestsTable).insert(request);

  Future<List<OfflineRequestsTableData>> pendingOfflineRequests(
    String userId,
  ) =>
      (select(offlineRequestsTable)
            ..where((row) => row.userId.equals(userId))
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<void> removeOfflineRequest(String id) =>
      (delete(offlineRequestsTable)..where((row) => row.id.equals(id))).go();

  Future<void> incrementOfflineAttempts(String id) async {
    await customStatement(
      'UPDATE offline_requests SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> offlineRequestCount(String userId) async {
    final count = offlineRequestsTable.id.count();
    final query = selectOnly(offlineRequestsTable)
      ..addColumns([count])
      ..where(offlineRequestsTable.userId.equals(userId));
    return (await query.getSingle()).read(count) ?? 0;
  }
}

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);
