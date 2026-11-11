import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, handler, HttpError, json, notifyAdmins, readJson, requireUser } from '../lib/server';

/**
 * El cliente cancela su pedido. Solo se permite:
 *  - si el pedido es suyo,
 *  - dentro del plazo de cancelación guardado en el pedido (cancelDeadline),
 *  - y mientras el pedido no haya empezado a hacerse (pendiente de pago o pago recibido).
 * La hora la decide el servidor, así que no se puede hacer trampa con el reloj.
 */

const CANCELABLE_STATUSES = ['pendiente_pago', 'pago_recibido'];

export default handler(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  const orderId = typeof body.orderId === 'string' ? body.orderId.trim() : '';
  if (!orderId || orderId.length > 128 || orderId.includes('/')) {
    throw new HttpError(400, 'Pedido inválido.');
  }

  const firestore = db();
  const ref = firestore.collection('orders').doc(orderId);

  const order = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const o = snap.data();
    // Si no es suyo respondemos igual que si no existiera (no revelamos pedidos ajenos)
    if (!snap.exists || !o || o.userId !== user.uid) throw new HttpError(404, 'No encontramos este pedido.');
    if (o.status === 'cancelado') throw new HttpError(409, 'Este pedido ya estaba cancelado.');
    if (!CANCELABLE_STATUSES.includes(o.status)) {
      throw new HttpError(409, 'Tu pedido ya se está haciendo, por eso ya no se puede cancelar. Si necesitás ayuda, escribinos por WhatsApp 💕');
    }
    const deadline = o.cancelDeadline instanceof Timestamp ? o.cancelDeadline.toMillis() : 0;
    if (!deadline) throw new HttpError(409, 'Este pedido no se puede cancelar.');
    if (Date.now() > deadline) throw new HttpError(409, 'El plazo para cancelar este pedido ya terminó.');

    tx.update(ref, {
      status: 'cancelado',
      statusHistory: FieldValue.arrayUnion({ status: 'cancelado', at: Timestamp.now() }),
      cancelledBy: 'cliente',
      cancelledAt: FieldValue.serverTimestamp(),
      seen: false,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return o;
  });

  try {
    const name = typeof order.customer?.name === 'string' ? order.customer.name : 'Un cliente';
    await notifyAdmins({
      title: `❌ Pedido ${order.orderNumber ?? ''} cancelado`,
      body: `${name} canceló su pedido dentro del plazo permitido.`,
      data: { orderId, type: 'order_cancelled' },
    });
  } catch (e) {
    console.error('No se pudo enviar la notificación de cancelación', e);
  }

  return json({ ok: true });
});
