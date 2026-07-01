import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/app/theme.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/settings/settings_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Gold è il tema predefinito e Oceano viene memorizzato', () async {
    final settings = SettingsNotifier();
    await settings.load();
    expect(settings.state.colorTheme, 'gold');
    expect(
      AppTheme.darkTheme(settings.state.colorTheme).colorScheme.primary,
      AppColorThemes.gold.primaryDark,
    );

    await settings.setColorTheme('ocean');
    final restored = SettingsNotifier();
    await restored.load();
    expect(restored.state.colorTheme, 'ocean');
    expect(
      AppTheme.darkTheme(restored.state.colorTheme).colorScheme.primary,
      AppColorThemes.ocean.primaryDark,
    );
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
