import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigator.dart';
import '../config.dart';
import '../models/models.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/cute_effects.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<ShopOrder?> _order = Repo.instance.order(widget.orderId);
  StreamSubscription<StoreSettings>? _settingsSub;
  StoreSettings _settings = StoreSettings();
  final _message = TextEditingController();
  bool _messageLoaded = false;
  bool _savingMessage = false;
  bool _markedSeen = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settingsSub = Repo.instance.settings().listen((s) => _settings = s, onError: (_) {});
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _message.dispose();
    super.dispose();
  }

  // ── Acciones ──

  Future<void> _launch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) showToast('No se pudo abrir la aplicación', emoji: '🥺');
    } catch (_) {
      showToast('No se pudo abrir la aplicación', emoji: '🥺');
    }
  }

  void _whatsApp(ShopOrder o, [String? text]) {
    final phone = whatsappNumber(o.customer.phone);
    if (phone.isEmpty) {
      showToast('Este pedido no tiene teléfono', emoji: '🥺');
      return;
    }
    final query = text == null ? '' : '?text=${Uri.encodeComponent(text)}';
    _launch(Uri.parse('https://wa.me/$phone$query'));
  }

  String _statusMessage(ShopOrder o, OrderStatus s) {
    final name = o.customer.firstName.isEmpty ? '' : ' ${o.customer.firstName}';
    final n = o.orderNumber;
    final String body;
    switch (s) {
      case OrderStatus.pendientePago:
        final sinpe = _settings.sinpeNumber.isEmpty
            ? ''
            : ' al SINPE Móvil ${_settings.sinpeNumber}${_settings.sinpeName.isEmpty ? '' : ' (${_settings.sinpeName})'}';
        body = 'Hola$name 💖 ¡Gracias por tu pedido $n! Para confirmarlo, el adelanto mínimo es de ${crc(o.minDeposit)}$sinpe. Cuando lo hagás, enviame el comprobante por aquí 🙏';
      case OrderStatus.pagoRecibido:
        body = 'Hola$name 💖 ¡Recibí tu pago del pedido $n! (${crc(o.amountPaid)} de ${crc(o.total)}). Muy pronto empiezo a trabajar en él ✨';
      case OrderStatus.enProceso:
        body = 'Hola$name 🧶 Tu pedido $n ya está en proceso, ¡lo estoy haciendo con mucho amor!';
      case OrderStatus.listo:
        final saldo = o.balance > 0 ? ' El saldo pendiente es de ${crc(o.balance)}.' : '';
        body = 'Hola$name 🎁 ¡Tu pedido $n está listo!$saldo Coordinemos la entrega 💕';
      case OrderStatus.enCamino:
        body = 'Hola$name 🚗 Tu pedido $n va en camino. ¡Ya casi lo tenés!';
      case OrderStatus.entregado:
        body = 'Hola$name 🌸 ¡Gracias por tu compra! Espero que amés tu pedido $n. Si podés, compartí una fotito y etiquetame 💖';
      case OrderStatus.cancelado:
        body = 'Hola$name, tu pedido $n fue cancelado. Cualquier duda, con gusto te ayudo 💕';
    }
    return '$body\n\nSeguí tu pedido aquí: ${AppConfig.orderTrackingUrl(o.id)}';
  }

  Future<void> _changeStatus(ShopOrder o, OrderStatus s, {bool ask = true}) async {
    if (s == o.status || _busy) return;
    if (ask) {
      final ok = await confirmDialog(
        context,
        title: '${s.emoji} ${s.label}',
        message: '¿Cambiar el pedido ${o.orderNumber} a "${s.label}"?\nEl cliente lo va a ver en la web.',
        confirm: 'Cambiar',
        danger: s == OrderStatus.cancelado,
      );
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await Repo.instance.updateStatus(o.id, s);
      if (s != OrderStatus.cancelado) Effects.confetti();
      showToast(
        'Ahora está: ${s.label}',
        emoji: s.emoji,
        action: SnackBarAction(label: 'Avisar 💬', onPressed: () => _whatsApp(o, _statusMessage(o, s))),
      );
    } catch (e) {
      showToast('No se pudo cambiar el estado. $e', emoji: '🥺');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _registerPayment(ShopOrder o) async {
    final amount = await showDialog<int>(context: context, builder: (_) => _PaymentDialog(order: o));
    if (amount == null || !mounted) return;
    try {
      await Repo.instance.setAmountPaid(o.id, amount);
      Effects.confetti();
      showToast('Pago registrado: ${crc(amount)}', emoji: '💰');
      if (amount > 0 && o.status == OrderStatus.pendientePago && mounted) {
        final mark = await confirmDialog(
          context,
          title: '💖 ¿Pago recibido?',
          message: '¿Querés cambiar el estado del pedido a "Pago recibido"?',
          confirm: 'Sí, cambiar',
          cancel: 'Ahora no',
        );
        if (mark) await _changeStatus(o, OrderStatus.pagoRecibido, ask: false);
      }
    } catch (e) {
      showToast('No se pudo guardar el pago. $e', emoji: '🥺');
    }
  }

  Future<void> _saveMessage(ShopOrder o) async {
    setState(() => _savingMessage = true);
    try {
      await Repo.instance.setAdminMessage(o.id, _message.text);
      showToast('Mensaje guardado, el cliente lo verá en la web', emoji: '💌');
    } catch (e) {
      showToast('No se pudo guardar el mensaje. $e', emoji: '🥺');
    } finally {
      if (mounted) setState(() => _savingMessage = false);
    }
  }

  Future<void> _delete(ShopOrder o) async {
    final ok = await confirmDialog(
      context,
      title: 'Eliminar pedido',
      message: '¿Seguro que querés eliminar el pedido ${o.orderNumber}? Esto no se puede deshacer.\n\nSi solo no se va a hacer, mejor cambiá el estado a "Cancelado".',
      confirm: 'Eliminar',
      danger: true,
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await Repo.instance.deleteOrder(o.id);
      navigator.pop();
      showToast('Pedido eliminado', emoji: '🗑️');
    } catch (e) {
      showToast('No se pudo eliminar. $e', emoji: '🥺');
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShopOrder?>(
      stream: _order,
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(appBar: AppBar(), body: ErrorState(error: snap.error));
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Scaffold(appBar: AppBar(), body: const CenteredLoader());
        }
        final o = snap.data;
        if (o == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(emoji: '🔍', title: 'Pedido no encontrado', subtitle: 'Puede que haya sido eliminado.'),
          );
        }
        if (!o.seen && !_markedSeen) {
          _markedSeen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => Repo.instance.markSeen(o.id).catchError((_) {}));
        }
        if (!_messageLoaded) {
          _messageLoaded = true;
          _message.text = o.adminMessage;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(o.orderNumber),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) {
                  if (v == 'link') {
                    Clipboard.setData(ClipboardData(text: AppConfig.orderTrackingUrl(o.id)));
                    showToast('Enlace de seguimiento copiado', emoji: '🔗');
                  } else if (v == 'delete') {
                    _delete(o);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'link', child: Text('🔗  Copiar enlace de seguimiento')),
                  PopupMenuItem(value: 'delete', child: Text('🗑️  Eliminar pedido')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              _header(o),
              const SizedBox(height: 14),
              _statusSection(o),
              const SizedBox(height: 14),
              _customerSection(o),
              const SizedBox(height: 14),
              _deliverySection(o),
              const SizedBox(height: 14),
              _itemsSection(o),
              const SizedBox(height: 14),
              _paymentSection(o),
              const SizedBox(height: 14),
              _messageSection(o),
              const SizedBox(height: 14),
              _historySection(o),
            ],
          ),
        );
      },
    );
  }

  Widget _header(ShopOrder o) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.pink200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(o.status),
              const Spacer(),
              Text(timeAgo(o.createdAt), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Text(crc(o.total), style: fredoka(size: 34, color: AppColors.pink600)),
          Text(
            '${o.itemCount} ${o.itemCount == 1 ? 'producto' : 'productos'} · ${formatDate(o.createdAt)}',
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _statusSection(ShopOrder o) {
    return SectionCard(
      title: 'Estado del pedido',
      icon: '📍',
      trailing: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)) : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in OrderStatus.values)
            ChoiceChip(
              label: Text('${s.emoji} ${s.label}'),
              selected: o.status == s,
              showCheckmark: false,
              selectedColor: s.color.withValues(alpha: 0.2),
              side: BorderSide(color: o.status == s ? s.color : AppColors.pink100, width: o.status == s ? 2 : 1),
              onSelected: _busy ? null : (_) => _changeStatus(o, s),
            ),
          const SizedBox(width: double.infinity),
          OutlinedButton.icon(
            onPressed: () => _whatsApp(o, _statusMessage(o, o.status)),
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Avisar estado por WhatsApp'),
          ),
        ],
      ),
    );
  }

  Widget _customerSection(ShopOrder o) {
    final c = o.customer;
    return SectionCard(
      title: 'Cliente',
      icon: '🙋‍♀️',
      child: Column(
        children: [
          InfoRow(icon: Icons.person_rounded, label: 'Nombre', value: c.name),
          InfoRow(icon: Icons.phone_rounded, label: 'Teléfono', value: formatPhone(c.phone)),
          InfoRow(
            icon: Icons.mail_rounded,
            label: 'Correo',
            value: c.email,
            onTap: c.email.isEmpty ? null : () => _launch(Uri(scheme: 'mailto', path: c.email)),
          ),
          InfoRow(icon: Icons.place_rounded, label: 'Ubicación', value: c.location),
          if (c.address.isNotEmpty) InfoRow(icon: Icons.home_rounded, label: 'Dirección / señas', value: c.address),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size(0, 48)),
                  onPressed: () => _whatsApp(o, 'Hola ${c.firstName} 💖 Te escribo de ${_settings.storeName} por tu pedido ${o.orderNumber}.'),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.phone.isEmpty ? null : () => _launch(Uri(scheme: 'tel', path: onlyDigits(c.phone))),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Llamar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deliverySection(ShopOrder o) {
    return SectionCard(
      title: 'Entrega',
      icon: '🚚',
      child: Column(
        children: [
          InfoRow(icon: Icons.local_shipping_rounded, label: 'Forma de entrega', value: o.deliveryMethod),
          if (o.deliveryDetails.isNotEmpty) InfoRow(icon: Icons.map_rounded, label: 'Detalles de entrega', value: o.deliveryDetails),
          if (o.neededBy.isNotEmpty) InfoRow(icon: Icons.event_rounded, label: 'Lo necesita para', value: formatIsoDay(o.neededBy)),
          if (o.customerNotes.isNotEmpty) InfoRow(icon: Icons.sticky_note_2_rounded, label: 'Notas del cliente', value: o.customerNotes),
        ],
      ),
    );
  }

  Widget _itemsSection(ShopOrder o) {
    return SectionCard(
      title: 'Productos',
      icon: '🛍️',
      child: Column(
        children: [
          for (final item in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NetImage(item.image, width: 62, height: 62, radius: 14, thumbWidth: 200),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        if (item.option.isNotEmpty)
                          Text('Opción: ${item.option}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                        if (item.note.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.lilac50, borderRadius: BorderRadius.circular(10)),
                            child: Text('✏️ ${item.note}', style: const TextStyle(fontSize: 13)),
                          ),
                        const SizedBox(height: 2),
                        Text('${item.qty} × ${crc(item.price)}', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(crc(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentSection(ShopOrder o) {
    final progress = o.total <= 0 ? 0.0 : (o.amountPaid / o.total).clamp(0.0, 1.0);
    Widget line(String label, String value, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.ink : AppColors.muted))),
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: bold ? 17 : 15, color: color)),
            ],
          ),
        );
    return SectionCard(
      title: 'Pago',
      icon: '💰',
      child: Column(
        children: [
          line('Total', crc(o.total), bold: true),
          line('Adelanto mínimo', crc(o.minDeposit), color: AppColors.lilac700),
          line('Pagado', crc(o.amountPaid), color: const Color(0xFF2E9B73)),
          line('Saldo pendiente', crc(o.balance), color: o.balance > 0 ? AppColors.pink600 : const Color(0xFF2E9B73)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.pink50,
              color: progress >= 1 ? AppColors.mint : AppColors.pink400,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              progress >= 1
                  ? '¡Pagado completo! 🎉'
                  : (o.depositCovered && o.amountPaid > 0 ? 'Adelanto cubierto ✅' : 'Esperando el adelanto 💌'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _registerPayment(o),
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Registrar pago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageSection(ShopOrder o) {
    return SectionCard(
      title: 'Mensaje para el cliente',
      icon: '💌',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _message,
            maxLines: 4,
            minLines: 2,
            maxLength: 600,
            decoration: const InputDecoration(
              hintText: 'Ej: ¡Tu ramo queda listo el viernes! Te escribo para coordinar 💕',
              helperText: 'Lo verá en la página de seguimiento de su pedido.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _savingMessage ? null : () => _saveMessage(o),
            icon: const Icon(Icons.send_rounded),
            label: Text(_savingMessage ? 'Guardando...' : 'Guardar mensaje'),
          ),
        ],
      ),
    );
  }

  Widget _historySection(ShopOrder o) {
    final events = o.history.reversed.toList();
    return SectionCard(
      title: 'Historial',
      icon: '🕒',
      child: events.isEmpty
          ? const Text('Sin cambios todavía', style: TextStyle(color: AppColors.muted))
          : Column(
              children: [
                for (var i = 0; i < events.length; i++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: events[i].status.color.withValues(alpha: 0.16), shape: BoxShape.circle),
                            child: Text(events[i].status.emoji, style: const TextStyle(fontSize: 15)),
                          ),
                          if (i < events.length - 1) Container(width: 2, height: 22, color: AppColors.pink100),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(events[i].status.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(formatDate(events[i].at), style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.order});
  final ShopOrder order;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.order.amountPaid > 0 ? '${widget.order.amountPaid}' : '',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _set(int v) => setState(() => _amount.text = '$v');

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return AlertDialog(
      title: const Text('Registrar pago 💰'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total del pedido: ${crc(o.total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Escribí el monto TOTAL que ya pagó el cliente (sumando todos los SINPE).', style: TextStyle(color: AppColors.muted, height: 1.35)),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Monto pagado', prefixText: '₡ '),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (o.minDeposit > 0) ActionChip(label: Text('Adelanto ${crc(o.minDeposit)}'), onPressed: () => _set(o.minDeposit)),
                ActionChip(label: Text('Total ${crc(o.total)}'), onPressed: () => _set(o.total)),
                ActionChip(label: const Text('₡0'), onPressed: () => _set(0)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, parseMoney(_amount.text)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
