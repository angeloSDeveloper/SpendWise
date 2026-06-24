import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_config.dart';

class AvatarService {
  static const _storagePrefix = 'avatar_config_v2_';

  static AvatarConfig getDefaultAvatarConfig({String initials = ''}) =>
      AvatarConfig(
        gender: 'male',
        presetId: 'male-navy',
        initials: _sanitizeInitials(initials),
        backgroundColor: '#e7eaf2',
        primaryColor: '#536dfe',
        skinTone: 'light',
        hairStyle: 'short_01',
        hairColor: 'brown',
        beardStyle: 'none',
        glasses: false,
        outfit: 'shirt_01',
        statusBadge: 'none',
      );

  static AvatarConfig generateAvatarFromUserId(String userId, String initials) {
    final hash = userId.codeUnits.fold<int>(17, (value, unit) {
      return (value * 31 + unit) & 0x7fffffff;
    });
    const backgrounds = ['#e8eaf6', '#dff4ef', '#f7e7ef', '#fff0d5', '#e1effe'];
    const primary = ['#536dfe', '#0f9d86', '#d94f86', '#ca7a19', '#7656c8'];
    const hair = ['short_01', 'medium_01', 'long_01'];
    const colors = ['black', 'brown', 'blonde', 'auburn'];
    const outfits = ['shirt_01', 'sweater_01'];
    return getDefaultAvatarConfig(initials: initials).copyWith(
      backgroundColor: backgrounds[hash % backgrounds.length],
      primaryColor: primary[(hash ~/ 3) % primary.length],
      presetId: const [
        'male-navy',
        'female-teal',
        'male-charcoal',
        'female-burgundy',
      ][hash % 4],
      hairStyle: hair[(hash ~/ 7) % hair.length],
      hairColor: colors[(hash ~/ 11) % colors.length],
      outfit: outfits[(hash ~/ 13) % outfits.length],
    );
  }

  static Future<void> saveAvatarConfig(
    String userId,
    AvatarConfig config,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_storagePrefix$userId', config.encode());
  }

