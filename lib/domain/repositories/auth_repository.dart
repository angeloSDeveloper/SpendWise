import 'package:spendwise/domain/models/user.dart';

abstract interface class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String email, String password, String name);
  Future<void> logout();
  Future<User?> currentUser();
}
