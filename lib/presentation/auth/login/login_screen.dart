import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/core/constants/app_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authStateProvider) is AuthLoading;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
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
                    color: colors.secondary.withValues(alpha: .12),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: .06),
            blurRadius: 42,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black38,
            blurRadius: 48,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bentornato',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accedi per ritrovare la tua panoramica.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              onPressed: onGoogle,
              icon: const _GoogleMark(),
              label: const Text('Continua con Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: colors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'oppure con email',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),
            ),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: colors.onSurface),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) =>
                  value != null &&
                      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)
                  ? null
                  : 'Inserisci un’email valida',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: password,
              obscureText: hidden,
              style: TextStyle(color: colors.onSurface),
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
}

class _LoginStory extends StatelessWidget {
  const _LoginStory();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CompactBrand(alignedLeft: true),
        const SizedBox(height: 52),
        Text(
          'Tutto ciò che conta,\nin un unico posto.',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 52,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 530,
          child: Text(
            'Organizza spese, scadenze, rate e veicoli con un’esperienza '
            'semplice, veloce e sicura.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 19,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 34),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FeatureChip(
              icon: Icons.dashboard_customize_rounded,
              label: 'Widget',
            ),
            _FeatureChip(icon: Icons.lock_rounded, label: 'PIN e biometria'),
            _FeatureChip(
              icon: Icons.cloud_done_outlined,
              label: 'Backup e sincronizzazione',
            ),
          ],
        ),
      ],
    );
  }
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
      const _SpendWiseMark(size: 46),
      const SizedBox(width: 12),
      Text(
        AppConstants.appName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _SpendWiseMark extends StatelessWidget {
  const _SpendWiseMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withValues(alpha: .72),
        ],
      ),
      borderRadius: BorderRadius.circular(15),
    ),
    child: CustomPaint(
      painter: _SpendWiseMarkPainter(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
  );
}

class _SpendWiseMarkPainter extends CustomPainter {
  const _SpendWiseMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .68, size.height * .27)
        ..cubicTo(
          size.width * .57,
          size.height * .16,
          size.width * .31,
          size.height * .2,
          size.width * .31,
          size.height * .36,
        )
        ..cubicTo(
          size.width * .31,
          size.height * .52,
          size.width * .67,
          size.height * .45,
          size.width * .67,
          size.height * .65,
        )
        ..cubicTo(
          size.width * .67,
          size.height * .8,
          size.width * .39,
          size.height * .85,
          size.width * .26,
          size.height * .7,
        ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .48, size.height * .62)
        ..lineTo(size.width * .59, size.height * .73)
        ..lineTo(size.width * .79, size.height * .49),
      paint..strokeWidth = size.width * .065,
    );
  }

  @override
  bool shouldRepaint(covariant _SpendWiseMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 7),
        Text(label),
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
