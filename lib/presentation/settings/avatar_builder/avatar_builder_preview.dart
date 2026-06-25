import 'package:flutter/material.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';

class AvatarBuilderPreview extends StatelessWidget {
  const AvatarBuilderPreview({
    required this.config,
    this.overrideSize,
    super.key,
  });

  final AvatarBuilderConfig config;
  final double? overrideSize;

  static IconData iconData(AvatarIcon icon) => switch (icon) {
    AvatarIcon.person => Icons.person_rounded,
    AvatarIcon.star => Icons.star_rounded,
    AvatarIcon.heart => Icons.favorite_rounded,
    AvatarIcon.bolt => Icons.bolt_rounded,
    AvatarIcon.crown => Icons.workspace_premium_rounded,
    AvatarIcon.diamond => Icons.diamond_rounded,
    AvatarIcon.none => Icons.person_rounded,
  };

  double get dimension =>
      overrideSize ??
      switch (config.size) {
        AvatarSize.small => 96,
        AvatarSize.medium => 132,
        AvatarSize.large => 184,
        AvatarSize.extraLarge => 236,
      };

  BorderRadius get radius => switch (config.shape) {
    AvatarShape.circle => BorderRadius.circular(dimension / 2),
    AvatarShape.rounded => BorderRadius.circular(dimension * .2),
    AvatarShape.squircle => BorderRadius.circular(dimension * .34),
    AvatarShape.square => BorderRadius.circular(4),
  };

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    width: dimension,
    height: dimension,
    decoration: BoxDecoration(
      color: config.backgroundType == 'solid'
          ? Color(config.backgroundColor)
          : null,
      gradient: config.backgroundType == 'gradient'
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(config.gradientStart), Color(config.gradientEnd)],
            )
          : null,
      borderRadius: radius,
      border: config.borderEnabled
          ? Border.all(
              color: Color(config.borderColor),
              width: config.borderWidth,
            )
          : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: config.icon == AvatarIcon.none
          ? Text(
              config.initials.trim().isEmpty
                  ? '•'
                  : config.initials.trim().toUpperCase(),
              key: ValueKey('text-${config.initials}-${config.textColor}'),
              style: TextStyle(
                color: Color(config.textColor),
                fontSize: dimension * .33,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            )
          : Icon(
              iconData(config.icon),
              key: ValueKey(config.icon),
              color: Color(config.textColor),
              size: dimension * .42,
            ),
    ),
  );
}
