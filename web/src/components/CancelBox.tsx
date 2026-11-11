import { useEffect, useState } from 'react';
import { useToast } from '../context/ToastContext';
import { cancelOrder } from '../lib/api';
import { formatDateTime, formatRemaining, hoursText } from '../lib/format';
import type { Order, OrderStatus } from '../lib/types';

/** Estados en los que el cliente todavía puede cancelar (aún no se empieza a hacer). */
const CANCELABLE: OrderStatus[] = ['pendiente_pago', 'pago_recibido'];

/** Hora actual que se actualiza sola (para la cuenta regresiva). */
function useNow(active: boolean) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (!active) return;
    const t = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(t);
  }, [active]);
  return now;
}

/** Cuadro de cancelación del pedido con cuenta regresiva. */
export default function CancelBox({ order }: { order: Order }) {
  const { toast, toastError } = useToast();
  const deadline = order.cancelDeadline;
  const statusAllows = CANCELABLE.includes(order.status);
  const now = useNow(!!deadline && statusAllows);
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);

  // Pedidos cancelados o de antes de esta función: no se muestra nada
  if (order.status === 'cancelado' || order.cancelWindowHours < 0) return null;

  // La tienda no permite cancelaciones
  if (!deadline) {
    return (
      <section className="cancel-box cancel-box--locked">
        <span aria-hidden="true">🔒</span>
        <p>Este pedido no se puede cancelar: cada pieza se hace a mano especialmente para vos 💕</p>
      </section>
    );
  }

  const remaining = deadline - now;

  if (!statusAllows) {
    return (
      <section className="cancel-box cancel-box--locked">
        <span aria-hidden="true">🧶</span>
        <p>Tu pedido ya se está haciendo con mucho amor, por eso ya no se puede cancelar.</p>
      </section>
    );
  }

  if (remaining <= 0) {
    return (
      <section className="cancel-box cancel-box--locked">
        <span aria-hidden="true">🔒</span>
        <p>
          El plazo para cancelar terminó el <strong>{formatDateTime(deadline)}</strong>. Tu pedido ya es firme 💕
        </p>
      </section>
    );
  }

  async function doCancel() {
    setBusy(true);
    try {
      await cancelOrder(order.id);
      toast('Tu pedido fue cancelado', '🥀');
      setConfirming(false);
    } catch (e) {
      toastError(e instanceof Error ? e.message : 'No pudimos cancelar el pedido.');
    } finally {
      setBusy(false);
    }
  }

  // Porcentaje de tiempo restante para la barrita
  const totalMs = Math.max(1, order.cancelWindowHours * 3_600_000);
  const pct = Math.min(100, Math.max(0, (remaining / totalMs) * 100));

  return (
    <section className="cancel-box">
      <div className="cancel-box__head">
        <span className="cancel-box__clock" aria-hidden="true">
          ⏳
        </span>
        <div>
          <strong>Podés cancelar durante</strong>
          <span className="cancel-box__time" aria-live="off">
            {formatRemaining(remaining)}
          </span>
        </div>
      </div>
      <div className="cancel-box__bar" aria-hidden="true">
        <span style={{ width: `${pct}%` }} />
      </div>
      <p className="cancel-box__note">
        Tenés {hoursText(order.cancelWindowHours)} desde que hiciste el pedido (hasta el {formatDateTime(deadline)}). Después ya
        no se puede cancelar, porque empezamos a crearlo a mano 💕
      </p>
      {!confirming ? (
        <button type="button" className="btn btn--soft btn--sm" onClick={() => setConfirming(true)}>
          Cancelar pedido
        </button>
      ) : (
        <div className="cancel-box__confirm" role="alertdialog" aria-label="Confirmar cancelación">
          <p>¿Seguro que querés cancelar el pedido {order.orderNumber}? Esto no se puede deshacer.</p>
          <div className="cancel-box__actions">
            <button type="button" className="btn btn--danger-solid btn--sm" disabled={busy} onClick={doCancel}>
              {busy ? 'Cancelando...' : 'Sí, cancelar'}
            </button>
            <button type="button" className="btn btn--ghost btn--sm" disabled={busy} onClick={() => setConfirming(false)}>
              No, lo quiero 💖
            </button>
          </div>
        </div>
      )}
    </section>
  );
}
