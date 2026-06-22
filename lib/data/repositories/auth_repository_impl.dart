import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/data/remote/api_client.dart';
import 'package:spendwise/domain/models/user.dart';
import 'package:spendwise/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.client, this.storage);
  final AuthApiClient client; final FlutterSecureStorage storage;
  static const _userKey = 'current_user';
  Future<User> _save(Future<AuthResponse> request) async {
    final response = await request;
    await storage.write(key: AppConstants.kAccessTokenKey, value: response.tokens.accessToken);
    await storage.write(key: AppConstants.kRefreshTokenKey, value: response.tokens.refreshToken);
    await storage.write(key: _userKey, value: jsonEncode(response.user.toJson()));
    return response.user;
  }
  @override Future<User> login(String email, String password) => _save(client.login(LoginRequest(email: email, password: password)));
  @override Future<User> register(String email, String password, String name) => _save(client.register(RegisterRequest(email: email, password: password, name: name)));
  @override Future<User?> currentUser() async { final raw = await storage.read(key: _userKey); return raw == null ? null : User.fromJson(jsonDecode(raw) as Map<String,dynamic>); }
  @override Future<void> logout() async { try { await client.logout(); } finally { await storage.deleteAll(); } }
}
