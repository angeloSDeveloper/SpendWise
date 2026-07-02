import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/local/database.dart';
import 'package:spendwise/data/local/offline_store.dart';
import 'package:spendwise/data/remote/offline_interceptor.dart';
import 'package:spendwise/domain/models/auth_tokens.dart';
import 'package:spendwise/domain/models/daily_expense.dart';
import 'package:spendwise/domain/models/fuel_entry.dart';
import 'package:spendwise/domain/models/installment_plan.dart';
import 'package:spendwise/domain/models/subscription.dart';
import 'package:spendwise/domain/models/user.dart';
import 'package:spendwise/domain/models/vehicle.dart';
import 'package:spendwise/domain/models/vehicle_maintenance.dart';
part 'api_client.freezed.dart';
part 'api_client.g.dart';

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    required String name,
  }) = _RegisterRequest;
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
abstract class RefreshRequest with _$RefreshRequest {
  const factory RefreshRequest({required String refreshToken}) =
      _RefreshRequest;
  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);
}

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({required User user, required AuthTokens tokens}) =
      _AuthResponse;
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

class DioClient {
  DioClient({FlutterSecureStorage? storage, OfflineStore? offlineStore})
    : storage = storage ?? const FlutterSecureStorage(),
      offlineStore = offlineStore ?? OfflineStore(AppDatabase.instance) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _authorize,
        onResponse: _unwrap,
        onError: _refreshAndRetry,
      ),
    );
    dio.interceptors.add(
      OfflineInterceptor(store: this.offlineStore, storage: this.storage),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
  late final Dio dio;
  final FlutterSecureStorage storage;
  final OfflineStore offlineStore;
  Future<String>? _refreshFuture;
  Future<void> _authorize(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: AppConstants.kAccessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _unwrap(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      response.data = body['data'];
    }
    handler.next(response);
  }

  Future<void> _refreshAndRetry(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode != 401 ||
        error.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(error);
    }
    try {
      final accessToken = await _refreshAccessToken();
      error.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
      handler.resolve(await dio.fetch<dynamic>(error.requestOptions));
    } catch (_) {
      await storage.delete(key: AppConstants.kAccessTokenKey);
      await storage.delete(key: AppConstants.kRefreshTokenKey);
      handler.next(
        DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: 'Sessione scaduta',
          message: 'Sessione scaduta, accedi di nuovo.',
        ),
      );
    }
  }

  Future<String> _refreshAccessToken() {
    final pending = _refreshFuture;
    if (pending != null) return pending;
    final refresh = _performRefresh();
    _refreshFuture = refresh;
    refresh.whenComplete(() {
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    }).ignore();
    return refresh;
  }

  Future<String> _performRefresh() async {
    final refreshToken = await storage.read(key: AppConstants.kRefreshTokenKey);
    if (refreshToken == null) throw StateError('Sessione scaduta');
    final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
    final response = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final tokens = data?['tokens'] as Map<String, dynamic>?;
    if (tokens == null) throw StateError('Risposta refresh non valida');
    final accessToken = tokens['accessToken'] as String;
    await storage.write(key: AppConstants.kAccessTokenKey, value: accessToken);
    await storage.write(
      key: AppConstants.kRefreshTokenKey,
      value: tokens['refreshToken'] as String,
    );
    return accessToken;
  }
}

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String? baseUrl}) = _AuthApiClient;
  @POST('/auth/register')
  Future<AuthResponse> register(@Body() Map<String, dynamic> body);
  @POST('/auth/login')
  Future<AuthResponse> login(@Body() Map<String, dynamic> body);
  @POST('/auth/refresh')
  Future<AuthResponse> refreshToken(@Body() Map<String, dynamic> body);
  @POST('/auth/logout')
  Future<void> logout();
}

