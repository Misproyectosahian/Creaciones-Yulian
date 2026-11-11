import { auth } from './firebase';

export interface NewOrderPayload {
  items: { productId: string; qty: number; option: string; note: string }[];
  deliveryMethod: string;
  deliveryDetails: string;
  neededBy: string;
  customerNotes: string;
}

/** Llama a una función del servidor (Netlify Function) con la sesión del cliente. */
async function callFunction(name: string, payload: unknown, fallbackError: string): Promise<Record<string, unknown>> {
  const user = auth.currentUser;
  if (!user) throw new Error('Necesitás iniciar sesión.');
  const token = await user.getIdToken();

  let res: Response;
  try {
    res = await fetch(`/.netlify/functions/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    });
  } catch {
    throw new Error('No hay conexión. Revisá tu internet e intentá de nuevo.');
  }

  let data: Record<string, unknown> = {};
  try {
    data = (await res.json()) as Record<string, unknown>;
  } catch {
    /* respuesta sin JSON */
  }
  if (!res.ok) throw new Error(typeof data.error === 'string' ? data.error : fallbackError);
  return data;
}

/** Crea el pedido en el servidor (los precios los calcula el servidor). */
export async function createOrder(payload: NewOrderPayload): Promise<{ id: string; orderNumber: string }> {
  const data = await callFunction('create-order', payload, 'No pudimos crear tu pedido. Intentá de nuevo.');
  if (typeof data.id !== 'string' || typeof data.orderNumber !== 'string') {
    throw new Error('El servidor de pedidos no respondió bien. Si estás probando en tu compu, usá "netlify dev".');
  }
  return { id: data.id, orderNumber: data.orderNumber };
}

/** Cancela un pedido (solo dentro del plazo permitido; lo valida el servidor). */
export async function cancelOrder(orderId: string): Promise<void> {
  await callFunction('cancel-order', { orderId }, 'No pudimos cancelar el pedido. Intentá de nuevo.');
}
