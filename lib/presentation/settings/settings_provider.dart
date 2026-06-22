import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.avatarData,
    this.biometricsEnabled = false,
  });
  final ThemeMode themeMode;
  final String? avatarData;
  final bool biometricsEnabled;
  SettingsState copyWith({
    ThemeMode? themeMode,
    String? avatarData,
    bool? biometricsEnabled,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    avatarData: avatarData ?? this.avatarData,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
  );
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier()..load(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (x) => x.name == prefs.getString('theme_mode'),
        orElse: () => ThemeMode.system,
      ),
      avatarData: prefs.getString('avatar_data'),
      biometricsEnabled: prefs.getBool('biometrics_enabled') ?? false,
    );
  }

  Future<void> setTheme(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    (await SharedPreferences.getInstance()).setString('theme_mode', value.name);
  }

  Future<void> setAvatar(String value) async {
    state = state.copyWith(avatarData: value);
    (await SharedPreferences.getInstance()).setString('avatar_data', value);
  }

  Future<void> setBiometrics(bool value) async {
    state = state.copyWith(biometricsEnabled: value);
    (await SharedPreferences.getInstance()).setBool(
      'biometrics_enabled',
      value,
    );
  }
}
