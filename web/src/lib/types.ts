export type Availability = 'disponible' | 'encargo' | 'agotado';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  minDeposit: number;
  categoryId: string;
  images: string[];
  options: string[];
  optionsLabel: string;
  availability: Availability;
  leadTime: string;
  featured: boolean;
  createdAt: number;
}

export interface Category {
  id: string;
  name: string;
  emoji: string;
  description: string;
  order: number;
}

export interface StoreSettings {
  storeName: string;
  tagline: string;
  aboutText: string;
  whatsapp: string;
  sinpeNumber: string;
  sinpeName: string;
  paymentInstructions: string;
  deliveryMethods: string[];
  instagram: string;
  facebook: string;
  tiktok: string;
}

export interface UserProfile {
  name: string;
  phone: string;
  email: string;
  province: string;
  canton: string;
  district: string;
  address: string;
}

export type OrderStatus =
  | 'pendiente_pago'
  | 'pago_recibido'
  | 'en_proceso'
  | 'listo'
  | 'en_camino'
  | 'entregado'
  | 'cancelado';

export interface OrderItem {
  productId: string;
  name: string;
  image: string;
  price: number;
  minDeposit: number;
  qty: number;
  option: string;
  note: string;
  subtotal: number;
}

export interface StatusEvent {
  status: OrderStatus;
  at: number | null;
}

export interface Order {
  id: string;
  orderNumber: string;
  userId: string;
  customer: UserProfile;
  items: OrderItem[];
  itemCount: number;
  total: number;
  minDeposit: number;
  amountPaid: number;
  status: OrderStatus;
  statusHistory: StatusEvent[];
  deliveryMethod: string;
  deliveryDetails: string;
  neededBy: string;
  customerNotes: string;
  adminMessage: string;
  createdAt: number | null;
}
