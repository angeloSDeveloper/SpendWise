import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_config.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_service.dart';

const avatarPresets = <String, (String, String, String)>{
  'male-navy': ('Uomo · Navy', 'male', 'assets/avatars/male-navy.jpg'),
  'male-charcoal': (
    'Uomo · Charcoal',
    'male',
    'assets/avatars/male-charcoal.jpg',
  ),
  'female-teal': ('Donna · Teal', 'female', 'assets/avatars/female-teal.jpg'),
  'female-burgundy': (
    'Donna · Burgundy',
    'female',
    'assets/avatars/female-burgundy.jpg',
  ),
};

class AvatarVisual extends StatelessWidget {
  const AvatarVisual({
    required this.config,
    this.fit = BoxFit.cover,
    super.key,
  });

  final AvatarConfig config;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final preset = avatarPresets[config.presetId];
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipOval(
          child: preset == null
              ? SvgPicture.string(
                  AvatarService.generateAvatarSvg(config),
                  fit: BoxFit.contain,
                )
              : Image.asset(preset.$3, fit: fit),
        ),
        if (config.statusBadge != 'none')
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.statusBadge == 'online'
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8),
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
          ),
      ],
    );
  }
}
