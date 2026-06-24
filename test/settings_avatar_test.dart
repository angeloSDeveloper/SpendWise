import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/settings/settings_screen.dart';

void main() {
  testWidgets('disegna le 30 combinazioni base dell’avatar', (tester) async {
    const faces = ['smile', 'calm', 'wink', 'glasses', 'freckles'];
    const hairs = ['crop', 'wave', 'bob'];
    const outfits = ['turtleneck', 'shirt'];
    var combinations = 0;

    for (final face in faces) {
      for (final hair in hairs) {
        for (final outfit in outfits) {
          combinations++;
          await tester.pumpWidget(
            MaterialApp(
              home: SizedBox(
                width: 160,
                height: 160,
                child: ModernAvatar(
                  settings: SettingsState(
                    avatarFace: face,
                    avatarHair: hair,
                    avatarOutfit: outfit,
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    }

    expect(combinations, 30);
  });
}
