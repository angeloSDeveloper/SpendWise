import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendwise/core/constants/app_constants.dart';
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
  DioClient({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
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
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
  late final Dio dio;
  final FlutterSecureStorage storage;
  bool _refreshing = false;
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
        error.requestOptions.path.contains('/auth/refresh') ||
        _refreshing) {
      return handler.next(error);
    }
    final refreshToken = await storage.read(key: AppConstants.kRefreshTokenKey);
    if (refreshToken == null) {
      return handler.next(error);
    }
    _refreshing = true;
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final tokens = data?['tokens'] as Map<String, dynamic>?;
      if (tokens == null) throw StateError('Risposta refresh non valida');
      await storage.write(
        key: AppConstants.kAccessTokenKey,
        value: tokens['accessToken'] as String,
      );
      await storage.write(
        key: AppConstants.kRefreshTokenKey,
        value: tokens['refreshToken'] as String,
      );
      error.requestOptions.headers['Authorization'] =
          'Bearer ${tokens['accessToken']}';
      handler.resolve(await dio.fetch<dynamic>(error.requestOptions));
    } catch (_) {
      handler.next(error);
    } finally {
      _refreshing = false;
    }
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
  @PUT('/installments/{id}')
  Future<InstallmentPlan> update(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
  @DELETE('/installments/{id}')
  Future<void> delete(@Path() String id);
  @POST('/installments/{id}/pay-installment')
  Future<dynamic> pay(@Path() String id);
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
  @GET('/vehicles/{id}/maintenance')
  Future<List<VehicleMaintenance>> maintenance(@Path() String id);
  @POST('/vehicles/{id}/maintenance')
  Future<VehicleMaintenance> addMaintenance(
    @Path() String id,
    @Body() Map<String, dynamic> body,
  );
}

@RestApi()
abstract class SyncApiClient {
  factory SyncApiClient(Dio dio, {String? baseUrl}) = _SyncApiClient;
  @POST('/sync/push')
  Future<dynamic> push(@Body() Map<String, dynamic> body);
  @GET('/sync/pull')
  Future<dynamic> pull(@Query('since') int since);
}
