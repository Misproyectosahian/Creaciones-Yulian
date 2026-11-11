import { useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { EmptyState, HeartLoader } from '../components/Bits';
import { MinusIcon, PlusIcon, TrashIcon } from '../components/Icons';
import { useAuth } from '../context/AuthContext';
import { MAX_QTY, useCart, type CartItem } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { crc } from '../lib/format';
import { cld } from '../lib/image';
import type { Product } from '../lib/types';

export interface CartLine extends CartItem {
  product: Product | undefined;
  unavailable: boolean;
}

/** Une el carrito con los datos actuales de los productos. */
export function useCartLines() {
  const { items } = useCart();
  const { productsById, loading } = useStore();
  return useMemo(() => {
    const lines: CartLine[] = items.map((i) => {
      const product = productsById.get(i.productId);
      const unavailable =
        !product || product.availability === 'agotado' || (product.options.length > 0 && !product.options.includes(i.option));
      return { ...i, product, unavailable };
    });
    const valid = lines.filter((l) => !l.unavailable && l.product);
    const total = valid.reduce((s, l) => s + (l.product?.price ?? 0) * l.qty, 0);
    const deposit = valid.reduce((s, l) => s + Math.min(l.product?.minDeposit ?? 0, l.product?.price ?? 0) * l.qty, 0);
    const count = valid.reduce((s, l) => s + l.qty, 0);
    return { lines, valid, total, deposit, count, loading, hasUnavailable: lines.some((l) => l.unavailable) };
  }, [items, productsById, loading]);
}

export default function CartPage() {
  const { setQty, remove } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  const { lines, valid, total, deposit, count, loading, hasUnavailable } = useCartLines();

  if (loading && lines.length > 0) {
    return (
      <div className="container">
        <HeartLoader label="Cargando tu carrito..." />
      </div>
    );
  }

  if (lines.length === 0) {
    return (
      <div className="container">
        <EmptyState
          emoji="🛍️"
          title="Tu carrito está vacío"
          text="¡Llenémoslo de cositas lindas! 💕"
          action={
            <Link to="/catalogo" className="btn btn--primary">
              Ver catálogo
            </Link>
          }
        />
      </div>
    );
  }

  return (
    <div className="container cart-page">
      <h1 className="page-title">Tu carrito 🛍️</h1>
      <div className="cart-layout">
        <ul className="cart-list">
          {lines.map((l) => (
            <li key={l.key} className={`cart-item${l.unavailable ? ' is-unavailable' : ''}`}>
              <Link to={l.product ? `/producto/${l.productId}` : '/catalogo'} className="cart-item__img">
                {l.product?.images[0] ? <img src={cld(l.product.images[0], 220)} alt="" loading="lazy" /> : <div className="img-placeholder">🧶</div>}
              </Link>
              <div className="cart-item__info">
                <h3>{l.product?.name ?? 'Producto no disponible'}</h3>
                {l.option && (
                  <p className="cart-item__meta">
                    {l.product?.optionsLabel ?? 'Opción'}: <strong>{l.option}</strong>
                  </p>
                )}
                {l.note && <p className="cart-item__note">✏️ {l.note}</p>}
                {l.unavailable ? (
                  <p className="cart-item__warn">Ya no está disponible 🥺 Quitalo para continuar.</p>
                ) : (
                  <p className="cart-item__meta">
                    {crc(l.product!.price)} c/u
                    {l.product!.minDeposit > 0 && <> · adelanto {crc(l.product!.minDeposit)}</>}
                  </p>
                )}
                <div className="cart-item__actions">
                  {!l.unavailable && (
                    <div className="qty qty--sm">
                      <button type="button" onClick={() => setQty(l.key, l.qty - 1)} disabled={l.qty <= 1} aria-label="Menos">
                        <MinusIcon size={16} />
                      </button>
                      <span>{l.qty}</span>
                      <button type="button" onClick={() => setQty(l.key, l.qty + 1)} disabled={l.qty >= MAX_QTY} aria-label="Más">
                        <PlusIcon size={16} />
                      </button>
                    </div>
                  )}
                  <button type="button" className="btn btn--link btn--danger" onClick={() => remove(l.key)}>
                    <TrashIcon size={16} /> Quitar
                  </button>
                </div>
              </div>
              {!l.unavailable && <div className="cart-item__total">{crc(l.product!.price * l.qty)}</div>}
            </li>
          ))}
        </ul>

        <aside className="summary">
          <h2>Resumen</h2>
          <div className="summary__row">
            <span>Productos ({count})</span>
            <span>{crc(total)}</span>
          </div>
          <div className="summary__row summary__row--total">
            <span>Total</span>
            <span>{crc(total)}</span>
          </div>
          <div className="summary__deposit">
            <span>💸 Adelanto mínimo para confirmar</span>
            <strong>{crc(deposit)}</strong>
          </div>
          <p className="summary__note">El envío o entrega se coordina con vos después de hacer el pedido.</p>
          {hasUnavailable && <p className="summary__warn">Quitá los productos no disponibles para continuar.</p>}
          <button
            type="button"
            className="btn btn--primary btn--lg btn--block"
            disabled={valid.length === 0 || hasUnavailable}
            onClick={() => navigate(user ? '/checkout' : '/ingresar?volver=/checkout')}
          >
            {user ? 'Continuar con el pedido 💖' : 'Ingresar para continuar 💖'}
          </button>
          <Link to="/catalogo" className="btn btn--link btn--block">
            ← Seguir comprando
          </Link>
        </aside>
      </div>
    </div>
  );
}