  static Future<AvatarConfig> loadAvatarConfig(
    String userId, {
    String initials = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_storagePrefix$userId');
    if (raw == null) return generateAvatarFromUserId(userId, initials);
    try {
      return AvatarConfig.decode(raw);
    } catch (_) {
      return generateAvatarFromUserId(userId, initials);
    }
  }

  static Future<void> resetAvatarConfig(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_storagePrefix$userId');
  }

  static String generateAvatarSvg(AvatarConfig config) {
    final initials = _sanitizeInitials(config.initials);
    final skin = _skinColors[config.skinTone] ?? _skinColors['light']!;
    final hair = _hairColors[config.hairColor] ?? _hairColors['brown']!;
    final background = _safeHex(config.backgroundColor, '#e7eaf2');
    final primary = _safeHex(config.primaryColor, '#536dfe');
    final fallback = config.hairStyle == 'initials';
    final female = config.gender == 'female';

    if (fallback) {
      final content = initials.isEmpty
          ? '<path d="M80 74a25 25 0 1 0 0-50 25 25 0 0 0 0 50Zm-42 58c4-28 21-42 42-42s38 14 42 42" fill="none" stroke="$primary" stroke-width="9" stroke-linecap="round"/>'
          : '<text x="80" y="94" text-anchor="middle" font-family="Inter,Arial,sans-serif" font-size="48" font-weight="700" fill="$primary">${htmlEscape.convert(initials)}</text>';
      return _svgShell(background, '$content${_badge(config.statusBadge)}');
    }

    final hairBack = switch (config.hairStyle) {
      'medium_01' =>
        '<path d="M48 72c-8-42 12-58 32-58 29 0 42 25 34 70l-4 36H49l-3-33c-1-5 0-10 2-15Z" fill="$hair" stroke="#20222a" stroke-width="3"/>',
      'long_01' =>
        '<path d="M45 70c-6-39 13-57 35-57 30 0 44 24 37 70 9 23 0 43-15 50H57c-17-9-22-33-12-63Z" fill="$hair" stroke="#20222a" stroke-width="3"/>',
      _ =>
        '<path d="M48 61c-1-32 14-47 34-47 25 0 38 17 32 49L99 48 72 35 53 63Z" fill="$hair" stroke="#20222a" stroke-width="3"/>',
    };
    final hairFront =
        '<path d="M49 62c0-28 14-43 33-44 21 0 35 16 33 44-12-6-20-16-25-26-9 14-22 23-41 26Z" fill="$hair" stroke="#20222a" stroke-width="3" stroke-linejoin="round"/>';
    final beard = switch (config.beardStyle) {
      'short' =>
        '<path d="M58 90c7 17 16 24 23 24 8 0 17-7 23-24-6 10-14 14-23 14s-17-4-23-14Z" fill="${_darken(hair)}" opacity=".82"/>',
      'mustache' =>
        '<path d="M68 91c5-7 10-6 13-1 4-5 9-6 14 1-5 7-10 7-14 3-4 4-9 4-13-3Z" fill="${_darken(hair)}"/>',
      _ => '',
    };
    final glasses = config.glasses
        ? '<g fill="none" stroke="#25272f" stroke-width="3"><rect x="54" y="67" width="23" height="17" rx="7"/><rect x="85" y="67" width="23" height="17" rx="7"/><path d="M77 74h8"/></g>'
        : '';
    final outfit = config.outfit == 'sweater_01'
        ? '<path d="M27 160c4-31 22-45 42-47h22c21 3 39 17 43 47Z" fill="$primary" stroke="#20222a" stroke-width="3"/><path d="M66 115c2 12 27 12 29 0" fill="none" stroke="#20222a" stroke-width="3"/>'
        : '<path d="M27 160c4-31 22-45 42-47h22c21 3 39 17 43 47Z" fill="$primary" stroke="#20222a" stroke-width="3"/><path d="m67 114 13 17 14-17" fill="#fff" stroke="#20222a" stroke-width="3"/>';
    final facePath = female
        ? 'M52 53c4-24 52-24 57 1l-3 31c-3 20-15 31-26 31S57 105 53 85Z'
        : 'M51 53c3-23 55-24 59 1l-3 30c-2 18-14 31-27 32-13-1-25-14-27-32Z';
    final brows = female
        ? '<path d="M62 69q8-4 15 0M87 69q8-4 15 0" fill="none" stroke="#20222a" stroke-width="2.4" stroke-linecap="round"/>'
        : '<path d="M61 68q9-5 17 0M86 68q9-5 17 0" fill="none" stroke="#20222a" stroke-width="3.4" stroke-linecap="round"/>';

    final body =
        '''
$hairBack
$outfit
<path d="M69 104v18h23v-18" fill="$skin" stroke="#20222a" stroke-width="3"/>
<ellipse cx="49" cy="76" rx="8" ry="11" fill="$skin" stroke="#20222a" stroke-width="3"/>
<ellipse cx="112" cy="76" rx="8" ry="11" fill="$skin" stroke="#20222a" stroke-width="3"/>
<path d="$facePath" fill="$skin" stroke="#20222a" stroke-width="3"/>
$hairFront
$brows
<circle cx="70" cy="77" r="2.7" fill="#20222a"/><circle cx="94" cy="77" r="2.7" fill="#20222a"/>
<path d="M82 78l-3 11 6 1" fill="none" stroke="#20222a" stroke-width="2.4" stroke-linecap="round"/>
<path d="M70 97q11 10 23 0" fill="none" stroke="#20222a" stroke-width="3" stroke-linecap="round"/>
<ellipse cx="64" cy="88" rx="7" ry="3.5" fill="#ed8290" opacity=".28"/><ellipse cx="99" cy="88" rx="7" ry="3.5" fill="#ed8290" opacity=".28"/>
$beard$glasses${_badge(config.statusBadge)}
''';
    return _svgShell(background, body);
  }

  static String _svgShell(String background, String body) =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" role="img">
  <rect width="160" height="160" rx="80" fill="$background"/>
  $body
</svg>
''';

  static String _badge(String status) => switch (status) {
    'online' =>
      '<circle cx="136" cy="136" r="13" fill="#22c55e" stroke="#fff" stroke-width="5"/>',
    'offline' =>
      '<circle cx="136" cy="136" r="13" fill="#94a3b8" stroke="#fff" stroke-width="5"/>',
    _ => '',
  };

  static String _safeHex(String value, String fallback) =>
      RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value) ? value : fallback;

  static String _sanitizeInitials(String value) {
    final cleaned = value.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-ZÀ-Ü0-9]'),
      '',
    );
    return cleaned.length <= 2 ? cleaned : cleaned.substring(0, 2);
  }

  static String _darken(String hex) {
    final value = int.parse(hex.substring(1), radix: 16);
    final r = ((value >> 16) & 0xff) * .7;
    final g = ((value >> 8) & 0xff) * .7;
    final b = (value & 0xff) * .7;
    return '#${r.round().toRadixString(16).padLeft(2, '0')}${g.round().toRadixString(16).padLeft(2, '0')}${b.round().toRadixString(16).padLeft(2, '0')}';
  }

  static const _skinColors = {
    'porcelain': '#ffe4d1',
    'light': '#f4c7a1',
    'medium': '#d99b6c',
    'tan': '#b87348',
    'deep': '#75442f',
  };
  static const _hairColors = {
    'black': '#242126',
    'brown': '#55372c',
    'blonde': '#d7ad62',
    'auburn': '#934c37',
    'silver': '#a9adb8',
  };
}
