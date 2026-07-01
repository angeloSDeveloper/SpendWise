import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});
  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final pin = TextEditingController();
  String? error;

  Future<void> submit() async {
    final valid = await ref
        .read(localUnlockProvider.notifier)
        .unlockWithPin(pin.text);
    if (!valid && mounted) setState(() => error = 'PIN non corretto');
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(localUnlockProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Sblocca SpendWise',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                if (lock.pinEnabled)
                  TextField(
                    controller: pin,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      errorText: error,
                    ),
                  ),
                const SizedBox(height: 16),
                if (lock.pinEnabled)
                  FilledButton(onPressed: submit, child: const Text('SBLOCCA')),
                if (lock.biometricsEnabled)
                  TextButton.icon(
                    onPressed: () => ref
                        .read(localUnlockProvider.notifier)
                        .unlockWithBiometrics(),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Usa impronta o biometria'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
