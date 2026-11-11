import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<ShopOrder>> _orders = Repo.instance.orders();
  final _search = TextEditingController();
  String _query = '';

  /// null = activos, 'new' = nuevos, 'all' = todos, o la clave de un estado.
  String? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ShopOrder> _apply(List<ShopOrder> orders) {
    Iterable<ShopOrder> list = orders;
    switch (_filter) {
      case null:
        list = list.where((o) => o.status.isActive);
      case 'all':
        break;
      case 'new':
        list = list.where((o) => !o.seen);
      default:
        list = list.where((o) => o.status.key == _filter);
    }
    final q = normalize(_query.trim());
    if (q.isNotEmpty) {
      final qDigits = onlyDigits(q);
      list = list.where((o) {
        final hay = normalize('${o.orderNumber} ${o.customer.name} ${o.customer.email} ${o.items.map((i) => i.name).join(' ')}');
        return hay.contains(q) || (qDigits.length >= 3 && onlyDigits(o.customer.phone).contains(qDigits));
      });
    }
    return list.toList();
  }

  int _count(List<ShopOrder> orders, String? filter) {
    switch (filter) {
      case null:
        return orders.where((o) => o.status.isActive).length;
      case 'all':
        return orders.length;
      case 'new':
        return orders.where((o) => !o.seen).length;
      default:
        return orders.where((o) => o.status.key == filter).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos 🧾')),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orders,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(error: snap.error);
          if (!snap.hasData) return const CenteredLoader();
          final all = snap.data!;
          final filtered = _apply(all);
          final filters = <(String?, String)>[
            (null, '✨ Activos'),
            ('new', '🎉 Nuevos'),
            for (final s in OrderStatus.values) (s.key, '${s.emoji} ${s.label}'),
            ('all', '📚 Todos'),
          ];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número, nombre o teléfono',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final (key, label) = filters[i];
                    final count = _count(all, key);
                    return ChoiceChip(
                      label: Text(count > 0 ? '$label · $count' : label),
                      selected: _filter == key,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = key),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        emoji: all.isEmpty ? '🌸' : '🔍',
                        title: all.isEmpty ? 'Todavía no hay pedidos' : 'No hay pedidos aquí',
                        subtitle: all.isEmpty
                            ? 'Los pedidos de la web aparecerán aquí al instante.'
                            : 'Probá con otro filtro o búsqueda.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => OrderCard(order: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta de pedido para las listas.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});
  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: o.seen ? AppColors.pink100 : AppColors.pink400, width: o.seen ? 1.5 : 2),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              NetImage(o.cover, width: 64, height: 64, radius: 16, thumbWidth: 200),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(o.orderNumber, style: fredoka(size: 16), overflow: TextOverflow.ellipsis),
                        ),
                        if (!o.seen) ...[
                          const SizedBox(width: 6),
                          const Pill('NUEVO', color: AppColors.pink500),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.customer.name.isEmpty ? 'Cliente' : o.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${timeAgo(o.createdAt)} · ${o.itemCount} ${o.itemCount == 1 ? 'producto' : 'productos'}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(crc(o.total), style: fredoka(size: 16, color: AppColors.pink600)),
                  const SizedBox(height: 6),
                  StatusChip(o.status, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
