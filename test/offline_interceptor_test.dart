import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/data/local/database.dart';
import 'package:spendwise/data/local/offline_store.dart';
import 'package:spendwise/data/remote/offline_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('con backup attivo una POST raggiunge subito il server', () async {
    SharedPreferences.setMockInitialValues({'cloud_backup_enabled': true});
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OfflineInterceptor(
          store: OfflineStore(AppDatabase.instance),
          storage: const FlutterSecureStorage(),
        ),
      );

    final response = await dio.post<Map<String, dynamic>>(
      '/vehicles/vehicle-1/fuel',
      data: {'totalCost': 50},
    );

    expect(adapter.calls, 1);
    expect(response.statusCode, 201);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"id":"fuel-1"}',
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
