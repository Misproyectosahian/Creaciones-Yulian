import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../services/notification_service.dart';
import '../services/repo.dart';
import '../widgets/cute_effects.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});
  final User user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final Stream<int> _unseen = Repo.instance.unseenOrdersCount();
  StreamSubscription<String>? _openSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  @override
  void initState() {
    super.initState();
    final notifications = NotificationService.instance;
    notifications.registerDevice(widget.user.uid);
    _openSub = notifications.onOpenOrder.listen(_openOrder);
    _foregroundSub = notifications.onForegroundMessage.listen(_onForegroundMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = notifications.takePendingOrder();
      if (pending != null) _openOrder(pending);
    });
  }

  @override
  void dispose() {
    _openSub?.cancel();
    _foregroundSub?.cancel();
    super.dispose();
  }

  void _openOrder(String orderId) {
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    Effects.confetti();
    final orderId = message.data['orderId']?.toString();
    showToast(
      message.notification?.title ?? '¡Nuevo pedido!',
      emoji: '🎉',
      action: orderId == null || orderId.isEmpty
          ? null
          : SnackBarAction(label: 'Ver', onPressed: () => _openOrder(orderId)),
    );
  }

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(onSeeOrders: () => _goTo(1)),
          const OrdersScreen(),
          const ProductsScreen(),
          const CategoriesScreen(),
          SettingsScreen(user: widget.user),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: _unseen,
        builder: (context, snap) {
          final unseen = snap.data ?? 0;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.favorite_border_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unseen > 0,
                  label: Text('$unseen'),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unseen > 0,
                  label: Text('$unseen'),
                  child: const Icon(Icons.receipt_long_rounded),
                ),
                label: 'Pedidos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.local_florist_outlined),
                selectedIcon: Icon(Icons.local_florist_rounded),
                label: 'Productos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark_rounded),
                label: 'Catálogos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Ajustes',
              ),
            ],
          );
        },
      ),
    );
  }
}
