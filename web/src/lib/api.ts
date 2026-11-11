import { auth } from './firebase';

export interface NewOrderPayload {
  items: { productId: string; qty: number; option: string; note: string }[];
  deliveryMethod: string;
  deliveryDetails: string;
  neededBy: string;
  customerNotes: string;
}

/** Crea el pedido en el servidor (Netlify Function). */
export async function createOrder(payload: NewOrderPayload): Promise<{ id: string; orderNumber: string }> {
  const user = auth.currentUser;
  if (!user) throw new Error('Necesitás iniciar sesión para hacer tu pedido.');
  const token = await user.getIdToken();

  let res: Response;
  try {
    res = await fetch('/.netlify/functions/create-order', {
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

  if (!res.ok) {
    throw new Error(typeof data.error === 'string' ? data.error : 'No pudimos crear tu pedido. Intentá de nuevo.');
  }
  if (typeof data.id !== 'string' || typeof data.orderNumber !== 'string') {
    throw new Error('El servidor de pedidos no respondió bien. Si estás probando en tu compu, usá "netlify dev".');
  }
  return { id: data.id, orderNumber: data.orderNumber };
}
