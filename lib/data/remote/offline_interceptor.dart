import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/local/offline_store.dart';

class OfflineInterceptor extends Interceptor {
  OfflineInterceptor({required this.store, required this.storage});

  final OfflineStore store;
  final FlutterSecureStorage storage;

  bool _isDataPath(String path) =>
      path.startsWith('/expenses') ||
      path.startsWith('/subscriptions') ||
      path.startsWith('/installments') ||
      path.startsWith('/vehicles');

  Future<String> _userId() async =>
      await storage.read(key: AppConstants.kUserIdKey) ?? 'local-device';

  Future<bool> _backupEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('cloud_backup_enabled') ??
      true;

  Uri _uri(RequestOptions options) => Uri(
    path: options.path,
    queryParameters: options.queryParameters.isEmpty
        ? null
        : options.queryParameters.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isDataPath(options.path) || options.extra['offlineReplay'] == true) {
      return handler.next(options);
    }
    final userId = await _userId();

    if (options.method == 'GET') {
      if (await _backupEnabled()) return handler.next(options);
      final cached = await store.read(userId, _uri(options));
      return handler.resolve(
        Response(
          requestOptions: options,
          data: cached ?? <dynamic>[],
          statusCode: 200,
          extra: const {'localOnly': true},
        ),
      );
    }
    // Ogni scrittura viene confermata prima sul dispositivo. SyncService
    // riproduce poi la coda quando backup e connessione sono disponibili.
    final result = await _queueAndApply(options, userId);
    handler.resolve(
      Response(
        requestOptions: options,
        data: result,
        statusCode: 200,
        extra: const {'localOnly': true},
      ),
    );
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (_isDataPath(options.path) && options.extra['offlineReplay'] != true) {
      final userId = await _userId();
      if (options.method == 'GET') {
        await store.cache(userId, _uri(options), response.data);
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_isDataPath(options.path) ||
        options.extra['offlineReplay'] == true ||
        !_isConnectionError(err)) {
      return handler.next(err);
    }
    final userId = await _userId();
    if (options.method == 'GET') {
      final cached = await store.read(userId, _uri(options));
      if (cached != null) {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cached,
            statusCode: 200,
            extra: const {'offline': true},
          ),
        );
      }
      return handler.next(err);
    }
    final result = await _queueAndApply(options, userId);
    handler.resolve(
      Response(
        requestOptions: options,
        data: result,
        statusCode: 200,
        extra: const {'offline': true},
      ),
    );
  }

  bool _isConnectionError(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;

  Future<dynamic> _queueAndApply(RequestOptions options, String userId) async {
    final uri = _uri(options);
    final data = _jsonData(options.data);
    final result = await store.applyLocalMutation(
      userId: userId,
      method: options.method,
      uri: uri,
      data: data,
    );
    final isAction =
        uri.path.endsWith('/pay-installment') ||
        uri.path.endsWith('/unpay-installment');
    await store.enqueue(
      userId: userId,
      method: options.method,
      uri: uri,
      data: options.method == 'POST' && !isAction ? result : data,
    );
    return result;
  }

  dynamic _jsonData(dynamic data) {
    if (data == null || data is Map || data is List) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }
}
