import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pinHashKey = 'app_pin_hash';
const _pinSaltKey = 'app_pin_salt';

class LocalUnlockState {
  const LocalUnlockState({
    this.loading = true,
    this.pinEnabled = false,
    this.biometricsEnabled = false,
    this.unlocked = false,
  });
  final bool loading, pinEnabled, biometricsEnabled, unlocked;
  bool get protectionEnabled => pinEnabled || biometricsEnabled;
}

final localUnlockProvider =
    StateNotifierProvider<LocalUnlockNotifier, LocalUnlockState>(
      (ref) => LocalUnlockNotifier()..load(),
    );

class LocalUnlockNotifier extends StateNotifier<LocalUnlockState> {
  LocalUnlockNotifier() : super(const LocalUnlockState());
  final storage = const FlutterSecureStorage();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pinEnabled = await storage.containsKey(key: _pinHashKey);
    final biometrics = prefs.getBool('biometrics_enabled') ?? false;
    state = LocalUnlockState(
      loading: false,
      pinEnabled: pinEnabled,
      biometricsEnabled: biometrics,
      unlocked: !pinEnabled && !biometrics,
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    final salt = await storage.read(key: _pinSaltKey);
    final expected = await storage.read(key: _pinHashKey);
    final valid =
        salt != null && expected != null && _hash(pin, salt) == expected;
    if (valid) {
      state = LocalUnlockState(
        loading: false,
        pinEnabled: true,
        biometricsEnabled: state.biometricsEnabled,
        unlocked: true,
      );
    }
    return valid;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!state.biometricsEnabled) return false;
    try {
      final valid = await LocalAuthentication().authenticate(
        localizedReason: 'Sblocca SpendWise',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (valid) {
        state = LocalUnlockState(
          loading: false,
          pinEnabled: state.pinEnabled,
          biometricsEnabled: true,
          unlocked: true,
        );
      }
      return valid;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4,}$').hasMatch(pin)) {
      throw ArgumentError('Il PIN deve contenere almeno 4 cifre');
    }
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );
    await storage.write(key: _pinSaltKey, value: salt);
    await storage.write(key: _pinHashKey, value: _hash(pin, salt));
    state = LocalUnlockState(
      loading: false,
      pinEnabled: true,
      biometricsEnabled: state.biometricsEnabled,
      unlocked: true,
    );
  }

  Future<void> disablePin(String currentPin) async {
    if (!await unlockWithPin(currentPin)) throw StateError('PIN errato');
    await storage.delete(key: _pinHashKey);
    await storage.delete(key: _pinSaltKey);
    await load();
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
