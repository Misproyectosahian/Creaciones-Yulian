import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_navigator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/cute_effects.dart';

const _maxImages = 10;

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Product? _p = widget.product;
  late final _name = TextEditingController(text: _p?.name ?? '');
  late final _description = TextEditingController(text: _p?.description ?? '');
  late final _price = TextEditingController(text: (_p?.price ?? 0) > 0 ? '${_p!.price}' : '');
  late final _deposit = TextEditingController(text: _p == null ? '' : '${_p.minDeposit}');
  late final _leadTime = TextEditingController(text: _p?.leadTime ?? '');
  late final _optionsLabel = TextEditingController(text: _p?.optionsLabel ?? 'Color');
  final _optionInput = TextEditingController();

  late final List<String> _images = [...?_p?.images];
  late final List<String> _options = [...?_p?.options];
  late String _categoryId = _p?.categoryId ?? '';
  late Availability _availability = _p?.availability ?? Availability.disponible;
  late bool _featured = _p?.featured ?? false;
  late bool _active = _p?.active ?? true;

  late final Stream<List<Category>> _categories = Repo.instance.categories();
  int _uploading = 0;
  bool _saving = false;
  bool _dirty = false;

  bool get _isNew => widget.product == null;

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _deposit, _leadTime, _optionsLabel, _optionInput]) {
      c.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // ── Fotos ──

  Future<void> _chooseSource() async {
    if (_images.length + _uploading >= _maxImages) {
      showToast('Máximo $_maxImages fotos por producto', emoji: '📸');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Agregar fotos', style: fredoka(size: 20)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 26)),
              title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 26)),
              title: const Text('Tomar una foto', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> files;
    try {
      if (source == ImageSource.gallery) {
        files = await picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      } else {
        final f = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
        files = f == null ? <XFile>[] : [f];
      }
    } catch (e) {
      showToast('No se pudo abrir la ${source == ImageSource.camera ? 'cámara' : 'galería'}', emoji: '🥺');
      return;
    }
    if (files.isEmpty || !mounted) return;

    final room = _maxImages - _images.length - _uploading;
    if (files.length > room) {
      showToast('Solo se agregarán $room fotos (máximo $_maxImages)', emoji: '📸');
      files = files.take(room).toList();
    }
    setState(() {
      _uploading += files.length;
      _dirty = true;
    });
    for (final f in files) {
      try {
        final url = await ApiService.uploadImage(f);
        if (!mounted) return;
        setState(() => _images.add(url));
      } catch (e) {
        showToast('$e', emoji: '🥺');
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
  }

  Future<void> _imageActions(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star_rounded, color: AppColors.pink500),
                title: const Text('Usar como portada', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, 'cover'),
              ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back_rounded, color: AppColors.pink500),
                title: const Text('Mover a la izquierda', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, 'left'),
              ),
            if (index < _images.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_forward_rounded, color: AppColors.pink500),
                title: const Text('Mover a la derecha', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, 'right'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD9534F)),
              title: const Text('Quitar foto', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD9534F))),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    setState(() {
      _dirty = true;
      switch (action) {
        case 'cover':
          _images.insert(0, _images.removeAt(index));
        case 'left':
          _images.insert(index - 1, _images.removeAt(index));
        case 'right':
          _images.insert(index + 1, _images.removeAt(index));
        case 'delete':
          _images.removeAt(index);
      }
    });
  }

  // ── Opciones ──

  void _addOptions() {
    final parts = _optionInput.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    var added = false;
    for (final part in parts) {
      if (!_options.any((o) => o.toLowerCase() == part.toLowerCase()) && _options.length < 30) {
        _options.add(part);
        added = true;
      }
    }
    _optionInput.clear();
    if (added) setState(() => _dirty = true);
  }

  void _setDepositPercent(double pct) {
    final price = parseMoney(_price.text);
    if (price <= 0) {
      showToast('Primero escribí el precio', emoji: '💰');
      return;
    }
    final value = ((price * pct) / 100).round() * 100;
    setState(() {
      _deposit.text = '${value.clamp(0, price)}';
      _dirty = true;
    });
  }

  // ── Guardar ──

  Future<void> _save() async {
    if (_uploading > 0) {
      showToast('Esperá a que terminen de subir las fotos', emoji: '⏳');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) {
      showToast('Revisá los campos marcados', emoji: '✏️');
      return;
    }
    if (_optionInput.text.trim().isNotEmpty) _addOptions();

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name.text,
      description: _description.text,
      price: parseMoney(_price.text),
      minDeposit: parseMoney(_deposit.text),
      categoryId: _categoryId,
      images: _images,
      options: _options,
      optionsLabel: _optionsLabel.text,
      availability: _availability,
      leadTime: _leadTime.text,
      featured: _featured,
      active: _active,
      createdAt: widget.product?.createdAt,
    );

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await Repo.instance.saveProduct(product);
      _dirty = false;
      Effects.confetti();
      showToast(
        _isNew ? (_active ? '¡Producto creado! Ya está en la web' : 'Producto creado (oculto)') : 'Cambios guardados',
        emoji: '🎉',
      );
      navigator.pop();
    } catch (e) {
      showToast('No se pudo guardar. $e', emoji: '🥺');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final p = widget.product;
    if (p == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Eliminar producto',
      message: '¿Seguro que querés eliminar "${p.name}"? Ya no aparecerá en la web.\n\nTip: si solo querés esconderlo un tiempo, apagá "Visible en la web".',
      confirm: 'Eliminar',
      danger: true,
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await Repo.instance.deleteProduct(p.id);
      _dirty = false;
      navigator.pop();
      showToast('Producto eliminado', emoji: '🗑️');
    } catch (e) {
      showToast('No se pudo eliminar. $e', emoji: '🥺');
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await confirmDialog(
          context,
          title: '¿Salir sin guardar?',
          message: 'Tenés cambios sin guardar en este producto.',
          confirm: 'Salir',
          cancel: 'Seguir editando',
        );
        if (leave) {
          _dirty = false;
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Nuevo producto ✨' : 'Editar producto'),
          actions: [
            if (!_isNew)
              IconButton(
                tooltip: 'Eliminar',
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        body: Form(
          key: _form,
          onChanged: _touch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              _photos(),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Información',
                icon: '📝',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 80,
                      decoration: const InputDecoration(labelText: 'Nombre del producto', hintText: 'Ej: Ramo de girasoles eternos'),
                      validator: (v) => (v ?? '').trim().length < 2 ? 'Escribí el nombre' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 8,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Materiales, tamaño, colores, cuidados...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Precio y adelanto',
                icon: '💰',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '₡ '),
                      validator: (v) => parseMoney(v ?? '') <= 0 ? 'Escribí el precio' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _deposit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Monto mínimo de adelanto',
                        prefixText: '₡ ',
                        helperText: 'Lo que se debe adelantar por SINPE (por unidad).\nPoné 0 si no pedís adelanto.',
                        helperMaxLines: 3,
                      ),
                      validator: (v) {
                        final deposit = parseMoney(v ?? '');
                        final price = parseMoney(_price.text);
                        if ((v ?? '').trim().isEmpty) return 'Escribí el adelanto (o 0)';
                        if (price > 0 && deposit > price) return 'No puede ser mayor que el precio';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(label: const Text('Sin adelanto'), onPressed: () => _setDepositPercent(0)),
                        ActionChip(label: const Text('25%'), onPressed: () => _setDepositPercent(0.25)),
                        ActionChip(label: const Text('50%'), onPressed: () => _setDepositPercent(0.5)),
                        ActionChip(label: const Text('100%'), onPressed: () => _setDepositPercent(1)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _categoryAndAvailability(),
              const SizedBox(height: 14),
              _optionsSection(),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Visibilidad',
                icon: '👀',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (v) => setState(() {
                        _active = v;
                        _dirty = true;
                      }),
                      title: const Text('Visible en la web', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('Apagalo para esconderlo sin borrarlo'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _featured,
                      onChanged: (v) => setState(() {
                        _featured = v;
                        _dirty = true;
                      }),
                      title: const Text('Destacado ⭐', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('Aparece en la portada de la web'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Icon(Icons.favorite_rounded),
                  label: Text(_saving ? 'Guardando...' : (_isNew ? 'Crear producto' : 'Guardar cambios')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photos() {
    return SectionCard(
      title: 'Fotos',
      icon: '📸',
      trailing: Text('${_images.length}/$_maxImages', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
      child: SizedBox(
        height: 112,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < _images.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => _imageActions(i),
                  child: Stack(
                    children: [
                      NetImage(_images[i], width: 108, height: 108, radius: 18, thumbWidth: 300),
                      if (i == 0)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                            child: const Text('⭐ Portada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            for (var i = 0; i < _uploading; i++)
              Container(
                width: 108,
                height: 108,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(18)),
                child: const Center(child: HeartLoader(size: 30, label: 'Subiendo')),
              ),
            if (_images.length + _uploading < _maxImages)
              InkWell(
                onTap: _chooseSource,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppColors.pink50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.pink300, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, color: AppColors.pink500, size: 30),
                      SizedBox(height: 6),
                      Text('Agregar', style: TextStyle(color: AppColors.pink600, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryAndAvailability() {
    return SectionCard(
      title: 'Catálogo y disponibilidad',
      icon: '🗂️',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Category>>(
            stream: _categories,
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final categories = snap.data!;
              final exists = categories.any((c) => c.id == _categoryId);
              final value = exists ? _categoryId : '';
              return DropdownButtonFormField<String>(
                key: ValueKey('cats-${categories.map((c) => c.id).join(',')}'),
                initialValue: value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Catálogo',
                  helperText: categories.isEmpty ? 'Creá catálogos en la pestaña "Catálogos"' : null,
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('📦 Sin catálogo')),
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}')),
                ],
                onChanged: (v) => setState(() {
                  _categoryId = v ?? '';
                  _dirty = true;
                }),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Disponibilidad', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Availability>(
              showSelectedIcon: false,
              segments: [
                for (final a in Availability.values)
                  ButtonSegment(value: a, label: Text('${a.emoji} ${a.label}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
              ],
              selected: {_availability},
              onSelectionChanged: (s) => setState(() {
                _availability = s.first;
                _dirty = true;
              }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.pink100,
                selectedForegroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.pink200),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _leadTime,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Tiempo de elaboración (opcional)',
              hintText: 'Ej: 5 a 7 días',
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsSection() {
    return SectionCard(
      title: 'Opciones (opcional)',
      icon: '🎨',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Si el producto viene en varios colores o tamaños, agregalos aquí y el cliente elegirá uno.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _optionsLabel,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Nombre de la opción', hintText: 'Ej: Color, Tamaño'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionInput,
                  onSubmitted: (_) => _addOptions(),
                  decoration: const InputDecoration(hintText: 'Ej: Rosado, Lila, Blanco'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addOptions,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.pink500, foregroundColor: Colors.white),
              ),
            ],
          ),
          if (_options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final o in _options)
                  InputChip(
                    label: Text(o),
                    onDeleted: () => setState(() {
                      _options.remove(o);
                      _dirty = true;
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
