import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DashboardWidgetSize { square, wide }

class DashboardWidgetConfig {
  const DashboardWidgetConfig({
    required this.id,
    this.size = DashboardWidgetSize.square,
    this.visible = true,
  });

  final String id;
  final DashboardWidgetSize size;
  final bool visible;

  DashboardWidgetConfig copyWith({DashboardWidgetSize? size, bool? visible}) =>
      DashboardWidgetConfig(
        id: id,
        size: size ?? this.size,
        visible: visible ?? this.visible,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'size': size.name,
    'visible': visible,
  };

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) =>
      DashboardWidgetConfig(
        id: json['id'] as String,
        size: DashboardWidgetSize.values.firstWhere(
          (value) => value.name == json['size'],
          orElse: () => DashboardWidgetSize.square,
        ),
        visible: json['visible'] as bool? ?? true,
      );
}

const defaultDashboardWidgets = [
  DashboardWidgetConfig(id: 'quick', size: DashboardWidgetSize.wide),
  DashboardWidgetConfig(id: 'categories'),
  DashboardWidgetConfig(id: 'trend'),
  DashboardWidgetConfig(id: 'recent', size: DashboardWidgetSize.wide),
];

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, List<DashboardWidgetConfig>>(
      (ref) => DashboardLayoutNotifier()..load(),
    );

class DashboardLayoutNotifier
    extends StateNotifier<List<DashboardWidgetConfig>> {
  DashboardLayoutNotifier() : super(defaultDashboardWidgets);

  static const _storageKey = 'dashboard_widget_layout_v1';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final saved = decoded
          .cast<Map<String, dynamic>>()
          .map(DashboardWidgetConfig.fromJson)
          .where((item) => defaultDashboardWidgets.any((x) => x.id == item.id))
          .toList();
      for (final item in defaultDashboardWidgets) {
        if (!saved.any((x) => x.id == item.id)) saved.add(item);
      }
      state = saved;
    } catch (_) {
      state = defaultDashboardWidgets;
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final updated = [...state];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await _save();
  }

  Future<void> setVisible(String id, bool value) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(visible: value) else item,
    ];
    await _save();
  }

  Future<void> setSize(String id, DashboardWidgetSize value) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(size: value) else item,
    ];
    await _save();
  }

  Future<void> reset() async {
    state = defaultDashboardWidgets;
    await _save();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(state.map((item) => item.toJson()).toList()),
    );
  }
}
