import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, handler, HttpError, json, notifyAdmins, readJson, requireUser } from '../lib/server';

/**
 * Crea un pedido de forma segura:
 *  - verifica la sesión del cliente
 *  - toma los precios y adelantos REALES desde la base de datos (no del navegador)
 *  - asigna un número de pedido consecutivo (CY-0001, CY-0002...)
 *  - avisa a la app de administración con una notificación push
 */

const MAX_ITEMS = 30;
const MAX_QTY = 20;

const str = (v: unknown, max: number): string => (typeof v === 'string' ? v.trim().slice(0, max) : '');
const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

const crc = (n: number) => '₡' + Math.round(n).toLocaleString('es-CR');

interface InItem {
  productId: string;
  qty: number;
  option: string;
  note: string;
}

function parseItems(raw: unknown): InItem[] {
  if (!Array.isArray(raw) || raw.length === 0) throw new HttpError(400, 'Tu carrito está vacío.');
  if (raw.length > MAX_ITEMS) throw new HttpError(400, `Máximo ${MAX_ITEMS} productos distintos por pedido.`);
  return raw.map((r) => {
    const o = (r && typeof r === 'object' ? r : {}) as Record<string, unknown>;
    const productId = str(o.productId, 128);
    const qty = Math.floor(num(o.qty));
    if (!productId || productId.includes('/')) throw new HttpError(400, 'Hay un producto inválido en el carrito.');
    if (qty < 1 || qty > MAX_QTY) throw new HttpError(400, `La cantidad de cada producto debe ser entre 1 y ${MAX_QTY}.`);
    return { productId, qty, option: str(o.option, 60), note: str(o.note, 300) };
  });
}

export default handler(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  const items = parseItems(body.items);
  const deliveryMethod = str(body.deliveryMethod, 60);
  const deliveryDetails = str(body.deliveryDetails, 500);
  const customerNotes = str(body.customerNotes, 800);
  const neededByRaw = str(body.neededBy, 10);
  const neededBy = /^\d{4}-\d{2}-\d{2}$/.test(neededByRaw) ? neededByRaw : '';

  const firestore = db();

  // Perfil del cliente (se guarda una copia en el pedido)
  const [profileSnap, settingsSnap] = await Promise.all([
    firestore.collection('users').doc(user.uid).get(),
    firestore.collection('settings').doc('store').get(),
  ]);
  const profile = profileSnap.data() ?? {};
  const customer = {
    name: str(profile.name, 80),
    phone: str(profile.phone, 20),
    email: str(user.email ?? profile.email, 120),
    province: str(profile.province, 40),
    canton: str(profile.canton, 60),
    district: str(profile.district, 60),
    address: str(profile.address, 400),
  };
  if (customer.name.length < 3 || customer.phone.replace(/\D/g, '').length < 8) {
    throw new HttpError(400, 'Completá tu nombre y teléfono en "Mi cuenta" antes de hacer el pedido.');
  }

  const settings = settingsSnap.data() ?? {};
  const methods: string[] = Array.isArray(settings.deliveryMethods)
    ? settings.deliveryMethods.filter((m: unknown): m is string => typeof m === 'string' && m.trim() !== '')
    : [];
  if (!deliveryMethod) throw new HttpError(400, 'Elegí una forma de entrega.');
  if (methods.length > 0 && !methods.includes(deliveryMethod)) {
    throw new HttpError(400, 'La forma de entrega elegida ya no está disponible. Elegí otra.');
  }
  const prefix = (str(settings.orderPrefix, 5).replace(/[^A-Za-z]/g, '') || 'CY').toUpperCase();

  // Evitar pedidos repetidos por error (máx. 3 cada 10 minutos)
  const recent = await firestore.collection('orders').where('userId', '==', user.uid).get();
  const tenMinutesAgo = Date.now() - 10 * 60 * 1000;
  const recentCount = recent.docs.filter((d) => {
    const created = d.get('createdAt');
    return created instanceof Timestamp && created.toMillis() > tenMinutesAgo;
  }).length;
  if (recentCount >= 3) {
    throw new HttpError(429, 'Hiciste varios pedidos seguidos. Esperá unos minutos o escribinos por WhatsApp 💕');
  }

  // Precios reales desde la base de datos
  const uniqueIds = [...new Set(items.map((i) => i.productId))];
  const productSnaps = await firestore.getAll(...uniqueIds.map((id) => firestore.collection('products').doc(id)));
  const products = new Map(productSnaps.map((s) => [s.id, s]));

  const orderItems = items.map((item) => {
    const snap = products.get(item.productId);
    const p = snap?.data();
    if (!snap?.exists || !p || p.active !== true) {
      throw new HttpError(409, 'Uno de los productos de tu carrito ya no está disponible. Revisá tu carrito.');
    }
    const name = str(p.name, 80) || 'Producto';
    if (p.availability === 'agotado') throw new HttpError(409, `"${name}" está agotado. Quitalo del carrito para continuar.`);
    const options: string[] = Array.isArray(p.options) ? p.options.filter((o: unknown): o is string => typeof o === 'string') : [];
    if (options.length > 0 && !options.includes(item.option)) {
      throw new HttpError(400, `Elegí una opción válida para "${name}".`);
    }
    const price = Math.max(0, Math.round(num(p.price)));
    const minDeposit = Math.min(price, Math.max(0, Math.round(num(p.minDeposit))));
    const images: unknown[] = Array.isArray(p.images) ? p.images : [];
    const image = typeof images[0] === 'string' ? images[0] : '';
    return {
      productId: item.productId,
      name,
      image,
      price,
      minDeposit,
      qty: item.qty,
      option: options.length > 0 ? item.option : '',
      note: item.note,
      subtotal: price * item.qty,
    };
  });

  const total = orderItems.reduce((s, i) => s + i.subtotal, 0);
  const minDeposit = orderItems.reduce((s, i) => s + i.minDeposit * i.qty, 0);
  const itemCount = orderItems.reduce((s, i) => s + i.qty, 0);

  // Número consecutivo + creación del pedido (en una sola transacción)
  const counterRef = firestore.collection('counters').doc('orders');
  const orderRef = firestore.collection('orders').doc();
  const orderNumber = await firestore.runTransaction(async (tx) => {
    const counter = await tx.get(counterRef);
    const next = (counter.exists ? Math.floor(num(counter.get('value'))) : 0) + 1;
    const number = `${prefix}-${String(next).padStart(4, '0')}`;
    tx.set(counterRef, { value: next }, { merge: true });
    tx.set(orderRef, {
      orderNumber: number,
      number: next,
      userId: user.uid,
      customer,
      items: orderItems,
      itemCount,
      total,
      minDeposit,
      amountPaid: 0,
      status: 'pendiente_pago',
      statusHistory: [{ status: 'pendiente_pago', at: Timestamp.now() }],
      deliveryMethod,
      deliveryDetails,
      neededBy,
      customerNotes,
      adminMessage: '',
      seen: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return number;
  });

  // Aviso a la app (si falla, el pedido igual queda creado)
  try {
    await notifyAdmins({
      title: `🧶 ¡Nuevo pedido ${orderNumber}!`,
      body: `${customer.name} · ${itemCount} ${itemCount === 1 ? 'producto' : 'productos'} · ${crc(total)}`,
      data: { orderId: orderRef.id, type: 'new_order' },
    });
  } catch (e) {
    console.error('No se pudo enviar la notificación', e);
  }

  return json({ id: orderRef.id, orderNumber });
});
