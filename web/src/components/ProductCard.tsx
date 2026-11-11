import { useRef } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { useToast } from '../context/ToastContext';
import { effects } from '../lib/effects';
import { crc } from '../lib/format';
import { cld, cldSrcSet } from '../lib/image';
import { AVAILABILITY } from '../lib/status';
import type { Product } from '../lib/types';
import { CartIcon, HeartIcon } from './Icons';

export default function ProductCard({ product, index = 0 }: { product: Product; index?: number }) {
  const { categoriesById } = useStore();
  const { favorites, toggleFavorite, add } = useCart();
  const { toast } = useToast();
  const favRef = useRef<HTMLButtonElement>(null);
  const addRef = useRef<HTMLButtonElement>(null);
  const p = product;
  const fav = favorites.has(p.id);
  const category = categoriesById.get(p.categoryId);
  const availability = AVAILABILITY[p.availability];
  const canQuickAdd = p.options.length === 0 && p.availability !== 'agotado';

  return (
    <article className="product-card" style={{ animationDelay: `${Math.min(index, 12) * 45}ms` }}>
      <Link to={`/producto/${p.id}`} className="product-card__media" aria-label={p.name}>
        {p.images[0] ? (
          <img
            src={cld(p.images[0], 500)}
            srcSet={cldSrcSet(p.images[0], [320, 500, 800])}
            sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 280px"
            alt={p.name}
            loading={index < 4 ? 'eager' : 'lazy'}
            decoding="async"
          />
        ) : (
          <div className="img-placeholder" aria-hidden="true">
            🧶
          </div>
        )}
        {p.images[1] && (
          <img className="product-card__alt" src={cld(p.images[1], 500)} alt="" loading="lazy" decoding="async" aria-hidden="true" />
        )}
        <span className={`badge ${availability.className} product-card__badge`}>
          {availability.emoji} {availability.label}
        </span>
      </Link>
      <button
        ref={favRef}
        type="button"
        className={`fav-btn${fav ? ' is-fav' : ''}`}
        aria-label={fav ? 'Quitar de favoritos' : 'Agregar a favoritos'}
        aria-pressed={fav}
        onClick={() => {
          const nowFav = toggleFavorite(p.id);
          if (nowFav) effects.burstFrom(favRef.current, 10);
        }}
      >
        <HeartIcon filled={fav} size={20} />
      </button>
      <div className="product-card__body">
        {category && (
          <span className="product-card__cat">
            {category.emoji} {category.name}
          </span>
        )}
        <h3 className="product-card__name">
          <Link to={`/producto/${p.id}`}>{p.name}</Link>
        </h3>
        <div className="product-card__bottom">
          <div>
            <div className="price">{crc(p.price)}</div>
            {p.minDeposit > 0 && <div className="deposit-mini">Adelanto {crc(p.minDeposit)}</div>}
          </div>
          {canQuickAdd ? (
            <button
              ref={addRef}
              type="button"
              className="quick-add"
              aria-label={`Agregar ${p.name} al carrito`}
              onClick={() => {
                add(p.id, 1);
                effects.burstFrom(addRef.current, 14);
                toast(`${p.name} se agregó al carrito`, '🛍️');
              }}
            >
              <CartIcon size={19} />
            </button>
          ) : (
            <Link to={`/producto/${p.id}`} className="quick-add quick-add--link" aria-label={`Ver ${p.name}`}>
              Ver
            </Link>
          )}
        </div>
      </div>
    </article>
  );
}
