// ARCHIVO TEMPORAL
//
// Este archivo se reemplaza automáticamente al ejecutar, dentro de la carpeta
// admin_app:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --platforms=android
//
// Mientras no se haya configurado, la app muestra una pantalla con instrucciones
// en lugar de cerrarse.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase todavía no está configurado. Ejecutá "flutterfire configure" '
      'dentro de la carpeta admin_app y volvé a compilar la app.',
    );
  }
}
