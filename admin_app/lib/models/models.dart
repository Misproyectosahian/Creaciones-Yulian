import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────── Helpers de lectura segura ───────────────────────────

String _str(dynamic v, [String fallback = '']) => v is String ? v : fallback;

int _int(dynamic v, [int fallback = 0]) => v is num ? v.round() : fallback;

bool _bool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> _strList(dynamic v) =>
    v is List ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList() : <String>[];

DateTime? _date(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

// ─────────────────────────────────── Productos ───────────────────────────────────

enum Availability {
  disponible('Disponible', '✅', Color(0xFF3BB58A)),
  encargo('Por encargo', '🧶', Color(0xFF9B7BE0)),
  agotado('Agotado', '💤', Color(0xFF9E8FA8));

  const Availability(this.label, this.emoji, this.color);
  final String label;
  final String emoji;
  final Color color;

  static Availability parse(dynamic v) =>
      Availability.values.firstWhere((a) => a.name == v, orElse: () => Availability.disponible);
}

class Product {
  Product({
    this.id = '',
    this.name = '',
    this.description = '',
    this.price = 0,
    this.minDeposit = 0,
    this.categoryId = '',
    List<String>? images,
    List<String>? options,
    this.optionsLabel = 'Color',
    this.availability = Availability.disponible,
    this.leadTime = '',
    this.featured = false,
    this.active = true,
    this.createdAt,
  })  : images = images ?? <String>[],
        options = options ?? <String>[];

  final String id;
  final String name;
  final String description;
  final int price;
  final int minDeposit;
  final String categoryId;
  final List<String> images;
  final List<String> options;
  final String optionsLabel;
  final Availability availability;
  final String leadTime;
  final bool featured;
  final bool active;
  final DateTime? createdAt;

  String? get cover => images.isEmpty ? null : images.first;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Product(
      id: doc.id,
      name: _str(m['name']),
      description: _str(m['description']),
      price: _int(m['price']),
      minDeposit: _int(m['minDeposit']),
      categoryId: _str(m['categoryId']),
      images: _strList(m['images']),
      options: _strList(m['options']),
      optionsLabel: _str(m['optionsLabel'], 'Color'),
      availability: Availability.parse(m['availability']),
      leadTime: _str(m['leadTime']),
      featured: _bool(m['featured']),
      active: _bool(m['active'], true),
      createdAt: _date(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'minDeposit': minDeposit,
        'categoryId': categoryId,
        'images': images,
        'options': options,
        'optionsLabel': optionsLabel.trim().isEmpty ? 'Opción' : optionsLabel.trim(),
        'availability': availability.name,
        'leadTime': leadTime.trim(),
        'featured': featured,
        'active': active,
      };
}

// ─────────────────────────────────── Catálogos ───────────────────────────────────

class Category {
  Category({this.id = '', this.name = '', this.emoji = '🌸', this.description = '', this.order = 0});

  final String id;
  final String name;
  final String emoji;
  final String description;
  final int order;

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return Category(
      id: doc.id,
      name: _str(m['name']),
      emoji: _str(m['emoji'], '🌸'),
      description: _str(m['description']),
      order: _int(m['order']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'emoji': emoji.trim().isEmpty ? '🌸' : emoji.trim(),
        'description': description.trim(),
        'order': order,
      };
}

// ──────────────────────────────── Estados del pedido ────────────────────────────────

enum OrderStatus {
  pendientePago('pendiente_pago', 'Pendiente de pago', '💌', Color(0xFFF06A9E)),
  pagoRecibido('pago_recibido', 'Pago recibido', '💖', Color(0xFFD94F8C)),
  enProceso('en_proceso', 'En proceso', '🧶', Color(0xFF9B7BE0)),
  listo('listo', 'Listo para entregar', '🎁', Color(0xFFE59A2F)),
  enCamino('en_camino', 'En camino', '🚗', Color(0xFF4A9FD8)),
  entregado('entregado', 'Entregado', '🌸', Color(0xFF3BB58A)),
  cancelado('cancelado', 'Cancelado', '🥀', Color(0xFF9E8FA8));

  const OrderStatus(this.key, this.label, this.emoji, this.color);
  final String key;
  final String label;
  final String emoji;
  final Color color;

  bool get isActive => this != entregado && this != cancelado;

  static OrderStatus fromKey(dynamic k) =>
      OrderStatus.values.firstWhere((s) => s.key == k, orElse: () => OrderStatus.pendientePago);
}

class StatusEvent {
  StatusEvent(this.status, this.at);
  final OrderStatus status;
  final DateTime? at;
}

class CustomerInfo {
  CustomerInfo({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.province = '',
    this.canton = '',
    this.district = '',
    this.address = '',
  });

  final String name;
  final String phone;
  final String email;
  final String province;
  final String canton;
  final String district;
  final String address;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get location => [district, canton, province].where((s) => s.trim().isNotEmpty).join(', ');

  factory CustomerInfo.fromMap(Map<String, dynamic> m) => CustomerInfo(
        name: _str(m['name']),
        phone: _str(m['phone']),
        email: _str(m['email']),
        province: _str(m['province']),
        canton: _str(m['canton']),
        district: _str(m['district']),
        address: _str(m['address']),
      );
}

class OrderItem {
  OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.minDeposit,
    required this.qty,
    required this.option,
    required this.note,
    required this.subtotal,
  });

  final String productId;
  final String name;
  final String image;
  final int price;
  final int minDeposit;
  final int qty;
  final String option;
  final String note;
  final int subtotal;

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    final price = _int(m['price']);
    final qty = math.max(1, _int(m['qty'], 1));
    return OrderItem(
      productId: _str(m['productId']),
      name: _str(m['name'], 'Producto'),
      image: _str(m['image']),
      price: price,
      minDeposit: _int(m['minDeposit']),
      qty: qty,
      option: _str(m['option']),
      note: _str(m['note']),
      subtotal: _int(m['subtotal'], price * qty),
    );
  }
}

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.customer,
    required this.items,
    required this.total,
    required this.minDeposit,
    required this.amountPaid,
    required this.status,
    required this.history,
    required this.deliveryMethod,
    required this.deliveryDetails,
    required this.neededBy,
    required this.customerNotes,
    required this.adminMessage,
    required this.seen,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String userId;
  final CustomerInfo customer;
  final List<OrderItem> items;
  final int total;
  final int minDeposit;
  final int amountPaid;
  final OrderStatus status;
  final List<StatusEvent> history;
  final String deliveryMethod;
  final String deliveryDetails;
  final String neededBy;
  final String customerNotes;
  final String adminMessage;
  final bool seen;
  final DateTime? createdAt;

  int get itemCount => items.fold(0, (total, i) => total + i.qty);
  int get balance => math.max(0, total - amountPaid);
  bool get depositCovered => amountPaid >= minDeposit;
  String get cover => items.map((i) => i.image).firstWhere((s) => s.isNotEmpty, orElse: () => '');

  DateTime? dateOf(OrderStatus s) {
    for (final e in history.reversed) {
      if (e.status == s) return e.at;
    }
    return null;
  }

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    final items = (m['items'] is List ? m['items'] as List : const [])
        .map((e) => OrderItem.fromMap(_map(e)))
        .toList();
    final history = (m['statusHistory'] is List ? m['statusHistory'] as List : const [])
        .map((e) {
          final h = _map(e);
          return StatusEvent(OrderStatus.fromKey(h['status']), _date(h['at']));
        })
        .toList();
    return ShopOrder(
      id: doc.id,
      orderNumber: _str(m['orderNumber'], '#${doc.id.substring(0, math.min(6, doc.id.length))}'),
      userId: _str(m['userId']),
      customer: CustomerInfo.fromMap(_map(m['customer'])),
      items: items,
      total: _int(m['total']),
      minDeposit: _int(m['minDeposit']),
      amountPaid: _int(m['amountPaid']),
      status: OrderStatus.fromKey(m['status']),
      history: history,
      deliveryMethod: _str(m['deliveryMethod']),
      deliveryDetails: _str(m['deliveryDetails']),
      neededBy: _str(m['neededBy']),
      customerNotes: _str(m['customerNotes']),
      adminMessage: _str(m['adminMessage']),
      seen: _bool(m['seen'], true),
      createdAt: _date(m['createdAt']),
    );
  }
}

