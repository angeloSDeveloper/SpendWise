import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/local/database.dart';
import 'package:spendwise/data/local/offline_store.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/data/repositories/auth_repository_impl.dart';
import 'package:spendwise/domain/models/user.dart';
import 'package:spendwise/domain/repositories/auth_repository.dart';
part 'auth_provider.freezed.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final dioClientProvider = Provider(
  (ref) => DioClient(storage: ref.watch(secureStorageProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRepositoryImpl(
    AuthApiClient(dio.dio),
    ref.watch(secureStorageProvider),
  );
});

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.repository) : super(const AuthState.initial());
  final AuthRepository repository;
  Future<void> login(String email, String password) =>
      _authenticate(() => repository.login(email, password));
  Future<void> register(String email, String password, String name) =>
      _authenticate(() => repository.register(email, password, name));
  Future<void> _authenticate(Future<User> Function() action) async {
    state = const AuthState.loading();
    try {
      state = AuthState.authenticated(await action());
    } catch (error) {
      state = AuthState.error(_readableError(error));
    }
  }

  String _readableError(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        final message = body['error'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Impossibile contattare il server. Controlla la connessione.';
      }
    }
    return 'Si è verificato un errore. Riprova.';
  }

  Future<void> checkAuthStatus() async {
    final user = await repository.currentUser();
    state = user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await repository.logout();
    state = const AuthState.unauthenticated();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider))..checkAuthStatus(),
);
final currentUserProvider = Provider<User?>(
  (ref) => ref
      .watch(authStateProvider)
      .maybeWhen(authenticated: (user) => user, orElse: () => null),
);

enum SyncStatus { synced, pending, syncing, offline, error }

final syncStatusProvider = StateProvider((ref) => SyncStatus.synced);
final syncInfoProvider = StateProvider((ref) => const SyncInfo());

class SyncInfo {
  const SyncInfo({this.pending = 0, this.error, this.lastCompletedAt});

  final int pending;
  final String? error;
  final DateTime? lastCompletedAt;
}

class SyncService {
  SyncService(this.ref, this.database, this.api, this.dio, this.storage) {
    scheduleMicrotask(sync);
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.syncIntervalSeconds),
      (_) => sync(),
    );
  }
  final Ref ref;
  final AppDatabase database;
  final SyncApiClient api;
  final Dio dio;
  final FlutterSecureStorage storage;
  Timer? _timer;
  Future<bool> sync({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final backupEnabled = prefs.getBool('cloud_backup_enabled') ?? true;
    final userId =
        await storage.read(key: AppConstants.kUserIdKey) ?? 'local-device';
    final pendingBefore = await database.offlineRequestCount(userId);
    if (!backupEnabled && !force) {
      ref.read(syncStatusProvider.notifier).state = pendingBefore > 0
          ? SyncStatus.pending
          : SyncStatus.synced;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        pending: pendingBefore,
        error: pendingBefore > 0
            ? 'Backup disattivato: le modifiche restano sul dispositivo.'
            : null,
      );
      return true;
    }
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        pending: pendingBefore,
        error: 'Dispositivo non connesso a Internet.',
      );
      return false;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    ref.read(syncInfoProvider.notifier).state = SyncInfo(
      pending: pendingBefore,
    );
    try {
      final requests = await database.pendingOfflineRequests(userId);
      for (final request in requests) {
        try {
          final query = Map<String, dynamic>.from(
            jsonDecode(request.query) as Map,
          );
          await dio.request<dynamic>(
            request.path,
            data: request.payload == null ? null : jsonDecode(request.payload!),
            queryParameters: query,
            options: Options(
              method: request.method,
              extra: const {'offlineReplay': true},
            ),
          );
          await database.removeOfflineRequest(request.id);
        } catch (error) {
          final alreadyDeleted =
              request.method == 'DELETE' &&
              error is DioException &&
              error.response?.statusCode == 404;
          if (alreadyDeleted) {
            await database.removeOfflineRequest(request.id);
            continue;
          }
          await database.incrementOfflineAttempts(request.id);
          rethrow;
        }
      }
      final queue = await database.pendingSync();
      if (queue.isNotEmpty) {
        await api.push({
          'operations': queue
              .map(
                (e) => {
                  'id': e.id,
                  'table': e.targetTable,
                  'recordId': e.recordId,
                  'operation': e.operation,
                  'payload': e.payload,
                },
              )
              .toList(),
        });
        await database.removeSync(queue.map((e) => e.id));
      }
      ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        lastCompletedAt: DateTime.now(),
      );
      return true;
    } catch (error) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        pending: await database.offlineRequestCount(userId),
        error: _readableSyncError(error),
      );
      return false;
    }
  }

  Future<bool> restoreFromCloud() async {
    final userId =
        await storage.read(key: AppConstants.kUserIdKey) ?? 'local-device';
    final pending = await database.offlineRequestCount(userId);
    if (pending > 0) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.pending;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        pending: pending,
        error:
            'Ci sono $pending modifiche locali non salvate. '
            'Esegui prima “Backup ora”.',
      );
      return false;
    }
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
      ref.read(syncInfoProvider.notifier).state = const SyncInfo(
        error: 'Serve una connessione Internet per ripristinare il backup.',
      );
      return false;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    ref.read(syncInfoProvider.notifier).state = const SyncInfo();
    final store = OfflineStore(database);
    try {
      Future<List<dynamic>> download(String path) async {
        final response = await dio.get<dynamic>(
          path,
          options: Options(extra: const {'offlineReplay': true}),
        );
        final rows = response.data is List
            ? List<dynamic>.from(response.data as List)
            : <dynamic>[];
        await store.cache(userId, Uri(path: path), rows);
        return rows;
      }

      await download('/expenses');
      await download('/subscriptions');
      await download('/installments');
      final vehicles = await download('/vehicles');
      for (final vehicle in vehicles.whereType<Map>()) {
        final id = vehicle['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await download('/vehicles/$id/fuel');
        await download('/vehicles/$id/maintenance');
        await download('/vehicles/$id/accessories');
      }
      ref.read(syncStatusProvider.notifier).state = SyncStatus.synced;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        lastCompletedAt: DateTime.now(),
      );
      return true;
    } catch (error) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      ref.read(syncInfoProvider.notifier).state = SyncInfo(
        error: _readableSyncError(error),
      );
      return false;
    }
  }

  String _readableSyncError(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      final serverMessage = body is Map ? body['error'] : null;
      if (serverMessage is String && serverMessage.isNotEmpty) {
        return serverMessage;
      }
      final status = error.response?.statusCode;
      if (status != null) return 'Il server ha risposto con errore $status.';
      return 'Connessione al server non riuscita.';
    }
    return 'Una modifica locale non è stata sincronizzata.';
  }

  void dispose() => _timer?.cancel();
}

final syncServiceProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  final service = SyncService(
    ref,
    ref.watch(databaseProvider),
    SyncApiClient(dioClient.dio),
    dioClient.dio,
    storage,
  );
  ref.onDispose(service.dispose);
  return service;
});
