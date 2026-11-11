import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Se muestra si Firebase todavía no está configurado (flutterfire configure).
class SetupNeededApp extends StatelessWidget {
  const SetupNeededApp({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: SoftBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧶', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 12),
                    Text('Falta un pasito', style: fredoka(size: 26)),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 18),
                    const Text(
                      'Revisá el archivo LEEME.md del proyecto, sección "App móvil".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