// ──────────────────────────────── Ajustes de la tienda ────────────────────────────────

class StoreSettings {
  StoreSettings({
    this.storeName = 'Creaciones Yulian',
    this.tagline = 'Crochet, ramos y flores eternas hechos a mano con amor 💖',
    this.aboutText = '',
    this.whatsapp = '',
    this.sinpeNumber = '',
    this.sinpeName = '',
    this.paymentInstructions =
        'Para confirmar tu pedido, realizá el SINPE Móvil del adelanto y enviá el comprobante por WhatsApp junto con tu número de pedido 💌',
    List<String>? deliveryMethods,
    this.instagram = '',
    this.facebook = '',
    this.tiktok = '',
    this.orderPrefix = 'CY',
  }) : deliveryMethods = deliveryMethods ?? const ['Retiro en persona', 'Entrega a domicilio', 'Punto de encuentro'];

  final String storeName;
  final String tagline;
  final String aboutText;
  final String whatsapp;
  final String sinpeNumber;
  final String sinpeName;
  final String paymentInstructions;
  final List<String> deliveryMethods;
  final String instagram;
  final String facebook;
  final String tiktok;
  final String orderPrefix;

  factory StoreSettings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return StoreSettings();
    final d = StoreSettings();
    final methods = _strList(m['deliveryMethods']);
    return StoreSettings(
      storeName: _str(m['storeName'], d.storeName),
      tagline: _str(m['tagline'], d.tagline),
      aboutText: _str(m['aboutText']),
      whatsapp: _str(m['whatsapp']),
      sinpeNumber: _str(m['sinpeNumber']),
      sinpeName: _str(m['sinpeName']),
      paymentInstructions: _str(m['paymentInstructions'], d.paymentInstructions),
      deliveryMethods: methods.isEmpty ? d.deliveryMethods : methods,
      instagram: _str(m['instagram']),
      facebook: _str(m['facebook']),
      tiktok: _str(m['tiktok']),
      orderPrefix: _str(m['orderPrefix'], d.orderPrefix),
    );
  }

  Map<String, dynamic> toMap() => {
        'storeName': storeName.trim(),
        'tagline': tagline.trim(),
        'aboutText': aboutText.trim(),
        'whatsapp': whatsapp.trim(),
        'sinpeNumber': sinpeNumber.trim(),
        'sinpeName': sinpeName.trim(),
        'paymentInstructions': paymentInstructions.trim(),
        'deliveryMethods': deliveryMethods.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'instagram': instagram.trim(),
        'facebook': facebook.trim(),
        'tiktok': tiktok.trim(),
        'orderPrefix': orderPrefix.trim().toUpperCase(),
      };
}
