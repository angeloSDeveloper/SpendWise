import 'dart:async';
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

  Future<dynamic> _readLocal(String userId, Uri uri) async {
    try {
      return await store
          .read(userId, uri)
          .timeout(const Duration(milliseconds: 750), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isDataPath(options.path) || options.extra['offlineReplay'] == true) {
      return handler.next(options);
    }
    final backupEnabled = await _backupEnabled();
    // Con il backup attivo le scritture raggiungono subito il server. In
    // assenza di rete onError le applica localmente e le accoda. Evitiamo
    // cosi' che una scrittura IndexedDB lenta blocchi indefinitamente i form.
    if (options.method != 'GET' && backupEnabled) {
      return handler.next(options);
    }
    final userId = await _userId();

    if (options.method == 'GET') {
      if (backupEnabled) return handler.next(options);
      final pending = await store.database.offlineRequestCount(userId);
      // Modalita' locale non significa modalita' offline: quando non ci sono
      // modifiche locali da proteggere leggiamo il profilo e aggiorniamo la
      // cache. Se esiste una coda locale, invece, la cache resta la fonte
      // principale finche' l'utente non esegue un backup manuale.
      if (pending == 0) return handler.next(options);
      final cached = await _readLocal(userId, _uri(options));
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
    if (_isDataPath(options.path) &&
        options.method == 'GET' &&
        options.extra['offlineReplay'] != true &&
        response.extra['localOnly'] != true &&
        response.extra['offline'] != true) {
      // La cache e' accessoria: una scrittura IndexedDB lenta o concorrente
      // non deve trattenere una risposta di rete gia' completata.
      unawaited(
        (() async {
          final userId = await _userId();
          await store.cache(userId, _uri(options), response.data);
        })().timeout(const Duration(seconds: 3)).catchError((_) {}),
      );
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
      final cached = await _readLocal(userId, _uri(options));
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
