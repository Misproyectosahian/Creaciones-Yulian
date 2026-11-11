import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// Acceso a la base de datos (Firestore).
class Repo {
  Repo._();
  static final Repo instance = Repo._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  DocumentReference<Map<String, dynamic>> get _settings => _db.collection('settings').doc('store');

  // ── Administradores ──
  Stream<bool> isAdmin(String uid) => _db.collection('admins').doc(uid).snapshots().map((d) => d.exists);

  // ── Productos ──
  Stream<List<Product>> products() => _products.snapshots().map((s) {
        final list = s.docs.map(Product.fromDoc).toList();
        final far = DateTime(2100);
        list.sort((a, b) => (b.createdAt ?? far).compareTo(a.createdAt ?? far));
        return list;
      });

  Future<void> saveProduct(Product p) async {
    final data = p.toMap()..['updatedAt'] = FieldValue.serverTimestamp();
    if (p.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _products.add(data);
    } else {
      await _products.doc(p.id).update(data);
    }
  }

  Future<void> setProductActive(String id, bool active) =>
      _products.doc(id).update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  // ── Catálogos ──
  Stream<List<Category>> categories() => _categories.snapshots().map((s) {
        final list = s.docs.map(Category.fromDoc).toList();
        list.sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.name.compareTo(b.name));
        return list;
      });

  Future<void> saveCategory(Category c) async {
    if (c.id.isEmpty) {
      await _categories.add(c.toMap());
    } else {
      await _categories.doc(c.id).update(c.toMap());
    }
  }

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  Future<void> reorderCategories(List<Category> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_categories.doc(ordered[i].id), {'order': i});
    }
    await batch.commit();
  }

  // ── Pedidos ──
  Stream<List<ShopOrder>> orders({int limit = 300}) => _orders
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ShopOrder.fromDoc).toList());

  Stream<ShopOrder?> order(String id) =>
      _orders.doc(id).snapshots().map((d) => d.exists ? ShopOrder.fromDoc(d) : null);

  Stream<int> unseenOrdersCount() =>
      _orders.where('seen', isEqualTo: false).snapshots().map((s) => s.size);

  Future<void> markSeen(String id) => _orders.doc(id).update({'seen': true});

  Future<void> updateStatus(String id, OrderStatus status) => _orders.doc(id).update({
        'status': status.key,
        // serverTimestamp no se permite dentro de arreglos, por eso Timestamp.now()
        'statusHistory': FieldValue.arrayUnion([
          {'status': status.key, 'at': Timestamp.now()},
        ]),
        'seen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setAmountPaid(String id, int amount) => _orders.doc(id).update({
        'amountPaid': amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setAdminMessage(String id, String message) => _orders.doc(id).update({
        'adminMessage': message.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteOrder(String id) => _orders.doc(id).delete();

  // ── Ajustes ──
  Stream<StoreSettings> settings() => _settings.snapshots().map((d) => StoreSettings.fromMap(d.data()));

  Future<void> saveSettings(StoreSettings s) => _settings.set(
        {...s.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
}
