import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appModules = {'daily', 'subscriptions', 'installments', 'vehicle'};

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.avatarData,
    this.avatarFace = '🙂',
    this.avatarHair = 'short',
    this.avatarColor = 0xFF8C6A4F,
    this.avatarClothes = 0xFF536DFE,
    this.biometricsEnabled = false,
    this.visibleModules = appModules,
    this.notificationsEnabled = false,
    this.notificationDaysBefore = 3,
  });
  final ThemeMode themeMode;
  final String? avatarData;
  final String avatarFace, avatarHair;
  final int avatarColor, avatarClothes;
  final bool biometricsEnabled, notificationsEnabled;
  final Set<String> visibleModules;
  final int notificationDaysBefore;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? avatarData,
    bool clearAvatar = false,
    String? avatarFace,
    String? avatarHair,
    int? avatarColor,
    int? avatarClothes,
    bool? biometricsEnabled,
    Set<String>? visibleModules,
    bool? notificationsEnabled,
    int? notificationDaysBefore,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    avatarData: clearAvatar ? null : avatarData ?? this.avatarData,
    avatarFace: avatarFace ?? this.avatarFace,
    avatarHair: avatarHair ?? this.avatarHair,
    avatarColor: avatarColor ?? this.avatarColor,
    avatarClothes: avatarClothes ?? this.avatarClothes,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    visibleModules: visibleModules ?? this.visibleModules,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
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
      avatarFace: prefs.getString('avatar_face') ?? '🙂',
      avatarHair: prefs.getString('avatar_hair') ?? 'short',
      avatarColor: prefs.getInt('avatar_color') ?? 0xFF8C6A4F,
      avatarClothes: prefs.getInt('avatar_clothes') ?? 0xFF536DFE,
      biometricsEnabled: prefs.getBool('biometrics_enabled') ?? false,
      visibleModules:
          prefs.getStringList('visible_modules')?.toSet() ?? appModules,
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? false,
      notificationDaysBefore: prefs.getInt('notification_days_before') ?? 3,
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

  Future<void> clearAvatar() async {
    state = state.copyWith(clearAvatar: true);
    (await SharedPreferences.getInstance()).remove('avatar_data');
  }

  Future<void> setAvatarStyle({
    String? face,
    String? hair,
    int? skin,
    int? clothes,
  }) async {
    state = state.copyWith(
      avatarFace: face,
      avatarHair: hair,
      avatarColor: skin,
      avatarClothes: clothes,
      clearAvatar: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar_data');
    if (face != null) await prefs.setString('avatar_face', face);
    if (hair != null) await prefs.setString('avatar_hair', hair);
    if (skin != null) await prefs.setInt('avatar_color', skin);
    if (clothes != null) await prefs.setInt('avatar_clothes', clothes);
  }

  Future<void> setBiometrics(bool value) async {
    state = state.copyWith(biometricsEnabled: value);
    (await SharedPreferences.getInstance()).setBool(
      'biometrics_enabled',
      value,
    );
  }

  Future<void> setModule(String module, bool visible) async {
    final modules = {...state.visibleModules};
    visible ? modules.add(module) : modules.remove(module);
    state = state.copyWith(visibleModules: modules);
    (await SharedPreferences.getInstance()).setStringList(
      'visible_modules',
      modules.toList(),
    );
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    (await SharedPreferences.getInstance()).setBool(
      'notifications_enabled',
      value,
    );
  }

  Future<void> setNotificationDays(int value) async {
    state = state.copyWith(notificationDaysBefore: value);
    (await SharedPreferences.getInstance()).setInt(
      'notification_days_before',
      value,
    );
  }
}
