import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';

final avatarBuilderRevisionProvider = StateProvider<int>((ref) => 0);
final avatarBuilderConfigProvider =
    FutureProvider.autoDispose<AvatarBuilderConfig>((ref) {
      ref.watch(avatarBuilderRevisionProvider);
      return AvatarBuilderStorage.load();
    });

class AvatarBuilderStorage {
  static const key = 'profile_avatar_builder_config';

  static Future<AvatarBuilderConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return const AvatarBuilderConfig();
    try {
      return AvatarBuilderConfig.decode(raw);
    } catch (_) {
      return const AvatarBuilderConfig();
    }
  }

  static Future<void> save(AvatarBuilderConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, config.encode());
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
