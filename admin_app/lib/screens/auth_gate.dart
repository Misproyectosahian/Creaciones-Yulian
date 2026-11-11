import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Decide qué mostrar: login, "no sos admin" o la app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _auth = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _Splash();
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return _AdminCheck(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _AdminCheck extends StatefulWidget {
  const _AdminCheck({super.key, required this.user});
  final User user;

  @override
  State<_AdminCheck> createState() => _AdminCheckState();
}

class _AdminCheckState extends State<_AdminCheck> {
  late final Stream<bool> _isAdmin = Repo.instance.isAdmin(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isAdmin,
      builder: (context, snap) {
        if (snap.hasError) return _NotAdmin(user: widget.user, error: snap.error);
        if (!snap.hasData) return const _Splash();
        if (snap.data != true) return _NotAdmin(user: widget.user);
        return HomeShell(user: widget.user);
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HeartLoader(size: 56),
              const SizedBox(height: 16),
              Text('Creaciones Yulian', style: pacifico(size: 26)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotAdmin extends StatelessWidget {
  const _NotAdmin({required this.user, this.error});
  final User user;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text('Cuenta sin acceso', style: fredoka(size: 24)),
                  const SizedBox(height: 10),
                  Text(
                    'La cuenta ${user.email ?? ''} no es de administración.\n\n'
                    'Para darle acceso, creá en Firestore el documento:\n'
                    'admins/${user.uid}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.5),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                  const SizedBox(height: 22),
                  SelectableText(user.uid, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Usar otra cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
