import type {
  Availability,
  Category,
  Order,
  OrderItem,
  OrderStatus,
  Product,
  StatusEvent,
  StoreSettings,
  UserProfile,
} from './types';

// Lectura segura de documentos de Firestore: si falta un campo, se usa un valor por defecto.

type Data = Record<string, unknown>;

const str = (v: unknown, fallback = ''): string => (typeof v === 'string' ? v : fallback);
const num = (v: unknown, fallback = 0): number => (typeof v === 'number' && Number.isFinite(v) ? v : fallback);
const strList = (v: unknown): string[] =>
  Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string' && x.trim() !== '') : [];
const obj = (v: unknown): Data => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Data) : {});

export function toMillis(v: unknown): number | null {
  if (v && typeof v === 'object' && 'toMillis' in v && typeof (v as { toMillis: unknown }).toMillis === 'function') {
    return (v as { toMillis: () => number }).toMillis();
  }
  if (typeof v === 'number') return v;
  return null;
}

const AVAILABILITY: Availability[] = ['disponible', 'encargo', 'agotado'];
const STATUSES: OrderStatus[] = ['pendiente_pago', 'pago_recibido', 'en_proceso', 'listo', 'en_camino', 'entregado', 'cancelado'];

export function parseProduct(id: string, d: Data): Product {
  const availability = AVAILABILITY.includes(d.availability as Availability) ? (d.availability as Availability) : 'disponible';
  return {
    id,
    name: str(d.name, 'Producto'),
    description: str(d.description),
    price: Math.max(0, Math.round(num(d.price))),
    minDeposit: Math.max(0, Math.round(num(d.minDeposit))),
    categoryId: str(d.categoryId),
    images: strList(d.images),
    options: strList(d.options),
    optionsLabel: str(d.optionsLabel, 'Opción') || 'Opción',
    availability,
    leadTime: str(d.leadTime),
    featured: d.featured === true,
    createdAt: toMillis(d.createdAt) ?? 0,
  };
}

export function parseCategory(id: string, d: Data): Category {
  return {
    id,
    name: str(d.name, 'Catálogo'),
    emoji: str(d.emoji, '🌸') || '🌸',
    description: str(d.description),
    order: num(d.order),
  };
}

export const DEFAULT_SETTINGS: StoreSettings = {
  storeName: 'Creaciones Yulian',
  tagline: 'Crochet, ramos y flores eternas hechos a mano con amor 💖',
  aboutText: '',
  whatsapp: '',
  sinpeNumber: '',
  sinpeName: '',
  paymentInstructions:
    'Para confirmar tu pedido, realizá el SINPE Móvil del adelanto y enviá el comprobante por WhatsApp junto con tu número de pedido 💌',
  deliveryMethods: ['Retiro en persona', 'Entrega a domicilio', 'Punto de encuentro'],
  instagram: '',
  facebook: '',
  tiktok: '',
  cancelWindowHours: 24,
};

export function parseSettings(d: Data | undefined): StoreSettings {
  if (!d) return DEFAULT_SETTINGS;
  const methods = strList(d.deliveryMethods);
  return {
    storeName: str(d.storeName) || DEFAULT_SETTINGS.storeName,
    tagline: str(d.tagline) || DEFAULT_SETTINGS.tagline,
    aboutText: str(d.aboutText),
    whatsapp: str(d.whatsapp),
    sinpeNumber: str(d.sinpeNumber),
    sinpeName: str(d.sinpeName),
    paymentInstructions: str(d.paymentInstructions) || DEFAULT_SETTINGS.paymentInstructions,
    deliveryMethods: methods.length ? methods : DEFAULT_SETTINGS.deliveryMethods,
    instagram: str(d.instagram),
    facebook: str(d.facebook),
    tiktok: str(d.tiktok),
    cancelWindowHours:
      typeof d.cancelWindowHours === 'number' && Number.isFinite(d.cancelWindowHours)
        ? Math.min(168, Math.max(0, Math.round(d.cancelWindowHours)))
        : DEFAULT_SETTINGS.cancelWindowHours,
  };
}

export function parseProfile(d: Data | undefined): UserProfile | null {
  if (!d) return null;
  return {
    name: str(d.name),
    phone: str(d.phone),
    email: str(d.email),
    province: str(d.province),
    canton: str(d.canton),
    district: str(d.district),
    address: str(d.address),
  };
}

function parseItem(v: unknown): OrderItem {
  const d = obj(v);
  const price = num(d.price);
  const qty = Math.max(1, num(d.qty, 1));
  return {
    productId: str(d.productId),
    name: str(d.name, 'Producto'),
    image: str(d.image),
    price,
    minDeposit: num(d.minDeposit),
    qty,
    option: str(d.option),
    note: str(d.note),
    subtotal: num(d.subtotal, price * qty),
  };
}

export function parseOrder(id: string, d: Data): Order {
  const items = Array.isArray(d.items) ? d.items.map(parseItem) : [];
  const history: StatusEvent[] = Array.isArray(d.statusHistory)
    ? d.statusHistory.map((h) => {
        const e = obj(h);
        const status = STATUSES.includes(e.status as OrderStatus) ? (e.status as OrderStatus) : 'pendiente_pago';
        return { status, at: toMillis(e.at) };
      })
    : [];
  const status = STATUSES.includes(d.status as OrderStatus) ? (d.status as OrderStatus) : 'pendiente_pago';
  return {
    id,
    orderNumber: str(d.orderNumber, '#' + id.slice(0, 6)),
    userId: str(d.userId),
    customer: parseProfile(obj(d.customer)) ?? DEFAULT_PROFILE,
    items,
    itemCount: num(d.itemCount, items.reduce((s, i) => s + i.qty, 0)),
    total: num(d.total),
    minDeposit: num(d.minDeposit),
    amountPaid: num(d.amountPaid),
    status,
    statusHistory: history,
    deliveryMethod: str(d.deliveryMethod),
    deliveryDetails: str(d.deliveryDetails),
    neededBy: str(d.neededBy),
    customerNotes: str(d.customerNotes),
    adminMessage: str(d.adminMessage),
    cancelDeadline: toMillis(d.cancelDeadline),
    cancelWindowHours: num(d.cancelWindowHours, -1),
    cancelledBy: str(d.cancelledBy),
    createdAt: toMillis(d.createdAt),
  };
}

export const DEFAULT_PROFILE: UserProfile = {
  name: '',
  phone: '',
  email: '',
  province: '',
  canton: '',
  district: '',
  address: '',
};
