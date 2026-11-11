import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { collection, doc, onSnapshot, query, where } from 'firebase/firestore';
import { EmptyState, HeartLoader, StatusBadge } from '../components/Bits';
import { CopyIcon, WhatsAppIcon } from '../components/Icons';
import OrderTimeline from '../components/OrderTimeline';
import ProfileFields, { validateProfile, type ProfileForm } from '../components/ProfileFields';
import { authErrorMessage, useAuth } from '../context/AuthContext';
import { useStore } from '../context/StoreContext';
import { useToast } from '../context/ToastContext';
import { effects } from '../lib/effects';
import { liveDb } from '../lib/live';
import { crc, formatDateTime, formatIsoDay, formatPhone, plural, timeAgo, whatsappLink } from '../lib/format';
import { cld } from '../lib/image';
import { parseOrder } from '../lib/parse';
import { STATUS } from '../lib/status';
import type { Order } from '../lib/types';

// ─────────────────────────────── Mis pedidos ───────────────────────────────

export function MyOrdersPage() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    return onSnapshot(
      query(collection(liveDb, 'orders'), where('userId', '==', user.uid)),
      (snap) => {
        const list = snap.docs.map((d) => parseOrder(d.id, d.data()));
        list.sort((a, b) => (b.createdAt ?? Date.now()) - (a.createdAt ?? Date.now()));
        setOrders(list);
      },
      () => setError('No pudimos cargar tus pedidos. Intentá de nuevo.'),
    );
  }, [user]);

  return (
    <div className="container narrow">
      <h1 className="page-title">Mis pedidos 🧾</h1>
      {error && <div className="alert alert--error">{error}</div>}
      {!orders && !error ? (
        <HeartLoader label="Buscando tus pedidos..." />
      ) : orders && orders.length === 0 ? (
        <EmptyState
          emoji="🌷"
          title="Todavía no tenés pedidos"
          text="Cuando hagás tu primer pedido, aquí vas a poder ver en qué estado está."
          action={
            <Link to="/catalogo" className="btn btn--primary">
              Ver catálogo
            </Link>
          }
        />
      ) : (
        <ul className="order-list">
          {orders?.map((o, i) => (
            <li key={o.id} style={{ animationDelay: `${i * 50}ms` }}>
              <Link to={`/pedido/${o.id}`} className="order-card">
                <div className="order-card__imgs">
                  {o.items.slice(0, 3).map((it, j) =>
                    it.image ? <img key={j} src={cld(it.image, 120)} alt="" loading="lazy" /> : <span key={j} className="img-placeholder">🧶</span>,
                  )}
                </div>
                <div className="order-card__info">
                  <strong>{o.orderNumber}</strong>
                  <span className="muted">
                    {timeAgo(o.createdAt)} · {plural(o.itemCount, 'producto', 'productos')}
                  </span>
                  <StatusBadge status={o.status} />
                </div>
                <div className="order-card__total">{crc(o.total)}</div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// ─────────────────────────────── Detalle / tracking ───────────────────────────────

export function OrderPage() {
  const { id = '' } = useParams();
  const [params, setParams] = useSearchParams();
  const { settings } = useStore();
  const { toast } = useToast();
  const [order, setOrder] = useState<Order | null | undefined>(undefined);
  const lastStatus = useRef<string | null>(null);
  // Mensaje de "¡Pedido creado!" (se guarda al entrar, aunque se limpie la URL)
  const [isNew] = useState(() => params.get('nuevo') === '1');

  useEffect(() => {
    setOrder(undefined);
    lastStatus.current = null;
    return onSnapshot(
      doc(liveDb, 'orders', id),
      (snap) => {
        if (!snap.exists()) {
          setOrder(null);
          return;
        }
        const o = parseOrder(snap.id, snap.data());
        // Confeti cuando el estado avanza mientras la página está abierta 🎉
        if (lastStatus.current && lastStatus.current !== o.status && o.status !== 'cancelado') {
          effects.confetti(120);
          toast(`Tu pedido ahora está: ${STATUS[o.status].label}`, STATUS[o.status].emoji);
        }
        lastStatus.current = o.status;
        setOrder(o);
      },
      () => setOrder(null),
    );
  }, [id, toast]);

  // Quita ?nuevo=1 de la dirección para que no se repita la celebración al recargar
  useEffect(() => {
    if (params.get('nuevo') === '1') setParams({}, { replace: true });
  }, [params, setParams]);

  if (order === undefined) return <HeartLoader label="Cargando tu pedido..." />;
  if (order === null) {
    return (
      <div className="container">
        <EmptyState
          emoji="🔍"
          title="No encontramos este pedido"
          text="Revisá que hayas ingresado con la misma cuenta con la que hiciste el pedido."
          action={
            <Link to="/mis-pedidos" className="btn btn--primary">
              Ver mis pedidos
            </Link>
          }
        />
      </div>
    );
  }

  const o = order;
  const balance = Math.max(0, o.total - o.amountPaid);
  const depositDue = Math.max(0, o.minDeposit - o.amountPaid);
  const progress = o.total > 0 ? Math.min(1, o.amountPaid / o.total) : 0;
  const receiptMsg = `¡Hola! 💖 Te envío el comprobante del SINPE de mi pedido ${o.orderNumber} (${crc(o.minDeposit > 0 ? o.minDeposit : o.total)}). Mi nombre es ${o.customer.name}.`;
  const helpMsg = `¡Hola! 💖 Tengo una consulta sobre mi pedido ${o.orderNumber}.`;

  async function copy(text: string, label: string) {
    try {
      await navigator.clipboard.writeText(text);
      toast(`${label} copiado`, '📋');
    } catch {
      /* sin portapapeles */
    }
  }

  return (
    <div className="container narrow order-page">
      <Link to="/mis-pedidos" className="back-link">
        ← Mis pedidos
      </Link>

      {isNew && (
        <div className="celebrate">
          <div className="celebrate__emoji" aria-hidden="true">
            🎉
          </div>
          <h1>¡Pedido creado con éxito!</h1>
          <p>Gracias por tu compra 💖 Ya le avisamos a {settings.storeName}.</p>
        </div>
      )}

      <article className="ticket">
        <header className="ticket__head">
          <div>
            <span className="ticket__label">Pedido</span>
            <h2 className="ticket__number">{o.orderNumber}</h2>
            <span className="muted">{formatDateTime(o.createdAt)}</span>
          </div>
          <StatusBadge status={o.status} large />
        </header>

        {o.status === 'pendiente_pago' && (
          <section className="pay-box">
            <h3>💸 Cómo confirmar tu pedido</h3>
            <p>{settings.paymentInstructions}</p>
            <div className="pay-box__grid">
              <div className="pay-box__item">
                <span>Monto {o.minDeposit > 0 ? 'mínimo de adelanto' : 'a pagar'}</span>
                <strong>{crc(o.minDeposit > 0 ? depositDue || o.minDeposit : o.total)}</strong>
              </div>
              {settings.sinpeNumber && (
                <div className="pay-box__item">
                  <span>SINPE Móvil</span>
                  <strong>
                    {formatPhone(settings.sinpeNumber)}
                    <button type="button" className="copy-btn" aria-label="Copiar número" onClick={() => copy(settings.sinpeNumber.replace(/\D/g, ''), 'Número')}>
                      <CopyIcon size={16} />
                    </button>
                  </strong>
                  {settings.sinpeName && <small>A nombre de {settings.sinpeName}</small>}
                </div>
              )}
              <div className="pay-box__item">
                <span>Detalle del SINPE</span>
                <strong>
                  {o.orderNumber}
                  <button type="button" className="copy-btn" aria-label="Copiar número de pedido" onClick={() => copy(o.orderNumber, 'Número de pedido')}>
                    <CopyIcon size={16} />
                  </button>
                </strong>
              </div>
            </div>
            {settings.whatsapp && (
              <a className="btn btn--whatsapp btn--block" href={whatsappLink(settings.whatsapp, receiptMsg)} target="_blank" rel="noreferrer">
                <WhatsAppIcon size={20} /> Enviar comprobante por WhatsApp
              </a>
            )}
          </section>
        )}

        {o.adminMessage && (
          <section className="admin-msg">
            <span className="admin-msg__emoji" aria-hidden="true">
              💌
            </span>
            <div>
              <strong>Mensaje de {settings.storeName}</strong>
              <p>{o.adminMessage}</p>
            </div>
          </section>
        )}

        <div className="ticket__cut" aria-hidden="true" />

        <section>
          <h3 className="ticket__section-title">📍 Seguimiento</h3>
          <OrderTimeline order={o} />
        </section>

        <div className="ticket__cut" aria-hidden="true" />

        <section>
          <h3 className="ticket__section-title">🛍️ Productos</h3>
          <ul className="ticket__items">
            {o.items.map((it, i) => (
              <li key={i}>
                {it.image ? <img src={cld(it.image, 140)} alt="" loading="lazy" /> : <span className="img-placeholder">🧶</span>}
                <div>
                  <strong>{it.name}</strong>
                  {it.option && <small>Opción: {it.option}</small>}
                  {it.note && <small>✏️ {it.note}</small>}
                  <small>
                    {it.qty} × {crc(it.price)}
                  </small>
                </div>
                <span>{crc(it.subtotal)}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="ticket__totals">
          <div>
            <span>Total</span>
            <strong>{crc(o.total)}</strong>
          </div>
          {o.minDeposit > 0 && (
            <div>
              <span>Adelanto mínimo</span>
              <span>{crc(o.minDeposit)}</span>
            </div>
          )}
          <div>
            <span>Pagado</span>
            <span className="text-ok">{crc(o.amountPaid)}</span>
          </div>
          <div>
            <span>Saldo pendiente</span>
            <strong className={balance > 0 ? 'text-pink' : 'text-ok'}>{crc(balance)}</strong>
          </div>
          <div className="progress" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(progress * 100)}>
            <span style={{ width: `${progress * 100}%` }} />
          </div>
        </section>

        <div className="ticket__cut" aria-hidden="true" />

        <section className="ticket__delivery">
          <h3 className="ticket__section-title">🚚 Entrega</h3>
          <dl className="data-list">
            <div>
              <dt>Forma</dt>
              <dd>{o.deliveryMethod || '—'}</dd>
            </div>
            {o.deliveryDetails && (
              <div>
                <dt>Detalles</dt>
                <dd>{o.deliveryDetails}</dd>
              </div>
            )}
            {o.neededBy && (
              <div>
                <dt>Para el</dt>
                <dd>{formatIsoDay(o.neededBy)}</dd>
              </div>
            )}
            {o.customerNotes && (
              <div>
                <dt>Tus notas</dt>
                <dd>{o.customerNotes}</dd>
              </div>
            )}
          </dl>
        </section>
      </article>

      {settings.whatsapp && (
        <a className="btn btn--soft btn--block" href={whatsappLink(settings.whatsapp, helpMsg)} target="_blank" rel="noreferrer">
          <WhatsAppIcon size={18} /> ¿Dudas? Escribinos por WhatsApp
        </a>
      )}
    </div>
  );
}

// ─────────────────────────────── Mis datos ───────────────────────────────

export function ProfilePage() {
  const { profile, user, saveProfile, logout } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const back = params.get('volver');
  const [form, setForm] = useState<ProfileForm>(() => ({
    name: profile?.name || user?.displayName || '',
    phone: profile?.phone ?? '',
    province: profile?.province ?? '',
    canton: profile?.canton ?? '',
    district: profile?.district ?? '',
    address: profile?.address ?? '',
  }));
  const [errors, setErrors] = useState<Partial<Record<keyof ProfileForm, string>>>({});
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const v = validateProfile(form);
    setErrors(v);
    if (Object.keys(v).length) return;
    setBusy(true);
    try {
      await saveProfile(form);
      toast('¡Datos guardados!', '✨');
      if (back && back.startsWith('/') && !back.startsWith('//')) navigate(back);
    } catch (err) {
      setError(authErrorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="container narrow">
      <h1 className="page-title">Mis datos 👤</h1>
      <p className="muted">Estos datos se adjuntan a tus pedidos para que podamos contactarte y coordinar la entrega.</p>
      <form className="card form" onSubmit={submit} noValidate>
        <div className="field">
          <label htmlFor="pf-email">Correo</label>
          <input id="pf-email" value={user?.email ?? ''} disabled />
        </div>
        <ProfileFields value={form} onChange={setForm} errors={errors} />
        {error && (
          <div className="alert alert--error" role="alert">
            {error}
          </div>
        )}
        <button type="submit" className="btn btn--primary btn--lg btn--block" disabled={busy}>
          {busy ? 'Guardando...' : back ? 'Guardar y continuar 💖' : 'Guardar cambios 💖'}
        </button>
      </form>
      <div className="profile-links">
        <Link to="/mis-pedidos" className="btn btn--soft">
          🧾 Mis pedidos
        </Link>
        <button
          type="button"
          className="btn btn--link btn--danger"
          onClick={async () => {
            await logout();
            toast('Sesión cerrada. ¡Vuelvas pronto!', '👋');
            navigate('/');
          }}
        >
          Cerrar sesión
        </button>
      </div>
    </div>
  );
}
