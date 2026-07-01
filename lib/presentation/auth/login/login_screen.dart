import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/onboarding/onboarding_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .login(email.text.trim(), password.text);
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state is Authenticated) context.go('/dashboard');
    if (state case AuthError(:final message)) {
      showAppMessage(context, message);
    }
  }

  void googleSignIn() {
    showAppMessage(
      context,
      'Accesso Google predisposto: servono Client ID OAuth e endpoint '
      'server prima di abilitarlo in sicurezza.',
    );
  }

  Future<void> replayIntroduction() async {
    await ref.read(onboardingProvider.notifier).restart();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authStateProvider) is AuthLoading;
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final form = _LoginForm(
              formKey: formKey,
              email: email,
              password: password,
              hidden: hidden,
              loading: loading,
              onTogglePassword: () => setState(() => hidden = !hidden),
              onSubmit: submit,
              onGoogle: googleSignIn,
            );
            return Stack(
              children: [
                Positioned(
                  top: -130,
                  right: -100,
                  child: _Glow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .22),
                    size: 430,
                  ),
                ),
                Positioned(
                  bottom: -180,
                  left: -130,
                  child: _Glow(
                    color: AppColors.secondary.withValues(alpha: .16),
                    size: 480,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: desktop
                          ? Row(
                              children: [
                                const Expanded(child: _LoginStory()),
                                const SizedBox(width: 70),
                                SizedBox(width: 430, child: form),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                children: [
                                  const _CompactBrand(),
                                  const SizedBox(height: 28),
                                  form,
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 14,
                  child: TextButton.icon(
                    onPressed: replayIntroduction,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Guida'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.hidden,
    required this.loading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoogle,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool hidden;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF15171B),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFF2A2D34)),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 50, offset: Offset(0, 24)),
      ],
    ),
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bentornato',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accedi per ritrovare la tua dashboard.',
            style: TextStyle(color: Color(0xFF9A9DA6)),
          ),
          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: onGoogle,
            icon: const _GoogleMark(),
            label: const Text('Continua con Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: Color(0xFF3B3E46)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              children: [
                Expanded(child: Divider(color: Color(0xFF343740))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'oppure con email',
                    style: TextStyle(color: Color(0xFF777A83), fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFF343740))),
              ],
            ),
          ),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) =>
                value != null && RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)
                ? null
                : 'Inserisci un’email valida',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: hidden,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  hidden
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            validator: (value) =>
                (value?.isNotEmpty ?? false) ? null : 'Password obbligatoria',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showAppMessage(
                context,
                'Recupero password disponibile prossimamente',
              ),
              child: const Text('Password dimenticata?'),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1677F2),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: loading
                ? const SizedBox.square(
                    dimension: 21,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Accedi'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/register'),
            child: const Text('Non hai un account? Registrati'),
          ),
        ],
      ),
    ),
  );
}

class _LoginStory extends StatelessWidget {
  const _LoginStory();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _CompactBrand(alignedLeft: true),
      SizedBox(height: 52),
      Text(
        'Tutto ciò che conta,\nin una sola dashboard.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 52,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.8,
        ),
      ),
      SizedBox(height: 22),
      SizedBox(
        width: 530,
        child: Text(
          'Organizza spese, scadenze, rate e veicoli con widget costruiti '
          'intorno al tuo modo di usare SpendWise.',
          style: TextStyle(color: Color(0xFF9A9DA6), fontSize: 19, height: 1.5),
        ),
      ),
      SizedBox(height: 34),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _FeatureChip(
            icon: Icons.dashboard_customize_rounded,
            label: 'Widget',
          ),
          _FeatureChip(icon: Icons.lock_rounded, label: 'PIN e biometria'),
          _FeatureChip(icon: Icons.cloud_done_rounded, label: 'Backup'),
        ],
      ),
    ],
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand({this.alignedLeft = false});

  final bool alignedLeft;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: alignedLeft ? MainAxisSize.max : MainAxisSize.min,
    mainAxisAlignment: alignedLeft
        ? MainAxisAlignment.start
        : MainAxisAlignment.center,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF35A3FF), Color(0xFF1555E8)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.ssid_chart_rounded, color: Colors.white),
      ),
      const SizedBox(width: 12),
      const Text(
        AppConstants.appName,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF15171B),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFF2B2E35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF48A5FF)),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xFF4285F4),
      fontSize: 20,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: size * .45)],
    ),
  );
}
