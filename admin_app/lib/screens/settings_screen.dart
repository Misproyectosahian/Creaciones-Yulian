import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigator.dart';
import '../config.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/cute_effects.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});
  final User user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _tagline = TextEditingController();
  final _about = TextEditingController();
  final _whatsapp = TextEditingController();
  final _sinpeNumber = TextEditingController();
  final _sinpeName = TextEditingController();
  final _payment = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _tiktok = TextEditingController();
  final _prefix = TextEditingController();
  final _cancelHours = TextEditingController();
  final _newMethod = TextEditingController();
  List<String> _methods = [];

  StreamSubscription<StoreSettings>? _sub;
  bool _loaded = false;
  bool _saving = false;
  bool _testing = false;
  bool? _notificationsOn;

  @override
  void initState() {
    super.initState();
    _sub = Repo.instance.settings().listen((s) {
      if (_loaded) return; // no pisar lo que se está editando
      _fill(s);
    }, onError: (_) {
      if (!_loaded) _fill(StoreSettings());
    });
    _checkNotifications();
  }

  void _fill(StoreSettings s) {
    _storeName.text = s.storeName;
    _tagline.text = s.tagline;
    _about.text = s.aboutText;
    _whatsapp.text = s.whatsapp;
    _sinpeNumber.text = s.sinpeNumber;
    _sinpeName.text = s.sinpeName;
    _payment.text = s.paymentInstructions;
    _instagram.text = s.instagram;
    _facebook.text = s.facebook;
    _tiktok.text = s.tiktok;
    _prefix.text = s.orderPrefix;
    _cancelHours.text = '${s.cancelWindowHours}';
    if (mounted) {
      setState(() {
        _methods = [...s.deliveryMethods];
        _loaded = true;
      });
    }
  }

  Future<void> _checkNotifications() async {
    final on = await NotificationService.instance.notificationsAllowed();
    if (mounted) setState(() => _notificationsOn = on);
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final c in [_storeName, _tagline, _about, _whatsapp, _sinpeNumber, _sinpeName, _payment, _instagram, _facebook, _tiktok, _prefix, _cancelHours, _newMethod]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMethod() {
    final m = _newMethod.text.trim();
    if (m.isEmpty) return;
    if (!_methods.any((e) => e.toLowerCase() == m.toLowerCase())) {
      setState(() => _methods.add(m));
    }
    _newMethod.clear();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_newMethod.text.trim().isNotEmpty) _addMethod();
    if (_methods.isEmpty) {
      showToast('Agregá al menos una forma de entrega', emoji: '🚚');
      return;
    }
    setState(() => _saving = true);
    try {
      await Repo.instance.saveSettings(StoreSettings(
        storeName: _storeName.text,
        tagline: _tagline.text,
        aboutText: _about.text,
        whatsapp: _whatsapp.text,
        sinpeNumber: _sinpeNumber.text,
        sinpeName: _sinpeName.text,
        paymentInstructions: _payment.text,
        deliveryMethods: _methods,
        instagram: _instagram.text,
        facebook: _facebook.text,
        tiktok: _tiktok.text,
        orderPrefix: _prefix.text.isEmpty ? 'CY' : _prefix.text,
        cancelWindowHours: (int.tryParse(_cancelHours.text) ?? 24).clamp(0, 168),
      ));
      Effects.confetti();
      showToast('¡Ajustes guardados! La web ya se actualizó', emoji: '✨');
    } catch (e) {
      showToast('No se pudo guardar. $e', emoji: '🥺');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testPush() async {
    setState(() => _testing = true);
    try {
      await NotificationService.instance.registerDevice(widget.user.uid);
      final sent = await ApiService.sendTestPush();
      showToast(
        sent > 0 ? 'Notificación enviada a $sent celular${sent == 1 ? '' : 'es'}' : 'No hay celulares registrados todavía',
        emoji: sent > 0 ? '🔔' : '🥺',
      );
    } catch (e) {
      showToast('$e', emoji: '🥺');
    } finally {
      _checkNotifications();
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Cerrar sesión',
      message: 'Este celular dejará de recibir notificaciones de pedidos nuevos hasta que vuelvas a ingresar.',
      confirm: 'Cerrar sesión',
    );
    if (!ok) return;
    await NotificationService.instance.unregisterDevice();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _openWeb() async {
    try {
      await launchUrl(Uri.parse(AppConfig.apiBaseUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      showToast('No se pudo abrir la página', emoji: '🥺');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes ⚙️')),
      body: !_loaded
          ? const CenteredLoader()
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  SectionCard(
                    title: 'Notificaciones',
                    icon: '🔔',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _notificationsOn == null
                              ? 'Revisando...'
                              : (_notificationsOn!
                                  ? 'Activadas ✅ Te avisaremos de cada pedido nuevo.'
                                  : 'Desactivadas 😿 Activalas en los ajustes del celular para enterarte de los pedidos.'),
                          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _testing ? null : _testPush,
                          icon: _testing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                              : const Icon(Icons.notifications_active_rounded),
                          label: const Text('Enviar notificación de prueba'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Tienda',
                    icon: '🏪',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _storeName,
                          maxLength: 60,
                          decoration: const InputDecoration(labelText: 'Nombre de la tienda'),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Escribí el nombre' : null,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _tagline,
                          maxLength: 120,
                          decoration: const InputDecoration(labelText: 'Frase de bienvenida'),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _about,
                          minLines: 2,
                          maxLines: 6,
                          maxLength: 800,
                          decoration: const InputDecoration(
                            labelText: 'Sobre mí (aparece en la web)',
                            alignLabelWithHint: true,
                            hintText: 'Contale a tus clientes quién sos y cómo hacés tus creaciones 💕',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Pagos (SINPE Móvil)',
                    icon: '💸',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _sinpeNumber,
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                          decoration: const InputDecoration(labelText: 'Número de SINPE Móvil', hintText: '8888-8888'),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _sinpeName,
                          maxLength: 60,
                          decoration: const InputDecoration(labelText: 'A nombre de'),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _payment,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: 500,
                          decoration: const InputDecoration(labelText: 'Instrucciones de pago', alignLabelWithHint: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Formas de entrega',
                    icon: '🚚',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final m in _methods)
                              InputChip(label: Text(m), onDeleted: () => setState(() => _methods.remove(m))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newMethod,
                                onSubmitted: (_) => _addMethod(),
                                decoration: const InputDecoration(hintText: 'Agregar forma de entrega'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addMethod,
                              icon: const Icon(Icons.add_rounded),
                              style: IconButton.styleFrom(backgroundColor: AppColors.pink500, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Contacto y redes',
                    icon: '📱',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _whatsapp,
                          keyboardType: TextInputType.phone,
                          maxLength: 15,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp de la tienda',
                            hintText: '8888-8888',
                            prefixIcon: Icon(Icons.chat_rounded),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _instagram,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(labelText: 'Instagram (enlace)', hintText: 'https://instagram.com/...'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _facebook,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(labelText: 'Facebook (enlace)'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tiktok,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(labelText: 'TikTok (enlace)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Cancelaciones',
                    icon: '⏳',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tiempo que tiene el cliente para cancelar su pedido después de hacerlo. '
                          'Pasado ese tiempo ya no puede cancelarlo. Se muestra en la web con una cuenta regresiva.',
                          style: TextStyle(color: AppColors.muted, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final (hours, label) in const [(0, '🔒 No se puede'), (12, '12 h'), (24, '24 h'), (48, '48 h')])
                              ChoiceChip(
                                label: Text(label),
                                selected: _cancelHours.text == '$hours',
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _cancelHours.text = '$hours'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cancelHours,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Horas para cancelar',
                            suffixText: 'horas',
                            helperText: 'Poné 0 si los pedidos no se pueden cancelar. Máximo 168 (7 días).',
                            helperMaxLines: 2,
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null) return 'Escribí un número de horas';
                            if (n > 168) return 'Máximo 168 horas (7 días)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Solo se puede cancelar mientras el pedido esté "Pendiente de pago" o "Pago recibido". '
                          'Si cambiás este tiempo, aplica a los pedidos nuevos.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Pedidos',
                    icon: '🧾',
                    child: TextFormField(
                      controller: _prefix,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z]'))],
                      decoration: const InputDecoration(
                        labelText: 'Prefijo del número de pedido',
                        helperText: 'Ej: CY → los pedidos serán CY-0001, CY-0002...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Guardando...' : 'Guardar ajustes'),
                  ),
                  const SizedBox(height: 26),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Text('🌐', style: TextStyle(fontSize: 24)),
                          title: const Text('Abrir la tienda web', style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(AppConfig.apiBaseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: _openWeb,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Text('👩‍💼', style: TextStyle(fontSize: 24)),
                          title: Text(widget.user.email ?? 'Administradora', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: const Text('Cerrar sesión'),
                          trailing: const Icon(Icons.logout_rounded, color: AppColors.pink500),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(child: Text('Hecho con 💖 para Creaciones Yulian', style: pacifico(size: 14, color: AppColors.pink400))),
                ],
              ),
            ),
    );
  }
}
