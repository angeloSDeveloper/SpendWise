import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:spendwise/data/local/database.dart';
import 'package:uuid/uuid.dart';

class OfflineStore {
  OfflineStore(this.database);

  final AppDatabase database;
  static const _uuid = Uuid();

  String cacheKey(String userId, Uri uri) {
    final query = uri.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final normalized = Uri(
      path: uri.path,
      queryParameters: query.isEmpty
          ? null
          : {for (final entry in query) entry.key: entry.value},
    );
    return '$userId|$normalized';
  }

  Future<dynamic> read(String userId, Uri uri) async {
    final row = await database.cachedResponse(cacheKey(userId, uri));
    return row == null ? null : jsonDecode(row.payload);
  }

  Future<void> cache(String userId, Uri uri, dynamic data) =>
      database.cacheResponse(
        key: cacheKey(userId, uri),
        userId: userId,
        path: uri.path,
        payload: jsonEncode(data),
      );

  Future<void> enqueue({
    required String userId,
    required String method,
    required Uri uri,
    dynamic data,
  }) => database.enqueueOfflineRequest(
    OfflineRequestsTableCompanion.insert(
      id: _uuid.v4(),
      userId: userId,
      method: method,
      path: uri.path,
      query: jsonEncode(uri.queryParameters),
      payload: Value(data == null ? null : jsonEncode(data)),
      createdAt: DateTime.now(),
    ),
  );

  Future<dynamic> applyLocalMutation({
    required String userId,
    required String method,
    required Uri uri,
    dynamic data,
  }) async {
    final segments = uri.pathSegments;
    final now = DateTime.now().toUtc().toIso8601String();
    final body = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    if (uri.path == '/installments/batch') {
      final source = data is List ? data : body['plans'] as List? ?? const [];
      final plans = source
          .map(
            (item) =>
                _newRecord(Map<String, dynamic>.from(item as Map), now, userId),
          )
          .toList();
      for (final plan in plans) {
        await _mutateCollection(userId, '/installments', 'POST', plan);
      }
      return plans;
    }

    if (segments.length >= 3 &&
        segments.first == 'installments' &&
        (segments.last == 'pay-installment' ||
            segments.last == 'unpay-installment')) {
      final existing = await _findRecord(userId, '/installments', segments[1]);
      if (existing == null) return <String, dynamic>{};
      final paid = (existing['paidInstallments'] as num?)?.toInt() ?? 0;
      final total = (existing['totalInstallments'] as num?)?.toInt() ?? 0;
      final isPay = segments.last == 'pay-installment';
      existing['paidInstallments'] = isPay
          ? (paid + 1).clamp(0, total)
          : (paid - 1).clamp(0, total);
      existing['isActive'] = existing['paidInstallments'] < total;
      existing['updatedAt'] = now;
      await _mutateCollection(userId, '/installments', 'PUT', existing);
      return existing;
    }

    final collectionPath = _collectionPath(uri.path);
    if (collectionPath == null) return body;
    final id = _recordId(uri.path, collectionPath);
    if (method == 'DELETE') {
      await _mutateCollection(userId, collectionPath, method, <String, dynamic>{
        'id': id,
      });
      return null;
    }
    final record = method == 'POST'
        ? _newRecord(body, now, userId)
        : {
            ...?_findRecordSync(await _cachedList(userId, collectionPath), id),
            ...body,
            'id': id,
            'updatedAt': now,
          };
    if (collectionPath.contains('/vehicles/')) {
      record['vehicleId'] ??= segments.length > 1 ? segments[1] : null;
    }
    await _mutateCollection(userId, collectionPath, method, record);
    return record;
  }

  Map<String, dynamic> _newRecord(
    Map<String, dynamic> body,
    String now,
    String userId,
  ) {
    final normalized = body.map(
      (key, value) => MapEntry(
        key,
        (key == 'date' || key.endsWith('Date') || key.endsWith('At')) &&
                value is num
            ? DateTime.fromMillisecondsSinceEpoch(
                value.toInt(),
                isUtc: true,
              ).toIso8601String()
            : value,
      ),
    );
    return {
      ...normalized,
      'id': body['id'] ?? _uuid.v4(),
      'userId': body['userId'] ?? userId,
      'currency': body['currency'] ?? 'EUR',
      'paidInstallments': body['paidInstallments'] ?? 0,
      'isActive': body['isActive'] ?? true,
      'isArchived': body['isArchived'] ?? false,
      'createdAt': body['createdAt'] ?? now,
      'updatedAt': body['updatedAt'] ?? now,
    };
  }

  String? _collectionPath(String path) {
    final segments = Uri(path: path).pathSegments;
    if (segments.isEmpty) return null;
    if ({
      'expenses',
      'subscriptions',
      'installments',
      'vehicles',
    }.contains(segments.first)) {
      if (segments.first == 'vehicles' &&
          segments.length >= 3 &&
          {'fuel', 'maintenance', 'accessories'}.contains(segments[2])) {
        return '/vehicles/${segments[1]}/${segments[2]}';
      }
      return '/${segments.first}';
    }
    return null;
  }

  String _recordId(String path, String collectionPath) {
    final remaining = path.substring(collectionPath.length);
    return remaining.split('/').where((part) => part.isNotEmpty).firstOrNull ??
        _uuid.v4();
  }

  Future<List<dynamic>> _cachedList(String userId, String path) async {
    final rows = await database.cachedPath(userId, path);
    if (rows.isEmpty) return [];
    final decoded = jsonDecode(rows.first.payload);
    return decoded is List ? List<dynamic>.from(decoded) : [];
  }

  Map<String, dynamic>? _findRecordSync(List<dynamic> rows, String id) {
    for (final item in rows) {
      if (item is Map && item['id'] == id) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _findRecord(
    String userId,
    String path,
    String id,
  ) async => _findRecordSync(await _cachedList(userId, path), id);

  Future<void> _mutateCollection(
    String userId,
    String path,
    String method,
    Map<String, dynamic> record,
  ) async {
    final rows = await database.cachedPath(userId, path);
    if (rows.isEmpty) {
      final list = method == 'DELETE' ? <dynamic>[] : <dynamic>[record];
      await cache(userId, Uri(path: path), list);
      return;
    }
    for (final row in rows) {
      final decoded = jsonDecode(row.payload);
      if (decoded is! List) continue;
      final list = List<dynamic>.from(decoded);
      final index = list.indexWhere(
        (item) => item is Map && item['id'] == record['id'],
      );
      if (method == 'DELETE') {
        if (index >= 0) list.removeAt(index);
      } else if (index >= 0) {
        list[index] = record;
      } else {
        list.insert(0, record);
      }
      await database.cacheResponse(
        key: row.cacheKey,
        userId: userId,
        path: path,
        payload: jsonEncode(list),
      );
    }
  }
}
