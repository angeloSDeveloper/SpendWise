import 'dart:convert';

enum AvatarShape { rounded, circle, squircle, square }

enum AvatarSize { small, medium, large, extraLarge }

enum AvatarIcon { none, person, star, heart, bolt, crown, diamond }

class AvatarBuilderConfig {
  const AvatarBuilderConfig({
    this.initials = 'AC',
    this.backgroundType = 'solid',
    this.backgroundColor = 0xFF2563EB,
    this.gradientStart = 0xFF7C3AED,
    this.gradientEnd = 0xFF2563EB,
    this.textColor = 0xFFFFFFFF,
    this.shape = AvatarShape.rounded,
    this.icon = AvatarIcon.none,
    this.borderEnabled = false,
    this.borderColor = 0xFFFFFFFF,
    this.borderWidth = 4,
    this.size = AvatarSize.large,
  });

  final String initials;
  final String backgroundType;
  final int backgroundColor;
  final int gradientStart;
  final int gradientEnd;
  final int textColor;
  final AvatarShape shape;
  final AvatarIcon icon;
  final bool borderEnabled;
  final int borderColor;
  final double borderWidth;
  final AvatarSize size;

  AvatarBuilderConfig copyWith({
    String? initials,
    String? backgroundType,
    int? backgroundColor,
    int? gradientStart,
    int? gradientEnd,
    int? textColor,
    AvatarShape? shape,
    AvatarIcon? icon,
    bool? borderEnabled,
    int? borderColor,
    double? borderWidth,
    AvatarSize? size,
  }) => AvatarBuilderConfig(
    initials: initials ?? this.initials,
    backgroundType: backgroundType ?? this.backgroundType,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    gradientStart: gradientStart ?? this.gradientStart,
    gradientEnd: gradientEnd ?? this.gradientEnd,
    textColor: textColor ?? this.textColor,
    shape: shape ?? this.shape,
    icon: icon ?? this.icon,
    borderEnabled: borderEnabled ?? this.borderEnabled,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    size: size ?? this.size,
  );

  Map<String, dynamic> toJson() => {
    'initials': initials,
    'backgroundType': backgroundType,
    'backgroundColor': _hex(backgroundColor),
    'backgroundGradient':
        'linear-gradient(135deg, ${_hex(gradientStart)}, ${_hex(gradientEnd)})',
    'gradientStart': _hex(gradientStart),
    'gradientEnd': _hex(gradientEnd),
    'textColor': _hex(textColor),
    'shape': shape.name,
    'icon': icon == AvatarIcon.none ? null : icon.name,
    'borderEnabled': borderEnabled,
    'borderColor': _hex(borderColor),
    'borderWidth': borderWidth,
    'size': size.name,
  };

  factory AvatarBuilderConfig.fromJson(Map<String, dynamic> json) =>
      AvatarBuilderConfig(
        initials: json['initials'] as String? ?? 'AC',
        backgroundType: json['backgroundType'] as String? ?? 'solid',
        backgroundColor: _parseColor(
          json['backgroundColor'] as String?,
          0xFF2563EB,
        ),
        gradientStart: _parseColor(
          json['gradientStart'] as String?,
          0xFF7C3AED,
        ),
        gradientEnd: _parseColor(json['gradientEnd'] as String?, 0xFF2563EB),
        textColor: _parseColor(json['textColor'] as String?, 0xFFFFFFFF),
        shape: AvatarShape.values.firstWhere(
          (value) => value.name == json['shape'],
          orElse: () => AvatarShape.rounded,
        ),
        icon: AvatarIcon.values.firstWhere(
          (value) => value.name == json['icon'],
          orElse: () => AvatarIcon.none,
        ),
        borderEnabled: json['borderEnabled'] as bool? ?? false,
        borderColor: _parseColor(json['borderColor'] as String?, 0xFFFFFFFF),
        borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 4,
        size: AvatarSize.values.firstWhere(
          (value) => value.name == json['size'],
          orElse: () => AvatarSize.large,
        ),
      );

  String encode() => jsonEncode(toJson());

  factory AvatarBuilderConfig.decode(String value) =>
      AvatarBuilderConfig.fromJson(jsonDecode(value) as Map<String, dynamic>);

  static String _hex(int value) =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static int _parseColor(String? value, int fallback) {
    if (value == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return fallback;
    }
    return 0xFF000000 | int.parse(value.substring(1), radix: 16);
  }
}

const avatarBuilderPresets = <String, (String, AvatarBuilderConfig)>{
  'blue': (
    'Blu professionale',
    AvatarBuilderConfig(
      backgroundColor: 0xFF2563EB,
      textColor: 0xFFFFFFFF,
      shape: AvatarShape.rounded,
    ),
  ),
  'black': (
    'Nero minimal',
    AvatarBuilderConfig(
      backgroundColor: 0xFF111827,
      textColor: 0xFFFFFFFF,
      shape: AvatarShape.rounded,
    ),
  ),
  'purple': (
    'Gradiente viola',
    AvatarBuilderConfig(
      backgroundType: 'gradient',
      gradientStart: 0xFF7C3AED,
      gradientEnd: 0xFF2563EB,
      textColor: 0xFFFFFFFF,
      shape: AvatarShape.rounded,
      borderEnabled: true,
      borderColor: 0xFFFFFFFF,
      borderWidth: 3,
    ),
  ),
  'green': (
    'Verde moderno',
    AvatarBuilderConfig(
      backgroundColor: 0xFF10B981,
      textColor: 0xFFFFFFFF,
      shape: AvatarShape.rounded,
    ),
  ),
  'red': (
    'Rosso elegante',
    AvatarBuilderConfig(
      backgroundColor: 0xFFDC2626,
      textColor: 0xFFFFFFFF,
      shape: AvatarShape.rounded,
    ),
  ),
};
