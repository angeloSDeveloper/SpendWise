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
            child: Stack(
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: ClipOval(
                    child: avatar == null
                        ? SimpleAvatar(settings: settings)
                        : Image.memory(
                            base64Decode(avatar.split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                SimpleAvatar(settings: settings),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: () => pickAvatar(ref),
                    icon: const Icon(Icons.photo_camera),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ExpansionTile(
            leading: const Icon(Icons.face_retouching_natural),
            title: const Text('Personalizza avatar'),
            subtitle: const Text('Faccina, capelli, pelle e vestiti'),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final face in ['🙂', '😎', '😊', '🤓', '😁'])
                    ChoiceChip(
                      label: Text(face, style: const TextStyle(fontSize: 22)),
                      selected: settings.avatarFace == face,
                      onSelected: (_) => ref
                          .read(settingsProvider.notifier)
                          .setAvatarStyle(face: face),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'short', label: Text('Corti')),
                  ButtonSegment(value: 'long', label: Text('Lunghi')),
                  ButtonSegment(value: 'bald', label: Text('Rasati')),
                ],
                selected: {settings.avatarHair},
                onSelectionChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(hair: value.first),
              ),
              const SizedBox(height: 12),
              _ColorChoices(
                selected: settings.avatarColor,
                colors: const [0xFFFFDBB4, 0xFFE6B17E, 0xFFB8784E, 0xFF70442E],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(skin: value),
              ),
              const SizedBox(height: 8),
              _ColorChoices(
                selected: settings.avatarClothes,
                colors: const [
                  0xFF536DFE,
                  0xFFE91E63,
                  0xFF00A884,
                  0xFFFF9800,
                  0xFF6A1B9A,
                ],
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setAvatarStyle(clothes: value),
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

class SimpleAvatar extends StatelessWidget {
  const SimpleAvatar({required this.settings, super.key});
  final SettingsState settings;

  @override
  Widget build(BuildContext context) => Container(
    color: Color(settings.avatarClothes),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -24,
          child: Container(
            width: 92,
            height: 70,
            decoration: BoxDecoration(
              color: Color(settings.avatarClothes),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Color(settings.avatarColor),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            settings.avatarFace,
            style: const TextStyle(fontSize: 38),
          ),
        ),
        if (settings.avatarHair != 'bald')
          Positioned(
            top: settings.avatarHair == 'long' ? 5 : 10,
            child: Icon(
              settings.avatarHair == 'long'
                  ? Icons.face_4
                  : Icons.face_retouching_natural,
              size: 82,
              color: const Color(0xFF3E2723),
            ),
          ),
      ],
    ),
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
