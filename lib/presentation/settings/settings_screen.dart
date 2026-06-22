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
                CircleAvatar(
                  radius: 52,
                  backgroundImage: avatar == null
                      ? null
                      : MemoryImage(base64Decode(avatar.split(',').last)),
                  child: avatar == null
                      ? const Icon(Icons.person, size: 52)
                      : null,
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