@RestApi()
abstract class ExpensesApiClient {
  factory ExpensesApiClient(Dio dio, {String? baseUrl}) = _ExpensesApiClient;
  @GET('/expenses')
  Future<List<DailyExpense>> getExpenses(
    @Query('from') String? from,
    @Query('to') String? to,
    @Query('category') String? category,
  );
  @POST('/expenses')
  Future<DailyExpense> createExpense(@Body() Map<String, dynamic> body);
  @PUT('/expenses/{id}')
  Future<DailyExpense> updateExpense(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/expenses/{id}')
  Future<void> deleteExpense(@Path() String id);
}

@RestApi()
abstract class SubscriptionsApiClient {
  factory SubscriptionsApiClient(Dio dio, {String? baseUrl}) =
      _SubscriptionsApiClient;
  @GET('/subscriptions')
  Future<List<Subscription>> getAll();
  @POST('/subscriptions')
  Future<Subscription> create(@Body() Map<String, dynamic> body);
  @PUT('/subscriptions/{id}')
  Future<Subscription> update(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/subscriptions/{id}')
  Future<void> delete(@Path() String id);
}

@RestApi()
abstract class InstallmentsApiClient {
  factory InstallmentsApiClient(Dio dio, {String? baseUrl}) =
      _InstallmentsApiClient;
  @GET('/installments')
  Future<List<InstallmentPlan>> getAll();
  @POST('/installments')
  Future<InstallmentPlan> create(@Body() Map<String, dynamic> body);
  @POST('/installments/batch')
  Future<List<InstallmentPlan>> createBatch(@Body() Map<String, dynamic> body);
  @PUT('/installments/{id}')
  Future<InstallmentPlan> update(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/installments/{id}')
  Future<void> delete(@Path() String id);
  @POST('/installments/{id}/pay-installment')
  Future<dynamic> pay(@Path() String id);
  @POST('/installments/{id}/unpay-installment')
  Future<dynamic> unpay(@Path() String id);
}

@RestApi()
abstract class VehiclesApiClient {
  factory VehiclesApiClient(Dio dio, {String? baseUrl}) = _VehiclesApiClient;
  @GET('/vehicles')
  Future<List<Vehicle>> getAll();
  @POST('/vehicles')
  Future<Vehicle> create(@Body() Map<String, dynamic> body);
  @PUT('/vehicles/{id}')
  Future<Vehicle> update(@Path() String id, @Body() Map<String, dynamic> body);
  @DELETE('/vehicles/{id}')
  Future<void> delete(@Path() String id);
  @GET('/vehicles/{id}/fuel')
  Future<List<FuelEntry>> fuel(@Path() String id);
  @POST('/vehicles/{id}/fuel')
  Future<FuelEntry> addFuel(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @PUT('/vehicles/{id}/fuel/{entryId}')
  Future<FuelEntry> updateFuel(
    @Path() String id,
    @Path() String entryId,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/vehicles/{id}/fuel/{entryId}')
  Future<void> deleteFuel(@Path() String id, @Path() String entryId);
  @GET('/vehicles/{id}/maintenance')
  Future<List<VehicleMaintenance>> maintenance(@Path() String id);
  @POST('/vehicles/{id}/maintenance')
  Future<VehicleMaintenance> addMaintenance(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @PUT('/vehicles/{id}/maintenance/{entryId}')
  Future<dynamic> updateMaintenance(
    @Path() String id,
    @Path() String entryId,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/vehicles/{id}/maintenance/{entryId}')
  Future<void> deleteMaintenance(@Path() String id, @Path() String entryId);
  @GET('/vehicles/{id}/accessories')
  Future<List<VehicleMaintenance>> accessories(@Path() String id);
  @POST('/vehicles/{id}/accessories')
  Future<VehicleMaintenance> addAccessory(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @PUT('/vehicles/{id}/accessories/{entryId}')
  Future<dynamic> updateAccessory(
    @Path() String id,
    @Path() String entryId,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/vehicles/{id}/accessories/{entryId}')
  Future<void> deleteAccessory(@Path() String id, @Path() String entryId);
}

@RestApi()
abstract class SyncApiClient {
  factory SyncApiClient(Dio dio, {String? baseUrl}) = _SyncApiClient;
  @POST('/sync/push')
  Future<dynamic> push(@Body() Map<String, dynamic> body);
  @GET('/sync/pull')
  Future<dynamic> pull(@Query('since') int since);
}

@freezed
abstract class TesterResult with _$TesterResult {
  const factory TesterResult({
    required String testKey,
    required String status,
    DateTime? updatedAt,
  }) = _TesterResult;
  factory TesterResult.fromJson(Map<String, dynamic> json) =>
      _$TesterResultFromJson(json);
}

@RestApi()
abstract class TesterApiClient {
  factory TesterApiClient(Dio dio, {String? baseUrl}) = _TesterApiClient;
  @GET('/tester/tests')
  Future<List<TesterResult>> getResults();
  @PUT('/tester/tests/{key}')
  Future<TesterResult> setResult(
    @Path() String key,
    @Body() Map<String, dynamic> body,
  );
}
