import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../models/models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final Stream<List<Product>> _products = Repo.instance.products();
  late final Stream<List<Category>> _categories = Repo.instance.categories();
  final _search = TextEditingController();
  String _query = '';
  String? _category; // null = todos, '' = sin catálogo

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open([Product? p]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos 🌷')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<List<Category>>(
        stream: _categories,
        builder: (context, catSnap) {
          final categories = catSnap.data ?? const <Category>[];
          final catById = {for (final c in categories) c.id: c};
          return StreamBuilder<List<Product>>(
            stream: _products,
            builder: (context, snap) {
              if (snap.hasError) return ErrorState(error: snap.error);
              if (!snap.hasData) return const CenteredLoader();
              final all = snap.data!;
              final q = normalize(_query.trim());
              final list = all.where((p) {
                if (_category != null) {
                  final cid = catById.containsKey(p.categoryId) ? p.categoryId : '';
                  if (cid != _category) return false;
                }
                if (q.isEmpty) return true;
                return normalize('${p.name} ${p.description} ${catById[p.categoryId]?.name ?? ''}').contains(q);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar productos',
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
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chip('✨ Todos', null, all.length),
                        for (final c in categories)
                          _chip('${c.emoji} ${c.name}', c.id, all.where((p) => p.categoryId == c.id).length),
                        if (all.any((p) => !catById.containsKey(p.categoryId)))
                          _chip('📦 Sin catálogo', '', all.where((p) => !catById.containsKey(p.categoryId)).length),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: list.isEmpty
                        ? EmptyState(
                            emoji: all.isEmpty ? '🧸' : '🔍',
                            title: all.isEmpty ? 'Aún no hay productos' : 'Sin resultados',
                            subtitle: all.isEmpty
                                ? 'Tocá "Nuevo" para crear tu primer producto. ¡Aparecerá en la web al instante!'
                                : 'Probá con otra búsqueda.',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) => _ProductTile(
                              product: list[i],
                              category: catById[list[i].categoryId],
                              onTap: () => _open(list[i]),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip(String label, String? value, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label · $count'),
        selected: _category == value,
        showCheckmark: false,
        onSelected: (_) => setState(() => _category = value),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.category, required this.onTap});
  final Product product;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(opacity: p.active ? 1 : 0.45, child: NetImage(p.cover, radius: 0)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (p.featured) _badge('⭐ Destacado', AppColors.butter),
                        if (!p.active) _badge('🙈 Oculto', Colors.white),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: p.active ? 'Ocultar de la web' : 'Mostrar en la web',
                        icon: Icon(p.active ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppColors.pink500, size: 20),
                        onPressed: () async {
                          try {
                            await Repo.instance.setProductActive(p.id, !p.active);
                            showToast(p.active ? 'Oculto de la web' : '¡Visible en la web!', emoji: p.active ? '🙈' : '✨');
                          } catch (e) {
                            showToast('No se pudo cambiar. $e', emoji: '🥺');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(crc(p.price), style: fredoka(size: 17, color: AppColors.pink600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Pill('${p.availability.emoji} ${p.availability.label}', color: p.availability.color),
                    ],
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 4),
                    Text('${category!.emoji} ${category!.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );
}
