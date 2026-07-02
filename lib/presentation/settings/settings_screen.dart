import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/app/theme.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_preview.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_screen.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_storage.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';
import 'package:spendwise/presentation/dashboard/dashboard_screen.dart';
import 'package:spendwise/presentation/onboarding/onboarding_provider.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

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
      showAppMessage(
        context,
        'Promemoria attivati. Il browser o il telefono potrà chiedere il consenso alle notifiche.',
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
      await ref.read(localUnlockProvider.notifier).load();
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
        await ref.read(localUnlockProvider.notifier).load();
      }
    } catch (_) {
      if (context.mounted) {
        showAppMessage(
          context,
          'Face ID o biometria non disponibili su questo dispositivo/browser.',
        );
      }
    }
  }

  Future<String?> askPin(
    BuildContext context, {
    required String title,
    bool confirm = false,
  }) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: InputDecoration(labelText: 'PIN', errorText: error),
              ),
              if (confirm)
                TextField(
                  controller: second,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: const InputDecoration(labelText: 'Conferma PIN'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () {
                if (!RegExp(r'^\d{4,}$').hasMatch(first.text)) {
                  setState(() => error = 'Inserisci almeno 4 cifre');
                  return;
                }
                if (confirm && first.text != second.text) {
                  setState(() => error = 'I PIN non coincidono');
                  return;
                }
                Navigator.pop(dialogContext, first.text);
              },
              child: const Text('CONFERMA'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localLock = ref.watch(localUnlockProvider);
    ref.watch(avatarBuilderRevisionProvider);
    final avatar = settings.avatarData;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profilo', style: Theme.of(context).textTheme.headlineSmall),
          const Text('Foto, avatar e identità visiva del tuo account.'),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                SizedBox.square(
                  dimension: 164,
                  child: Center(
                    child: avatar == null
                        ? FutureBuilder<AvatarBuilderConfig>(
                            future: AvatarBuilderStorage.load(),
                            builder: (context, snapshot) =>
                                AvatarBuilderPreview(
                                  config:
                                      snapshot.data ??
                                      const AvatarBuilderConfig(),
                                  overrideSize: 154,
                                ),
                          )
                        : ClipOval(
                            child: Image.memory(
                              base64Decode(avatar.split(',').last),
                              width: 154,
                              height: 154,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const AvatarBuilderPreview(
                                    config: AvatarBuilderConfig(),
                                    overrideSize: 154,
                                  ),
                            ),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Personalizza avatar'),
              subtitle: const Text(
                'Iniziali, icone, forme, colori, bordo e preset rapidi.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AvatarBuilderScreen(),
                  ),
                );
                if (changed == true) {
                  await ref.read(settingsProvider.notifier).clearAvatar();
                  ref.read(avatarBuilderRevisionProvider.notifier).state++;
                }
              },
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Impostazioni generali',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Text(
            'Aspetto, navigazione, dati, notifiche e sicurezza dell’app.',
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 16),
          Text('Tema colore', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final colorTheme in AppColorThemes.values)
                ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: colorTheme.primaryDark,
                    radius: 8,
                  ),
                  label: Text(colorTheme.name),
                  selected: settings.colorTheme == colorTheme.id,
                  onSelected: (_) => ref
                      .read(settingsProvider.notifier)
                      .setColorTheme(colorTheme.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Lingua', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.localeCode,
            decoration: const InputDecoration(
              labelText: 'Lingua dell’applicazione',
              prefixIcon: Icon(Icons.language),
            ),
            items: const [
              DropdownMenuItem(value: 'it', child: Text('Italiano')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            ],
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setLocale(value!),
          ),
          const SizedBox(height: 20),
          Text('Interazioni', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 'left',
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Swipe a sinistra', maxLines: 1),
                ),
              ),
              ButtonSegment(
                value: 'right',
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Swipe a destra', maxLines: 1),
                ),
              ),
            ],
            selected: {settings.swipeDirection},
            onSelectionChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setSwipeDirection(value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: settings.bannerDurationSeconds,
            decoration: const InputDecoration(
              labelText: 'Durata messaggi',
              helperText: '0 disattiva i banner; massimo 15 secondi',
              suffixText: 'secondi',
            ),
            items: [
              for (var seconds = 0; seconds <= 15; seconds++)
                DropdownMenuItem(
                  value: seconds,
                  child: Text(seconds == 0 ? 'Nessun banner' : '$seconds'),
                ),
            ],
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setBannerDuration(value!),
          ),
          const SizedBox(height: 20),
          Text(
            'Sezioni visibili',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'La panoramica, le statistiche e la navigazione seguiranno queste scelte.',
          ),
          for (final module in const {
            'daily': ('Spese', Icons.receipt_long),
            'subscriptions': ('Abbonamenti', Icons.autorenew),
            'installments': ('Rate', Icons.credit_card),
            'vehicle': ('Veicolo', Icons.directions_car),
          }.entries)
            SwitchListTile(
              secondary: CircleAvatar(
                backgroundColor: settings.moduleColor(module.key),
                child: Icon(module.value.$2, color: Colors.white),
              ),
              title: Text(module.value.$1),
              subtitle: const Text('Tocca il colore per personalizzare'),
              value: settings.visibleModules.contains(module.key),
              onChanged: (value) => ref
                  .read(settingsProvider.notifier)
                  .setModule(module.key, value),
            ),
          const SizedBox(height: 8),
          Text(
            'Colori delle sezioni',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final module in const {
            'daily': 'Spese',
            'subscriptions': 'Abbonamenti',
            'installments': 'Rate',
            'vehicle': 'Veicolo',
          }.entries)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: settings.moduleColor(module.key),
              ),
              title: Text(module.value),
              trailing: Wrap(
                spacing: 6,
                children: [
                  for (final color in const [
                    0xFF2563EB,
                    0xFF8B5CF6,
                    0xFFEC4899,
                    0xFF10B981,
                    0xFFF59E0B,
                    0xFFE11D48,
                  ])
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setModuleColor(module.key, color),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(color),
                          child: settings.moduleColors[module.key] == color
                              ? const Icon(
                                  Icons.check,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text('Dati e backup', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Sincronizzazione automatica'),
            subtitle: Text(
              settings.cloudBackupEnabled
                  ? 'Le modifiche locali vengono copiate anche sul profilo'
                  : 'Modalità locale: nessun invio automatico',
            ),
            value: settings.cloudBackupEnabled,
            onChanged: (value) async {
              await ref.read(settingsProvider.notifier).setCloudBackup(value);
              if (value) {
                await ref.read(syncServiceProvider).sync();
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'SpendWise conserva sempre i dati sul dispositivo. Puoi creare '
              'un backup manuale o ripristinare la copia presente sul profilo.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  showAppMessage(context, 'Backup in corso…');
                  final completed = await ref
                      .read(syncServiceProvider)
                      .sync(force: true);
                  if (!context.mounted) return;
                  final info = ref.read(syncInfoProvider);
                  showAppMessage(
                    context,
                    completed
                        ? 'Backup online completato. I dati restano anche sul dispositivo.'
                        : info.error ?? 'Backup non riuscito.',
                  );
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Backup ora'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Ripristina dal cloud'),
                          content: const Text(
                            'La copia online sostituirà i dati visualizzati '
                            'su questo dispositivo. Le modifiche locali non '
                            'salvate devono essere prima incluse in un backup.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('ANNULLA'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('RIPRISTINA'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!confirmed || !context.mounted) return;
                  showAppMessage(context, 'Ripristino in corso…');
                  final restored = await ref
                      .read(syncServiceProvider)
                      .restoreFromCloud();
                  ref.invalidate(dashboardDataProvider);
                  if (!context.mounted) return;
                  final info = ref.read(syncInfoProvider);
                  showAppMessage(
                    context,
                    restored
                        ? 'Dati ripristinati dal profilo.'
                        : info.error ?? 'Ripristino non riuscito.',
                  );
                },
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Ripristina dal cloud'),
              ),
            ],
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
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(localLock.pinEnabled ? 'Modifica PIN' : 'Imposta PIN'),
            subtitle: const Text('Almeno 4 cifre, salvato in modo sicuro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final value = await askPin(
                context,
                title: localLock.pinEnabled ? 'Nuovo PIN' : 'Imposta PIN',
                confirm: true,
              );
              if (value != null) {
                await ref.read(localUnlockProvider.notifier).setPin(value);
                if (context.mounted) showAppMessage(context, 'PIN salvato');
              }
            },
          ),
          if (localLock.pinEnabled)
            ListTile(
              leading: const Icon(Icons.lock_open_outlined),
              title: const Text('Disattiva PIN'),
              onTap: () async {
                final value = await askPin(
                  context,
                  title: 'Inserisci il PIN attuale',
                );
                if (value == null) return;
                try {
                  await ref
                      .read(localUnlockProvider.notifier)
                      .disablePin(value);
                } catch (_) {
                  if (context.mounted) {
                    showAppMessage(context, 'PIN non corretto');
                  }
                }
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: const Text('Rivedi la guida iniziale'),
            subtitle: const Text('Panoramica delle funzioni principali'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await ref.read(onboardingProvider.notifier).restart();
              if (context.mounted) context.go('/welcome');
            },
          ),
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
