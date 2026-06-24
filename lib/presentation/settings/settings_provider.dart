import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appModules = {'daily', 'subscriptions', 'installments', 'vehicle'};

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.avatarData,
    this.avatarGender = 'male',
    this.avatarFace = 'smile',
    this.avatarHair = 'bob',
    this.avatarColor = 0xFFFFDBB4,
    this.avatarHairColor = 0xFF4A2C24,
    this.avatarClothes = 0xFF536DFE,
    this.avatarBackground = 0xFFD98ACB,
    this.avatarOutfit = 'turtleneck',
    this.biometricsEnabled = false,
    this.visibleModules = appModules,
    this.notificationsEnabled = false,
    this.notificationDaysBefore = 3,
  });
  final ThemeMode themeMode;
  final String? avatarData;
  final String avatarGender;
  final String avatarFace, avatarHair, avatarOutfit;
  final int avatarColor, avatarHairColor, avatarClothes, avatarBackground;
  final bool biometricsEnabled, notificationsEnabled;
  final Set<String> visibleModules;
  final int notificationDaysBefore;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? avatarData,
    bool clearAvatar = false,
    String? avatarGender,
    String? avatarFace,
    String? avatarHair,
    int? avatarColor,
    int? avatarHairColor,
    int? avatarClothes,
    int? avatarBackground,
    String? avatarOutfit,
    bool? biometricsEnabled,
    Set<String>? visibleModules,
    bool? notificationsEnabled,
    int? notificationDaysBefore,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    avatarData: clearAvatar ? null : avatarData ?? this.avatarData,
    avatarGender: avatarGender ?? this.avatarGender,
    avatarFace: avatarFace ?? this.avatarFace,
    avatarHair: avatarHair ?? this.avatarHair,
    avatarColor: avatarColor ?? this.avatarColor,
    avatarHairColor: avatarHairColor ?? this.avatarHairColor,
    avatarClothes: avatarClothes ?? this.avatarClothes,
    avatarBackground: avatarBackground ?? this.avatarBackground,
    avatarOutfit: avatarOutfit ?? this.avatarOutfit,
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
      avatarGender: prefs.getString('avatar_gender') ?? 'male',
      avatarFace: _normalizeFace(prefs.getString('avatar_face')),
      avatarHair: _normalizeHair(prefs.getString('avatar_hair')),
      avatarColor: prefs.getInt('avatar_color') ?? 0xFFFFDBB4,
      avatarHairColor: prefs.getInt('avatar_hair_color') ?? 0xFF4A2C24,
      avatarClothes: prefs.getInt('avatar_clothes') ?? 0xFF536DFE,
      avatarBackground: prefs.getInt('avatar_background') ?? 0xFFD98ACB,
      avatarOutfit: prefs.getString('avatar_outfit') ?? 'turtleneck',
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

  Future<void> setAvatarGender(String value) async {
    final female = value == 'female';
    state = state.copyWith(
      avatarGender: value,
      avatarFace: 'smile',
      avatarHair: female ? 'bob' : 'crop',
      avatarColor: female ? 0xFFFFC99D : 0xFFE6A06C,
      avatarHairColor: female ? 0xFF4A2C24 : 0xFF231815,
      avatarClothes: female ? 0xFFE84C88 : 0xFF536DFE,
      avatarBackground: female ? 0xFFF0B7D2 : 0xFF9FC4F4,
      avatarOutfit: female ? 'shirt' : 'turtleneck',
      clearAvatar: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar_data');
    await prefs.setString('avatar_gender', value);
  }

  Future<void> setAvatarStyle({
    String? face,
    String? hair,
    int? skin,
    int? hairColor,
    int? clothes,
    int? background,
    String? outfit,
  }) async {
    state = state.copyWith(
      avatarFace: face,
      avatarHair: hair,
      avatarColor: skin,
      avatarHairColor: hairColor,
      avatarClothes: clothes,
      avatarBackground: background,
      avatarOutfit: outfit,
      clearAvatar: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatar_data');
    if (face != null) await prefs.setString('avatar_face', face);
    if (hair != null) await prefs.setString('avatar_hair', hair);
    if (skin != null) await prefs.setInt('avatar_color', skin);
    if (hairColor != null) {
      await prefs.setInt('avatar_hair_color', hairColor);
    }
    if (clothes != null) await prefs.setInt('avatar_clothes', clothes);
    if (background != null) {
      await prefs.setInt('avatar_background', background);
    }
    if (outfit != null) await prefs.setString('avatar_outfit', outfit);
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

String _normalizeFace(String? value) => switch (value) {
  'calm' || 'wink' || 'glasses' || 'freckles' => value!,
  _ => 'smile',
};

String _normalizeHair(String? value) => switch (value) {
  'crop' || 'wave' || 'bob' => value!,
  'bald' || 'short' => 'crop',
  'long' => 'wave',
  _ => 'bob',
};
