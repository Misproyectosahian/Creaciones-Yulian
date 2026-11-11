import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_navigator.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/setup_needed_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'widgets/cute_effects.dart';

/// Se ejecuta cuando llega una notificación con la app cerrada.
/// Android muestra la notificación solito; aquí solo se inicializa Firebase.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await initializeDateFormatting('es');

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on UnsupportedError catch (e) {
    runApp(SetupNeededApp(message: e.message ?? 'Firebase no está configurado.'));
    return;
  } catch (e) {
    runApp(SetupNeededApp(message: 'No se pudo iniciar Firebase: $e'));
    return;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await NotificationService.instance.init();
  runApp(const YulianAdminApp());
}

class YulianAdminApp extends StatelessWidget {
  const YulianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creaciones Yulian',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      builder: (context, child) => CuteEffects(child: child ?? const SizedBox.shrink()),
      home: const AuthGate(),
    );
  }
}
