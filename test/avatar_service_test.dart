import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_config.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_service.dart';

void main() {
  test('serializza e ripristina la configurazione JSON', () {
    const config = AvatarConfig(
      gender: 'female',
      presetId: 'female-teal',
      initials: 'AC',
      backgroundColor: '#e1effe',
      primaryColor: '#2563eb',
      skinTone: 'medium',
      hairStyle: 'short_01',
      hairColor: 'brown',
      beardStyle: 'short',
      glasses: true,
      outfit: 'shirt_01',
      statusBadge: 'online',
    );

    expect(AvatarConfig.decode(config.encode()).toJson(), config.toJson());
  });

  test('genera SVG inline con accessori e badge', () {
    final config = AvatarService.getDefaultAvatarConfig(
      initials: 'AC',
    ).copyWith(glasses: true, beardStyle: 'mustache', statusBadge: 'online');
    final svg = AvatarService.generateAvatarSvg(config);

    expect(svg, contains('<svg'));
    expect(svg, contains('stroke="#fff"'));
    expect(svg, contains('<rect x="54"'));
  });

  test('fallback iniziali e avatar automatico sono deterministici', () {
    final first = AvatarService.generateAvatarFromUserId('user-123', 'AC');
    final second = AvatarService.generateAvatarFromUserId('user-123', 'AC');
    final initials = first.copyWith(hairStyle: 'initials');

    expect(first.toJson(), second.toJson());
    expect(AvatarService.generateAvatarSvg(initials), contains('>AC</text>'));
  });
}
