import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/auth/local_unlock_provider.dart';
import 'package:spendwise/presentation/onboarding/onboarding_provider.dart';
import 'package:spendwise/presentation/settings/settings_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const pages = [
    (
      icon: Icons.auto_awesome_rounded,
      title: 'Benvenuto in SpendWise',
      description:
          'Tieni insieme spese, abbonamenti, rate e veicoli in un solo posto, '
          'con una vista chiara di ciò che conta davvero.',
      color: Color(0xFF1B74F8),
    ),
    (
      icon: Icons.dashboard_customize_rounded,
      title: 'La tua dashboard, come vuoi tu',
      description:
          'Scegli i widget, riordinali e usa schede quadrate 4×4 oppure '
          'orizzontali 4×8. Ogni elemento apre direttamente il suo dettaglio.',
      color: Color(0xFF7C5CFC),
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Capisci dove vanno i soldi',
      description:
          'Grafici interattivi, scadenze e riepiloghi trasformano i dati che '
          'già inserisci in informazioni utili e immediate.',
      color: Color(0xFF13B98D),
    ),
    (
      icon: Icons.shield_rounded,
      title: 'Protezione fin dal primo accesso',
      description:
          'Puoi proteggere la copia locale con un PIN e, sui dispositivi '
          'compatibili, usare Face ID o l’autenticazione biometrica.',
      color: Color(0xFFFF9F43),
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  Future<void> configurePin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crea il PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'PIN (almeno 4 cifre)',
                  errorText: error,
                ),
              ),
              TextField(
                controller: second,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(labelText: 'Conferma PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                if (!RegExp(r'^\d{4,}$').hasMatch(first.text)) {
                  setDialogState(() => error = 'Usa almeno 4 cifre');
                } else if (first.text != second.text) {
                  setDialogState(() => error = 'I PIN non coincidono');
                } else {
                  Navigator.pop(dialogContext, first.text);
                }
              },
              child: const Text('Salva PIN'),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    second.dispose();
    if (pin == null) return;
    await ref.read(localUnlockProvider.notifier).setPin(pin);
    if (mounted) showAppMessage(context, 'PIN configurato');
  }

  Future<void> configureBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      final available =
          await localAuth.isDeviceSupported() &&
          await localAuth.canCheckBiometrics;
      if (!available) {
        if (mounted) {
          showAppMessage(
            context,
            'Biometria non disponibile su questo dispositivo',
          );
        }
        return;
      }
      final verified = await localAuth.authenticate(
        localizedReason: 'Attiva lo sblocco biometrico di SpendWise',
        biometricOnly: true,
      );
      if (!verified) return;
      await ref.read(settingsProvider.notifier).setBiometrics(true);
      await ref.read(localUnlockProvider.notifier).load();
      if (mounted) showAppMessage(context, 'Sblocco biometrico attivato');
    } catch (_) {
      if (mounted) showAppMessage(context, 'Impossibile attivare la biometria');
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = page == pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
              child: Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 10),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: finish, child: const Text('Salta')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: (value) => setState(() => page = value),
                itemCount: pages.length,
                itemBuilder: (context, index) => _OnboardingPage(
                  data: pages[index],
                  showSecurityActions: index == pages.length - 1,
                  onPin: configurePin,
                  onBiometrics: configureBiometrics,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == page ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == page
                        ? const Color(0xFF1B74F8)
                        : const Color(0xFF34363C),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: last
                      ? finish
                      : () => controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B74F8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(last ? 'Inizia' : 'Avanti'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.showSecurityActions,
    required this.onPin,
    required this.onBiometrics,
  });

  final ({IconData icon, String title, String description, Color color}) data;
  final bool showSecurityActions;
  final VoidCallback onPin;
  final VoidCallback onBiometrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: constraints.maxWidth > 700 ? 310 : 230,
              height: constraints.maxWidth > 700 ? 310 : 230,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.color.withValues(alpha: .35),
                    data.color.withValues(alpha: .06),
                  ],
                ),
                borderRadius: BorderRadius.circular(72),
                border: Border.all(color: data.color.withValues(alpha: .5)),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: .22),
                    blurRadius: 70,
                  ),
                ],
              ),
              child: Icon(data.icon, color: data.color, size: 112),
            ),
            const SizedBox(height: 42),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 590),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9699A2),
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
            ),
            if (showSecurityActions) ...[
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPin,
                    icon: const Icon(Icons.pin_rounded),
                    label: const Text('Configura PIN'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onBiometrics,
                    icon: const Icon(Icons.face_rounded),
                    label: const Text('Usa biometria'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF36A2FF), Color(0xFF1557E8)],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.ssid_chart_rounded, color: Colors.white, size: 22),
  );
}
