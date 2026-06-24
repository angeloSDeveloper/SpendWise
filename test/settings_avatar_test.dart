import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/settings/settings_screen.dart';

void main() {
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
