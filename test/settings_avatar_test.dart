import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/app/theme.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/settings/settings_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Oceano è il tema predefinito e Gold viene memorizzato', () async {
    final settings = SettingsNotifier();
    await settings.load();
    expect(settings.state.colorTheme, 'ocean');
    expect(
      AppTheme.darkTheme(settings.state.colorTheme).colorScheme.primary,
      AppColorThemes.ocean.primary,
    );

    await settings.setColorTheme('gold');
    final restored = SettingsNotifier();
    await restored.load();
    expect(restored.state.colorTheme, 'gold');
    expect(
      AppTheme.darkTheme(restored.state.colorTheme).colorScheme.primary,
      AppColorThemes.gold.primary,
    );
  });

  test('tutti i temi premium generano una palette scura coerente', () {
    expect(AppColorThemes.values, hasLength(6));
    for (final palette in AppColorThemes.values) {
      final scheme = AppTheme.darkTheme(palette.id).colorScheme;
      expect(scheme.primary, palette.primary);
      expect(scheme.surface, palette.darkSurface);
      expect(scheme.surfaceContainer, palette.darkContainer);
      expect(scheme.outlineVariant, palette.border);
    }
  });

  testWidgets('disegna le versioni uomo e donna', (tester) async {
    for (final settings in const [
      SettingsState(avatarGender: 'male', avatarHair: 'crop'),
      SettingsState(
        avatarGender: 'female',
        avatarHair: 'bob',
        avatarOutfit: 'shirt',
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 160,
            height: 160,
            child: ModernAvatar(settings: settings),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
