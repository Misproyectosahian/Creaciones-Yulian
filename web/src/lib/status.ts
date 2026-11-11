import type { Availability, OrderStatus } from './types';

export interface StatusMeta {
  label: string;
  emoji: string;
  color: string;
  description: string;
}

export const STATUS: Record<OrderStatus, StatusMeta> = {
  pendiente_pago: {
    label: 'Pendiente de pago',
    emoji: '💌',
    color: '#f06a9e',
    description: 'Realizá el SINPE del adelanto para confirmar tu pedido.',
  },
  pago_recibido: {
    label: 'Pago recibido',
    emoji: '💖',
    color: '#d94f8c',
    description: '¡Recibimos tu pago! Tu pedido está confirmado.',
  },
  en_proceso: {
    label: 'Pedido en proceso',
    emoji: '🧶',
    color: '#9b7be0',
    description: 'Tu pedido se está creando a mano con mucho amor.',
  },
  listo: {
    label: 'Listo para entregar',
    emoji: '🎁',
    color: '#e59a2f',
    description: '¡Tu pedido está listo! Coordinamos la entrega.',
  },
  en_camino: {
    label: 'En camino',
    emoji: '🚗',
    color: '#4a9fd8',
    description: 'Tu pedido va en camino o está por entregarse.',
  },
  entregado: {
    label: 'Entregado',
    emoji: '🌸',
    color: '#3bb58a',
    description: '¡Gracias por tu compra! Esperamos que lo amés.',
  },
  cancelado: {
    label: 'Cancelado',
    emoji: '🥀',
    color: '#9e8fa8',
    description: 'Este pedido fue cancelado.',
  },
};

/** Pasos que se muestran en el seguimiento (en orden). */
export const TRACK_STEPS: OrderStatus[] = ['pendiente_pago', 'pago_recibido', 'en_proceso', 'listo', 'en_camino', 'entregado'];

export const AVAILABILITY: Record<Availability, { label: string; emoji: string; className: string }> = {
  disponible: { label: 'Disponible', emoji: '✅', className: 'badge--ok' },
  encargo: { label: 'Por encargo', emoji: '🧶', className: 'badge--lilac' },
  agotado: { label: 'Agotado', emoji: '💤', className: 'badge--muted' },
};
