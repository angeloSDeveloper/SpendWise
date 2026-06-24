import 'dart:convert';

class AvatarConfig {
  const AvatarConfig({
    required this.gender,
    required this.presetId,
    required this.initials,
    required this.backgroundColor,
    required this.primaryColor,
    required this.skinTone,
    required this.hairStyle,
    required this.hairColor,
    required this.beardStyle,
    required this.glasses,
    required this.outfit,
    required this.statusBadge,
  });

  final String gender;
  final String presetId;
  final String initials;
  final String backgroundColor;
  final String primaryColor;
  final String skinTone;
  final String hairStyle;
  final String hairColor;
  final String beardStyle;
  final bool glasses;
  final String outfit;
  final String statusBadge;

  AvatarConfig copyWith({
    String? gender,
    String? presetId,
    String? initials,
    String? backgroundColor,
    String? primaryColor,
    String? skinTone,
    String? hairStyle,
    String? hairColor,
    String? beardStyle,
    bool? glasses,
    String? outfit,
    String? statusBadge,
  }) => AvatarConfig(
    gender: gender ?? this.gender,
    presetId: presetId ?? this.presetId,
    initials: initials ?? this.initials,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    primaryColor: primaryColor ?? this.primaryColor,
    skinTone: skinTone ?? this.skinTone,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColor: hairColor ?? this.hairColor,
    beardStyle: beardStyle ?? this.beardStyle,
    glasses: glasses ?? this.glasses,
    outfit: outfit ?? this.outfit,
    statusBadge: statusBadge ?? this.statusBadge,
  );

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'presetId': presetId,
    'initials': initials,
    'backgroundColor': backgroundColor,
    'primaryColor': primaryColor,
    'skinTone': skinTone,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
    'beardStyle': beardStyle,
    'glasses': glasses,
    'outfit': outfit,
    'statusBadge': statusBadge,
  };

  factory AvatarConfig.fromJson(Map<String, dynamic> json) => AvatarConfig(
    gender: json['gender'] as String? ?? 'male',
    presetId: json['presetId'] as String? ?? 'male-navy',
    initials: json['initials'] as String? ?? '',
    backgroundColor: json['backgroundColor'] as String? ?? '#e8eaf0',
    primaryColor: json['primaryColor'] as String? ?? '#536dfe',
    skinTone: json['skinTone'] as String? ?? 'light',
    hairStyle: json['hairStyle'] as String? ?? 'short_01',
    hairColor: json['hairColor'] as String? ?? 'brown',
    beardStyle: json['beardStyle'] as String? ?? 'none',
    glasses: json['glasses'] as bool? ?? false,
    outfit: json['outfit'] as String? ?? 'shirt_01',
    statusBadge: json['statusBadge'] as String? ?? 'none',
  );

  String encode() => jsonEncode(toJson());

  factory AvatarConfig.decode(String value) =>
      AvatarConfig.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
