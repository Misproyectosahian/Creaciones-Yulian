import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/cute_effects.dart';

String authErrorMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Esperá un momento e intentá de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
    }
    return e.message ?? 'No se pudo ingresar.';
  }
  return 'No se pudo ingresar.';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      Effects.confetti();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Escribí tu correo arriba y tocá de nuevo "¿Olvidaste tu contraseña?"');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showToast('Te enviamos un correo para cambiar la contraseña', emoji: '📬');
    } catch (e) {
      setState(() => _error = authErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: Stack(
          children: [
            // Corazones flotando
            AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final size = MediaQuery.sizeOf(context);
                return Stack(
                  children: List.generate(9, (i) {
                    final phase = (_float.value + i / 9) % 1.0;
                    final x = (i * 0.13 + 0.05) % 1.0 * size.width;
                    final y = size.height * (1.05 - phase * 1.15);
                    return Positioned(
                      left: x + math.sin(phase * math.pi * 2 + i) * 14,
                      top: y,
                      child: Opacity(
                        opacity: (math.sin(phase * math.pi)).clamp(0.0, 1.0) * 0.55,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 14.0 + (i % 4) * 7,
                          color: i.isEven ? AppColors.pink300 : AppColors.lilac300,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(26),
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.strongGradient,
                            boxShadow: [
                              BoxShadow(color: AppColors.pink400.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text('🧶', style: TextStyle(fontSize: 50)),
                        ),
                        const SizedBox(height: 18),
                        Text('Creaciones Yulian', style: pacifico(size: 32)),
                        const SizedBox(height: 4),
                        const Text(
                          'Panel de administración 💖',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 30),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo',
                                    prefixIcon: Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: (v) => (v ?? '').contains('@') ? null : 'Escribí tu correo',
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                    ),
                                  ),
                                  validator: (v) => (v ?? '').length >= 6 ? null : 'Mínimo 6 caracteres',
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.pink50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.pink200),
                                    ),
                                    child: Text('🥺 $_error', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _loading ? null : _login,
                                    child: _loading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                                          )
                                        : const Text('Ingresar'),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(onPressed: _forgot, child: const Text('¿Olvidaste tu contraseña?')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
