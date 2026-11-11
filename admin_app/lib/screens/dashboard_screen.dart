import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSeeOrders});
  final VoidCallback onSeeOrders;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<ShopOrder>> _orders = Repo.instance.orders();
  late final Stream<List<Product>> _products = Repo.instance.products();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días!';
    if (h < 18) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShopOrder>>(
      stream: _orders,
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(error: snap.error);
        if (!snap.hasData) return const CenteredLoader(label: 'Cargando...');
        final orders = snap.data!;
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month);

        final pending = orders.where((o) => o.status == OrderStatus.pendientePago).length;
        final working = orders.where((o) => o.status == OrderStatus.pagoRecibido || o.status == OrderStatus.enProceso).length;
        final ready = orders.where((o) => o.status == OrderStatus.listo || o.status == OrderStatus.enCamino).length;
        final monthOrders = orders.where((o) => o.status != OrderStatus.cancelado && (o.createdAt?.isAfter(monthStart) ?? false));
        final monthTotal = monthOrders.fold<int>(0, (s, o) => s + o.total);
        final toCollect = orders.where((o) => o.status.isActive).fold<int>(0, (s, o) => s + o.balance);
        final unseen = orders.where((o) => !o.seen).length;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.strongGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppColors.pink400.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting, style: fredoka(size: 26, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            unseen > 0
                                ? 'Tenés $unseen pedido${unseen == 1 ? '' : 's'} nuevo${unseen == 1 ? '' : 's'} 🎉'
                                : 'Todo al día por aquí 💖',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatDay(now),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Text('🧶', style: TextStyle(fontSize: 50)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _StatCard(emoji: '💌', label: 'Pendientes de pago', value: '$pending', color: OrderStatus.pendientePago.color, onTap: widget.onSeeOrders),
                  _StatCard(emoji: '🧶', label: 'En proceso', value: '$working', color: OrderStatus.enProceso.color, onTap: widget.onSeeOrders),
                  _StatCard(emoji: '🎁', label: 'Por entregar', value: '$ready', color: OrderStatus.listo.color, onTap: widget.onSeeOrders),
                  _StatCard(emoji: '💰', label: 'Por cobrar', value: crc(toCollect), color: AppColors.lilac500),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  leading: const Text('✨', style: TextStyle(fontSize: 28)),
                  title: const Text('Vendido este mes', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
                  subtitle: Text(crc(monthTotal), style: fredoka(size: 26, color: AppColors.pink600)),
                  trailing: Text('${monthOrders.length} pedidos', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Product>>(
                stream: _products,
                builder: (context, ps) {
                  final products = ps.data ?? const <Product>[];
                  final visible = products.where((p) => p.active).length;
                  final soldOut = products.where((p) => p.availability == Availability.agotado).length;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      leading: const Text('🌷', style: TextStyle(fontSize: 26)),
                      title: Text('${products.length} productos', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('$visible visibles en la web · $soldOut agotados'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Text('Pedidos recientes', style: fredoka(size: 20))),
                  TextButton(onPressed: widget.onSeeOrders, child: const Text('Ver todos')),
                ],
              ),
              const SizedBox(height: 6),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: EmptyState(
                    emoji: '🌸',
                    title: 'Todavía no hay pedidos',
                    subtitle: 'Cuando alguien haga un pedido en la web te va a llegar una notificación aquí.',
                  ),
                )
              else
                ...orders.take(5).map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OrderCard(order: o),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.emoji, required this.label, required this.value, required this.color, this.onTap});
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: fredoka(size: 26, color: Color.lerp(color, AppColors.ink, 0.3))),
              ),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
