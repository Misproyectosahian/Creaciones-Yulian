import 'package:flutter/material.dart';

/// Llave global del navegador: permite abrir un pedido desde una notificación.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Llave global para mostrar mensajes (SnackBar) desde cualquier parte.
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showToast(String message, {String emoji = '💖', SnackBarAction? action}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$emoji  $message'),
        action: action,
        duration: Duration(seconds: action == null ? 3 : 6),
      ),
    );
}
