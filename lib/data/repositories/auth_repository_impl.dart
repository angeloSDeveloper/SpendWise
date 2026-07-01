import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/user.dart';
import 'package:spendwise/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.client, this.storage);
  final AuthApiClient client;
  final FlutterSecureStorage storage;
  static const _userKey = 'current_user';
  Future<User> _save(Future<AuthResponse> request) async {
    final response = await request;
    await storage.write(
      key: AppConstants.kAccessTokenKey,
      value: response.tokens.accessToken,
    );
    await storage.write(
      key: AppConstants.kRefreshTokenKey,
      value: response.tokens.refreshToken,
    );
    await storage.write(
      key: _userKey,
      value: jsonEncode(response.user.toJson()),
    );
    await storage.write(key: AppConstants.kUserIdKey, value: response.user.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('local_unlock_active', false);
    return response.user;
  }

  @override
  Future<User> login(String email, String password) => _save(
    client.login(LoginRequest(email: email, password: password).toJson()),
  );
  @override
  Future<User> register(String email, String password, String name) => _save(
    client.register(
      RegisterRequest(email: email, password: password, name: name).toJson(),
    ),
  );
  @override
  Future<User?> currentUser() async {
    final raw = await storage.read(key: _userKey);
    final refreshToken = await storage.read(key: AppConstants.kRefreshTokenKey);
    if (raw == null || refreshToken == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final biometrics = prefs.getBool('biometrics_enabled') ?? false;
    if (biometrics) {
      try {
        final unlocked = await LocalAuthentication().authenticate(
          localizedReason:
              'Sblocca SpendWise con impronta o riconoscimento biometrico',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (!unlocked) return null;
      } catch (_) {
        return null;
      }
    }
    try {
      final response = await client.refreshToken({
        'refreshToken': refreshToken,
      });
      await _save(Future.value(response));
      return response.user;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        await prefs.setBool('local_unlock_active', true);
        return User.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
      if (biometrics) {
        await prefs.setBool('local_unlock_active', true);
        return User.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
      await storage.deleteAll();
      return null;
    } catch (_) {
      await storage.deleteAll();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.logout();
    } finally {
      (await SharedPreferences.getInstance()).setBool(
        'local_unlock_active',
        false,
      );
      await storage.deleteAll();
    }
  }
}
