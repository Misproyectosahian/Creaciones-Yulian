import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../theme.dart';

/// Maneja las notificaciones push de pedidos nuevos.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pedidos',
    'Pedidos nuevos',
    description: 'Avisos cuando entra un pedido nuevo 💖',
    importance: Importance.max,
  );

  final _local = FlutterLocalNotificationsPlugin();
  final _openOrder = StreamController<String>.broadcast();
  final _foreground = StreamController<RemoteMessage>.broadcast();

  String? _pendingOrderId;
  String? _currentToken;
  StreamSubscription<String>? _tokenSub;
  bool _initialized = false;

  /// Se emite cuando la usuaria toca una notificación de pedido.
  Stream<String> get onOpenOrder => _openOrder.stream;

  /// Se emite cuando llega una notificación con la app abierta.
  Stream<RemoteMessage> get onForegroundMessage => _foreground.stream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_heart'),
        ),
        onDidReceiveNotificationResponse: (response) => _emit(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _setPending(launch?.notificationResponse?.payload);
      }

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _setPending(initial.data['orderId']?.toString());

      FirebaseMessaging.onMessageOpenedApp.listen((m) => _emit(m.data['orderId']?.toString()));
      FirebaseMessaging.onMessage.listen(_onForeground);
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  void _setPending(String? orderId) {
    if (orderId != null && orderId.isNotEmpty) _pendingOrderId = orderId;
  }

  void _emit(String? orderId) {
    if (orderId == null || orderId.isEmpty) return;
    if (_openOrder.hasListener) {
      _openOrder.add(orderId);
    } else {
      _pendingOrderId = orderId;
    }
  }

  /// Pedido pendiente de abrir (cuando la app se abrió desde una notificación).
  String? takePendingOrder() {
    final id = _pendingOrderId;
    _pendingOrderId = null;
    return id;
  }

  Future<void> _onForeground(RemoteMessage message) async {
    _foreground.add(message);
    final n = message.notification;
    if (n == null) return;
    try {
      await _local.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000000),
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_stat_heart',
            color: AppColors.pink500,
          ),
        ),
        payload: message.data['orderId']?.toString(),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
    }
  }

  /// Pide permiso y guarda el token de este celular para recibir avisos.
  Future<bool> registerDevice(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return false;
      // Se usa el token FCM clásico (estable y compatible con firebase-admin).
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      // ignore: deprecated_member_use
      _tokenSub ??= messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
      return token != null;
    } catch (e) {
      debugPrint('No se pudo registrar el dispositivo: $e');
      return false;
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    final previous = _currentToken;
    _currentToken = token;
    final devices = FirebaseFirestore.instance.collection('adminDevices');
    await devices.doc(token).set({
      'uid': uid,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (previous != null && previous != token) {
      try {
        await devices.doc(previous).delete();
      } catch (_) {}
    }
  }

  Future<bool> notificationsAllowed() async {
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Deja de recibir avisos en este celular (al cerrar sesión).
  Future<void> unregisterDevice() async {
    try {
      // ignore: deprecated_member_use
      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('adminDevices').doc(token).delete();
      }
    } catch (e) {
      debugPrint('No se pudo quitar el dispositivo: $e');
    }
    await _tokenSub?.cancel();
    _tokenSub = null;
    _currentToken = null;
  }
}
