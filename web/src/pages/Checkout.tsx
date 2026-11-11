import { useEffect, useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { HeartLoader } from '../components/Bits';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { useToast } from '../context/ToastContext';
import { createOrder } from '../lib/api';
import { effects } from '../lib/effects';
import { crc, formatPhone } from '../lib/format';
import { cld } from '../lib/image';
import { useCartLines } from './CartPage';

function todayIso() {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export default function Checkout() {
  const { profile, profileComplete, user } = useAuth();
  const { settings } = useStore();
  const { clear } = useCart();
  const { toastError } = useToast();
  const navigate = useNavigate();
  const { lines, valid, total, deposit, count, loading, hasUnavailable } = useCartLines();

  const [method, setMethod] = useState('');
  const [details, setDetails] = useState('');
  const [neededBy, setNeededBy] = useState('');
  const [notes, setNotes] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [detailsTouched, setDetailsTouched] = useState(false);

  // Rellena la dirección con la del perfil
  useEffect(() => {
    if (!detailsTouched && profile) {
      const place = [profile.address, profile.district, profile.canton, profile.province].filter(Boolean).join(', ');
      setDetails(place);
    }
  }, [profile, detailsTouched]);

  useEffect(() => {
    if (!method && settings.deliveryMethods.length === 1) setMethod(settings.deliveryMethods[0]);
  }, [settings.deliveryMethods, method]);

  if (loading) return <HeartLoader label="Preparando tu pedido..." />;
  if (!sending && lines.length === 0) return <Navigate to="/carrito" replace />;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!method) {
      setError('Elegí una forma de entrega 🚚');
      return;
    }
    if (hasUnavailable || valid.length === 0) {
      setError('Hay productos no disponibles en tu carrito. Revisalo antes de continuar.');
      return;
    }
    setSending(true);
    try {
      const { id } = await createOrder({
        items: valid.map((l) => ({ productId: l.productId, qty: l.qty, option: l.option, note: l.note })),
        deliveryMethod: method,
        deliveryDetails: details,
        neededBy,
        customerNotes: notes,
      });
      clear();
      effects.confetti(180);
      navigate(`/pedido/${id}?nuevo=1`, { replace: true });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'No pudimos crear tu pedido.';
      setError(message);
      toastError(message);
      setSending(false);
    }
  }

  if (!profileComplete) {
    return (
      <div className="container narrow">
        <div className="card card--center">
          <div className="big-emoji">📝</div>
          <h1 className="page-title">Completá tus datos</h1>
          <p className="muted">Necesitamos tu nombre y teléfono para poder contactarte sobre tu pedido.</p>
          <Link to="/perfil?volver=/checkout" className="btn btn--primary">
            Completar mis datos
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container checkout">
      <h1 className="page-title">Confirmar pedido 💖</h1>
      <form className="checkout-layout" onSubmit={submit}>
        <div className="checkout-main">
          <section className="card">
            <div className="card__head">
              <h2>🙋 Tus datos</h2>
              <Link to="/perfil?volver=/checkout" className="btn btn--link btn--sm">
                Editar
              </Link>
            </div>
            <dl className="data-list">
              <div>
                <dt>Nombre</dt>
                <dd>{profile?.name}</dd>
              </div>
              <div>
                <dt>Teléfono</dt>
                <dd>{formatPhone(profile?.phone ?? '')}</dd>
              </div>
              <div>
                <dt>Correo</dt>
                <dd>{user?.email}</dd>
              </div>
            </dl>
          </section>

          <section className="card">
            <h2>🚚 Entrega</h2>
            <div className="method-grid" role="radiogroup" aria-label="Forma de entrega">
              {settings.deliveryMethods.map((m) => (
                <label key={m} className={`method${method === m ? ' is-active' : ''}`}>
                  <input type="radio" name="method" value={m} checked={method === m} onChange={() => setMethod(m)} />
                  <span className="method__emoji" aria-hidden="true">
                    {/retir|recog/i.test(m) ? '🏠' : /domicilio|express|envío|envio/i.test(m) ? '🛵' : /encuentro/i.test(m) ? '📍' : '🎁'}
                  </span>
                  <span>{m}</span>
                </label>
              ))}
            </div>
            <div className="field">
              <label htmlFor="details">Dirección o punto de entrega</label>
              <textarea
                id="details"
                rows={2}
                maxLength={500}
                value={details}
                onChange={(e) => {
                  setDetails(e.target.value);
                  setDetailsTouched(true);
                }}
                placeholder="Dirección exacta, lugar de encuentro o detalles para coordinar"
              />
            </div>
            <div className="field">
              <label htmlFor="neededBy">
                ¿Para cuándo lo necesitás? <span className="optional">(opcional)</span>
              </label>
              <input id="neededBy" type="date" min={todayIso()} value={neededBy} onChange={(e) => setNeededBy(e.target.value)} />
            </div>
            <div className="field">
              <label htmlFor="notes">
                Notas para {settings.storeName} <span className="optional">(opcional)</span>
              </label>
              <textarea
                id="notes"
                rows={3}
                maxLength={800}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Ocasión especial, tarjeta con dedicatoria, colores preferidos... 💌"
              />
            </div>
          </section>
        </div>

        <aside className="summary">
          <h2>Tu pedido</h2>
          <ul className="mini-lines">
            {valid.map((l) => (
              <li key={l.key}>
                {l.product?.images[0] ? <img src={cld(l.product.images[0], 120)} alt="" /> : <span className="img-placeholder">🧶</span>}
                <div>
                  <strong>{l.product?.name}</strong>
                  <small>
                    {l.qty} × {crc(l.product?.price ?? 0)}
                    {l.option ? ` · ${l.option}` : ''}
                  </small>
                </div>
              </li>
            ))}
          </ul>
          <div className="summary__row">
            <span>Productos ({count})</span>
            <span>{crc(total)}</span>
          </div>
          <div className="summary__row summary__row--total">
            <span>Total</span>
            <span>{crc(total)}</span>
          </div>
          <div className="summary__deposit">
            <span>💸 Adelanto mínimo</span>
            <strong>{crc(deposit)}</strong>
          </div>
          <p className="summary__note">
            Después de confirmar te mostramos cómo pagar el adelanto por SINPE Móvil. El pedido queda "Pendiente de pago" hasta recibirlo.
          </p>
          {error && (
            <div className="alert alert--error" role="alert">
              {error}
            </div>
          )}
          <button type="submit" className="btn btn--primary btn--lg btn--block" disabled={sending}>
            {sending ? 'Creando tu pedido... 💫' : 'Confirmar pedido 💖'}
          </button>
          <Link to="/carrito" className="btn btn--link btn--block">
            ← Volver al carrito
          </Link>
        </aside>
      </form>
    </div>
  );
}
