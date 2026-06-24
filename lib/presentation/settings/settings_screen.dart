import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_config.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_customizer_view.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_service.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_visual.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';

final avatarRevisionProvider = StateProvider<int>((ref) => 0);

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
    final user = ref.watch(currentUserProvider);
    ref.watch(avatarRevisionProvider);
    final avatar = settings.avatarData;
    final userId = user?.id ?? 'local-user';
    final initials = _initials(
      user?.displayName?.isNotEmpty == true ? user!.displayName! : user?.email,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: 172,
                    height: 172,
                    child: ClipOval(
                      child: avatar != null
                          ? Image.memory(
                              base64Decode(avatar.split(',').last),
                              fit: BoxFit.cover,
                            )
                          : FutureBuilder<AvatarConfig>(
                              future: AvatarService.loadAvatarConfig(
                                userId,
                                initials: initials,
                              ),
                              builder: (context, snapshot) => AvatarVisual(
                                config:
                                    snapshot.data ??
                                    AvatarService.generateAvatarFromUserId(
                                      userId,
                                      initials,
                                    ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Avatar profilo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SVG leggero, responsive e salvato come configurazione JSON',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final current = await AvatarService.loadAvatarConfig(
                            userId,
                            initials: initials,
                          );
                          if (!context.mounted) return;
                          final changed = await Navigator.of(context)
                              .push<AvatarConfig>(
                                MaterialPageRoute(
                                  builder: (_) => AvatarCustomizerView(
                                    userId: userId,
                                    initialConfig: current,
                                  ),
                                ),
                              );
                          if (changed != null) {
                            await ref
                                .read(settingsProvider.notifier)
                                .clearAvatar();
                            ref.read(avatarRevisionProvider.notifier).state++;
                          }
                        },
                        icon: const Icon(Icons.tune),
                        label: const Text('Personalizza avatar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => pickAvatar(ref),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Usa foto'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versione applicazione'),
            trailing: Text(AppConstants.appVersion),
          ),
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

String _initials(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final parts = value
      .trim()
      .split(RegExp(r'[\s@._-]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
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
