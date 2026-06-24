import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> pickAvatar(WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 65,
    );
    if (file == null) return;
    final value =
        'data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(await file.readAsBytes())}';
    await ref.read(settingsProvider.notifier).setAvatar(value);
  }

  Future<void> requestNotifications(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    await ref.read(settingsProvider.notifier).setNotifications(value);
    if (value && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Promemoria attivati. Il browser o il telefono potrà chiedere il consenso alle notifiche.',
          ),
        ),
      );
    }
  }

  Future<void> toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (!value) {
      await ref.read(settingsProvider.notifier).setBiometrics(false);
      return;
    }
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) throw StateError('not-supported');
      final verified = await auth.authenticate(
        localizedReason:
            'Conferma per attivare l’accesso biometrico a SpendWise',
      );
      if (verified) {
        await ref.read(settingsProvider.notifier).setBiometrics(true);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Face ID o biometria non disponibili su questo dispositivo/browser.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final avatar = settings.avatarData;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 164,
                  height: 164,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: avatar == null
                        ? ModernAvatar(settings: settings)
                        : Image.memory(
                            base64Decode(avatar.split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                ModernAvatar(settings: settings),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => pickAvatar(ref),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Usa foto'),
                    ),
                    if (avatar != null)
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            ref.read(settingsProvider.notifier).clearAvatar(),
                        icon: const Icon(Icons.palette_outlined),
                        label: const Text('Usa avatar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ExpansionTile(
            leading: const Icon(Icons.face_retouching_natural),
            title: const Text('Personalizza avatar'),
            subtitle: const Text('30 combinazioni base, leggere e moderne'),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Espressione',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final face in const {
                    'smile': ('Sorriso', Icons.sentiment_satisfied_alt),
                    'calm': ('Calmo', Icons.sentiment_neutral),
                    'wink': ('Occhiolino', Icons.visibility),
                    'glasses': ('Occhiali', Icons.visibility_outlined),
                    'freckles': ('Lentiggini', Icons.face),
                  }.entries)
                    ChoiceChip(
                      avatar: Icon(face.value.$2, size: 18),
                      label: Text(face.value.$1),
                      selected: settings.avatarFace == face.key,
                      onSelected: (_) => ref
                          .read(settingsProvider.notifier)
                          .setAvatarStyle(face: face.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Capelli',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'crop', label: Text('Corti')),
                  ButtonSegment(value: 'wave', label: Text('Mossi')),
                  ButtonSegment(value: 'bob', label: Text('Caschetto')),
                ],
                selected: {settings.avatarHair},
                onSelectionChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(hair: value.first),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stile vestiti',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'turtleneck', label: Text('Dolcevita')),
                  ButtonSegment(value: 'shirt', label: Text('Maglia')),
                ],
                selected: {settings.avatarOutfit},
                onSelectionChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(outfit: value.first),
              ),
              const SizedBox(height: 16),
              _ColorSetting(
                label: 'Carnagione',
                selected: settings.avatarColor,
                colors: const [
                  0xFFFFE0C2,
                  0xFFFFC99D,
                  0xFFE6A06C,
                  0xFFB96F47,
                  0xFF75422F,
                ],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(skin: value),
              ),
              const SizedBox(height: 12),
              _ColorSetting(
                label: 'Capelli',
                selected: settings.avatarHairColor,
                colors: const [
                  0xFF231815,
                  0xFF4A2C24,
                  0xFF8A5A3B,
                  0xFFE1B45F,
                  0xFFD66B9B,
                ],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(hairColor: value),
              ),
              const SizedBox(height: 12),
              _ColorSetting(
                label: 'Vestiti',
                selected: settings.avatarClothes,
                colors: const [
                  0xFF2E3038,
                  0xFF536DFE,
                  0xFFE84C88,
                  0xFF00A884,
                  0xFFFF9800,
                ],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(clothes: value),
              ),
              const SizedBox(height: 12),
              _ColorSetting(
                label: 'Sfondo',
                selected: settings.avatarBackground,
                colors: const [
                  0xFFD98ACB,
                  0xFF8FB9F4,
                  0xFF8FD9C4,
                  0xFFF4C982,
                  0xFFB6A4ED,
                ],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(background: value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Aspetto', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Chiaro'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Scuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (v) =>
                ref.read(settingsProvider.notifier).setTheme(v.first),
          ),
          const SizedBox(height: 20),
          Text(
            'Sezioni visibili',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'La dashboard, le statistiche e la navigazione seguiranno queste scelte.',
          ),
          for (final module in const {
            'daily': ('Spese', Icons.receipt_long),
            'subscriptions': ('Abbonamenti', Icons.autorenew),
            'installments': ('Rate', Icons.credit_card),
            'vehicle': ('Veicolo', Icons.directions_car),
          }.entries)
            SwitchListTile(
              secondary: Icon(module.value.$2),
              title: Text(module.value.$1),
              value: settings.visibleModules.contains(module.key),
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .setModule(module.key, value),
            ),
          const SizedBox(height: 20),
          Text('Notifiche', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Promemoria scadenze'),
            subtitle: const Text('Abbonamenti e rate su web e telefono'),
            value: settings.notificationsEnabled,
            onChanged: (value) => requestNotifications(context, ref, value),
          ),
          if (settings.notificationsEnabled)
            DropdownButtonFormField<int>(
              initialValue: settings.notificationDaysBefore,
              decoration: const InputDecoration(
                labelText: 'Avvisami prima della scadenza',
              ),
              items: const [1, 2, 3, 5, 7, 14, 30]
                  .map(
                    (days) => DropdownMenuItem(
                      value: days,
                      child: Text('$days giorni prima'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .setNotificationDays(value!),
            ),
          const SizedBox(height: 20),
          Text('Sicurezza', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            secondary: const Icon(Icons.face),
            title: const Text('Face ID / biometria'),
            subtitle: const Text(
              'Disponibile su dispositivi compatibili; sul web dipende dal browser.',
            ),
            value: settings.biometricsEnabled,
            onChanged: (value) => toggleBiometrics(context, ref, value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Esci'),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class ModernAvatar extends StatelessWidget {
  const ModernAvatar({required this.settings, super.key});
  final SettingsState settings;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AvatarPainter(settings),
    child: const SizedBox.expand(),
  );
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.settings);
  final SettingsState settings;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final skin = Color(settings.avatarColor);
    final hair = Color(settings.avatarHairColor);
    final clothes = Color(settings.avatarClothes);
    const outline = Color(0xFF25242A);
    final line = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 160, 160),
      Paint()..color = Color(settings.avatarBackground),
    );

    final hairBack = switch (settings.avatarHair) {
      'wave' =>
        Path()
          ..moveTo(43, 76)
          ..cubicTo(34, 38, 52, 18, 80, 18)
          ..cubicTo(117, 17, 131, 47, 120, 91)
          ..cubicTo(125, 111, 113, 122, 104, 123)
          ..lineTo(54, 123)
          ..cubicTo(38, 119, 34, 99, 43, 76)
          ..close(),
      'bob' =>
        Path()
          ..moveTo(41, 74)
          ..cubicTo(36, 38, 53, 20, 80, 19)
          ..cubicTo(111, 18, 126, 41, 121, 78)
          ..lineTo(116, 113)
          ..cubicTo(102, 122, 58, 122, 44, 111)
          ..close(),
      _ =>
        Path()
          ..moveTo(45, 62)
          ..cubicTo(44, 32, 62, 20, 83, 20)
          ..cubicTo(109, 21, 121, 38, 115, 64)
          ..close(),
    };
    canvas.drawPath(hairBack, Paint()..color = hair);
    canvas.drawPath(hairBack, line);

    final shoulders = Path()
      ..moveTo(25, 160)
      ..cubicTo(29, 129, 49, 119, 68, 116)
      ..lineTo(92, 116)
      ..cubicTo(112, 120, 132, 130, 136, 160)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = clothes);
    canvas.drawPath(shoulders, line);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 102, 24, 27),
        const Radius.circular(8),
      ),
      Paint()..color = skin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 102, 24, 27),
        const Radius.circular(8),
      ),
      line,
    );
    canvas.drawOval(const Rect.fromLTWH(42, 66, 15, 22), Paint()..color = skin);
    canvas.drawOval(
      const Rect.fromLTWH(103, 66, 15, 22),
      Paint()..color = skin,
    );

    final face = Path()
      ..moveTo(52, 51)
      ..cubicTo(56, 30, 103, 29, 109, 54)
      ..lineTo(106, 83)
      ..cubicTo(102, 105, 91, 115, 80, 116)
      ..cubicTo(67, 115, 56, 104, 52, 83)
      ..close();
    canvas.drawPath(face, Paint()..color = skin);
    canvas.drawPath(face, line);

    final hairFront = Path()
      ..moveTo(48, 60)
      ..cubicTo(46, 38, 59, 27, 80, 26)
      ..cubicTo(101, 25, 114, 40, 112, 61)
      ..cubicTo(99, 56, 93, 42, 87, 36)
      ..cubicTo(79, 49, 66, 57, 48, 60)
      ..close();
    canvas.drawPath(hairFront, Paint()..color = hair);
    canvas.drawPath(hairFront, line);

    void eye(double x, {bool closed = false}) {
      if (closed) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 75), width: 11, height: 7),
          .15,
          2.75,
          false,
          line,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 75), width: 5, height: 7),
          Paint()..color = outline,
        );
      }
    }

    eye(67, closed: settings.avatarFace == 'calm');
    eye(
      93,
      closed: settings.avatarFace == 'calm' || settings.avatarFace == 'wink',
    );
    canvas.drawArc(const Rect.fromLTWH(60, 65, 14, 8), 3.35, 2.4, false, line);
    canvas.drawArc(const Rect.fromLTWH(86, 65, 14, 8), 3.35, 2.4, false, line);

    if (settings.avatarFace == 'glasses') {
      for (final rect in const [
        Rect.fromLTWH(57, 68, 20, 15),
        Rect.fromLTWH(83, 68, 20, 15),
      ]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          line,
        );
      }
      canvas.drawLine(const Offset(77, 74), const Offset(83, 74), line);
    }

    if (settings.avatarFace == 'freckles') {
      final dots = Paint()..color = const Color(0xFFC56E62);
      for (final point in const [
        Offset(60, 87),
        Offset(65, 89),
        Offset(69, 87),
        Offset(91, 87),
        Offset(95, 89),
        Offset(100, 87),
      ]) {
        canvas.drawCircle(point, 1.2, dots);
      }
    } else {
      final blush = Paint()..color = const Color(0x55E86D82);
      canvas.drawOval(const Rect.fromLTWH(56, 84, 15, 7), blush);
      canvas.drawOval(const Rect.fromLTWH(89, 84, 15, 7), blush);
    }

    canvas.drawLine(const Offset(80, 76), const Offset(77, 87), line);
    canvas.drawLine(const Offset(77, 87), const Offset(82, 88), line);
    if (settings.avatarFace == 'calm') {
      canvas.drawLine(const Offset(72, 98), const Offset(88, 98), line);
    } else {
      canvas.drawArc(
        const Rect.fromLTWH(68, 89, 24, 15),
        .2,
        2.75,
        false,
        line,
      );
    }

    if (settings.avatarOutfit == 'turtleneck') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 112, 36, 19),
          const Radius.circular(7),
        ),
        Paint()..color = clothes,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 112, 36, 19),
          const Radius.circular(7),
        ),
        line,
      );
    } else {
      canvas.drawLine(const Offset(68, 118), const Offset(80, 129), line);
      canvas.drawLine(const Offset(92, 118), const Offset(80, 129), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.settings.avatarFace != settings.avatarFace ||
      oldDelegate.settings.avatarHair != settings.avatarHair ||
      oldDelegate.settings.avatarOutfit != settings.avatarOutfit ||
      oldDelegate.settings.avatarColor != settings.avatarColor ||
      oldDelegate.settings.avatarHairColor != settings.avatarHairColor ||
      oldDelegate.settings.avatarClothes != settings.avatarClothes ||
      oldDelegate.settings.avatarBackground != settings.avatarBackground;
}

class _ColorSetting extends StatelessWidget {
  const _ColorSetting({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });
  final String label;
  final int selected;
  final List<int> colors;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
      Expanded(
        child: _ColorChoices(
          selected: selected,
          colors: colors,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

class _ColorChoices extends StatelessWidget {
  const _ColorChoices({
    required this.selected,
    required this.colors,
    required this.onChanged,
  });
  final int selected;
  final List<int> colors;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    children: [
      for (final color in colors)
        InkWell(
          onTap: () => onChanged(color),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected == color
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        ),
    ],
  );
}
