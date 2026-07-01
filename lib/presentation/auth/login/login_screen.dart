import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spendwise/core/constants/app_constants.dart';
import 'package:spendwise/presentation/shared/providers/auth_provider.dart';
import 'package:spendwise/presentation/shared/app_feedback.dart';

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

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authStateProvider) is AuthLoading;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bentornato',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'Accedi al tuo account',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
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
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.isNotEmpty ?? false)
                            ? null
                            : 'Password obbligatoria',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showAppMessage(
                            context,
                            'Recupero password disponibile prossimamente',
                          ),
                          child: const Text('Hai dimenticato la password?'),
                        ),
                      ),
                      FilledButton(
                        onPressed: loading ? null : submit,
                        child: loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Accedi'),
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('oppure'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Non hai un account? Registrati'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
