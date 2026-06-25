import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_preview.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_screen.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_storage.dart';

void main() {
  test('la configurazione avatar mantiene tutti i valori nel JSON', () {
    const original = AvatarBuilderConfig(
      initials: 'SW',
      backgroundType: 'gradient',
      gradientStart: 0xFF7C3AED,
      gradientEnd: 0xFF2563EB,
      textColor: 0xFFF5E6D3,
      shape: AvatarShape.squircle,
      icon: AvatarIcon.crown,
      borderEnabled: true,
      borderColor: 0xFFFFFFFF,
      borderWidth: 7,
      size: AvatarSize.extraLarge,
    );

    final restored = AvatarBuilderConfig.decode(original.encode());

    expect(restored.initials, 'SW');
    expect(restored.backgroundType, 'gradient');
    expect(restored.gradientStart, 0xFF7C3AED);
    expect(restored.gradientEnd, 0xFF2563EB);
    expect(restored.textColor, 0xFFF5E6D3);
    expect(restored.shape, AvatarShape.squircle);
    expect(restored.icon, AvatarIcon.crown);
    expect(restored.borderEnabled, isTrue);
    expect(restored.borderWidth, 7);
    expect(restored.size, AvatarSize.extraLarge);
  });

  test('salva e ricarica la configurazione dalle preferenze locali', () async {
    SharedPreferences.setMockInitialValues({});
    const config = AvatarBuilderConfig(
      initials: 'AC',
      backgroundColor: 0xFF10B981,
      shape: AvatarShape.circle,
      size: AvatarSize.medium,
    );

    await AvatarBuilderStorage.save(config);
    final loaded = await AvatarBuilderStorage.load();

    expect(loaded.initials, 'AC');
    expect(loaded.backgroundColor, 0xFF10B981);
    expect(loaded.shape, AvatarShape.circle);
    expect(loaded.size, AvatarSize.medium);
  });

  testWidgets('la preview alterna iniziali e icona', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarBuilderPreview(
            config: AvatarBuilderConfig(initials: 'AC'),
          ),
        ),
      ),
    );

    expect(find.text('AC'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarBuilderPreview(
            config: AvatarBuilderConfig(icon: AvatarIcon.star),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('AC'), findsNothing);
  });

  testWidgets('su mobile la preview live resta fuori dall’area scorrevole', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AvatarBuilderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Anteprima live'), findsOneWidget);
    await tester.drag(
      find.text('Personalizza avatar').last,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anteprima live'), findsOneWidget);
  });
}
