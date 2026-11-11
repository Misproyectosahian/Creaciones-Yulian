import { formatDateTime } from '../lib/format';
import { STATUS, TRACK_STEPS } from '../lib/status';
import type { Order } from '../lib/types';

/** Seguimiento visual del pedido (tracking). */
export default function OrderTimeline({ order }: { order: Order }) {
  if (order.status === 'cancelado') {
    const at = [...order.statusHistory].reverse().find((h) => h.status === 'cancelado')?.at ?? null;
    return (
      <div className="timeline-cancelled">
        <span aria-hidden="true">🥀</span>
        <div>
          <strong>Pedido cancelado</strong>
          <p>{at ? formatDateTime(at) : 'Si tenés dudas, escribinos por WhatsApp 💕'}</p>
        </div>
      </div>
    );
  }

  const currentIndex = TRACK_STEPS.indexOf(order.status);
  const dateOf = (s: string) => [...order.statusHistory].reverse().find((h) => h.status === s)?.at ?? null;

  return (
    <ol className="timeline">
      {TRACK_STEPS.map((step, i) => {
        const meta = STATUS[step];
        const state = i < currentIndex ? 'done' : i === currentIndex ? 'current' : 'todo';
        const at = dateOf(step);
        return (
          <li key={step} className={`timeline__step is-${state}`} style={{ '--c': meta.color } as React.CSSProperties}>
            <span className="timeline__dot" aria-hidden="true">
              {state === 'todo' ? '' : meta.emoji}
            </span>
            <div className="timeline__text">
              <strong>{meta.label}</strong>
              {state === 'current' && <p>{meta.description}</p>}
              {at && state !== 'todo' && <time>{formatDateTime(at)}</time>}
            </div>
          </li>
        );
      })}
    </ol>
  );
}
