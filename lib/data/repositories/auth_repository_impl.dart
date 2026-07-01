import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    final pinEnabled = await storage.containsKey(key: 'app_pin_hash');
    final localProtection = biometrics || pinEnabled;
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
      if (localProtection) {
        await prefs.setBool('local_unlock_active', true);
        return User.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
      await _clearSession();
      return null;
    } catch (_) {
      await _clearSession();
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
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    await storage.delete(key: AppConstants.kAccessTokenKey);
    await storage.delete(key: AppConstants.kRefreshTokenKey);
    await storage.delete(key: AppConstants.kUserIdKey);
    await storage.delete(key: _userKey);
  }
}
