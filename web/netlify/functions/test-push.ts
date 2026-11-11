import { handler, json, notifyAdmins, requireAdmin } from '../lib/server';

/** Envía una notificación de prueba a los celulares de administración. */
export default handler(async (req) => {
  await requireAdmin(req);
  const sent = await notifyAdmins({
    title: '🔔 ¡Notificación de prueba!',
    body: 'Así te van a llegar los pedidos nuevos 💖',
    data: { type: 'test' },
  });
  return json({ sent });
});
