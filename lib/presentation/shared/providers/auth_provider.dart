import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/local/database.dart';
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
      state = AuthState.error(error.toString());
    }
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

class SyncService {
  SyncService(this.ref, this.database, this.api) {
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.syncIntervalSeconds),
      (_) => sync(),
    );
  }
  final Ref ref;
  final AppDatabase database;
  final SyncApiClient api;
  Timer? _timer;
  Future<void> sync() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
      return;
    }
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    try {
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
    } catch (_) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
    }
  }

  void dispose() => _timer?.cancel();
}

final syncServiceProvider = Provider((ref) {
  final service = SyncService(
    ref,
    ref.watch(databaseProvider),
    SyncApiClient(ref.watch(dioClientProvider).dio),
  );
  ref.onDispose(service.dispose);
  return service;
});
