import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../models/models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/cute_effects.dart';

const _emojiChoices = ['🌸', '🌷', '💐', '🌹', '🌻', '🌼', '🧶', '🧸', '🐰', '🐻', '🦋', '🍓', '🎀', '💖', '🎁', '✨', '👜', '🔑', '🍄', '🐝'];

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Stream<List<Category>> _categories = Repo.instance.categories();
  late final Stream<List<Product>> _products = Repo.instance.products();
  List<Category>? _localOrder;

  Future<void> _edit([Category? category, int nextOrder = 0]) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(category: category, nextOrder: nextOrder),
    );
    if (result == null) return;
    try {
      await Repo.instance.saveCategory(result);
      Effects.confetti();
      showToast(category == null ? '¡Catálogo creado!' : 'Catálogo actualizado', emoji: result.emoji);
    } catch (e) {
      showToast('No se pudo guardar. $e', emoji: '🥺');
    }
  }

  Future<void> _delete(Category c, int productCount) async {
    final ok = await confirmDialog(
      context,
      title: 'Eliminar catálogo',
      message: productCount > 0
          ? 'El catálogo "${c.name}" tiene $productCount producto${productCount == 1 ? '' : 's'}. Si lo eliminás, esos productos quedarán "sin catálogo" (no se borran).'
          : '¿Eliminar el catálogo "${c.name}"?',
      confirm: 'Eliminar',
      danger: true,
    );
    if (!ok) return;
    try {
      await Repo.instance.deleteCategory(c.id);
      showToast('Catálogo eliminado', emoji: '🗑️');
    } catch (e) {
      showToast('No se pudo eliminar. $e', emoji: '🥺');
    }
  }

  Future<void> _reorder(List<Category> list, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = [...list];
    updated.insert(newIndex, updated.removeAt(oldIndex));
    setState(() => _localOrder = updated);
    try {
      await Repo.instance.reorderCategories(updated);
    } catch (e) {
      showToast('No se pudo guardar el orden. $e', emoji: '🥺');
    } finally {
      if (mounted) setState(() => _localOrder = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: _categories,
      builder: (context, snap) {
        final categories = _localOrder ?? snap.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Catálogos 🗂️')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(null, categories?.length ?? 0),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: Builder(
            builder: (context) {
              if (snap.hasError) return ErrorState(error: snap.error);
              if (categories == null) return const CenteredLoader();
              if (categories.isEmpty) {
                return const EmptyState(
                  emoji: '🗂️',
                  title: 'Sin catálogos todavía',
                  subtitle: 'Los catálogos agrupan tus productos en la web.\nEj: Ramos eternos, Amigurumis, Llaveros, Flores.',
                );
              }
              return StreamBuilder<List<Product>>(
                stream: _products,
                builder: (context, ps) {
                  final products = ps.data ?? const <Product>[];
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: categories.length,
                    header: const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Mantené presionado y arrastrá para cambiar el orden en la web ✨',
                        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                    onReorder: (a, b) => _reorder(categories, a, b),
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final count = products.where((p) => p.categoryId == c.id).length;
                      return Padding(
                        key: ValueKey(c.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                            leading: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient),
                              child: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                            ),
                            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              c.description.isEmpty ? '$count producto${count == 1 ? '' : 's'}' : '$count · ${c.description}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _edit(c),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _delete(c, count),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
                                ),
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.drag_indicator_rounded, color: AppColors.pink300),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category, required this.nextOrder});
  final Category? category;
  final int nextOrder;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _description = TextEditingController(text: widget.category?.description ?? '');
  late String _emoji = widget.category?.emoji ?? '🌸';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final c = widget.category;
    Navigator.pop(
      context,
      Category(
        id: c?.id ?? '',
        name: _name.text,
        emoji: _emoji,
        description: _description.text,
        order: c?.order ?? widget.nextOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nuevo catálogo' : 'Editar catálogo'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient),
                  child: Text(_emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final e in _emojiChoices)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e == _emoji ? AppColors.pink100 : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                autofocus: widget.category == null,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Ej: Ramos eternos'),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Escribí un nombre' : null,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Descripción corta (opcional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
