import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { BackLink, EmptyState, PageLoader } from '../components/Bits';
import { CartIcon, ChevronLeft, ChevronRight, CloseIcon, HeartIcon, MinusIcon, PlusIcon, ShareIcon, WhatsAppIcon } from '../components/Icons';
import ProductCard from '../components/ProductCard';
import { MAX_QTY, useCart } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { useToast } from '../context/ToastContext';
import { effects } from '../lib/effects';
import { crc, whatsappLink } from '../lib/format';
import { cld, cldSrcSet } from '../lib/image';
import { AVAILABILITY } from '../lib/status';

export default function ProductPage() {
  const { id = '' } = useParams();
  const navigate = useNavigate();
  const { productsById, products, categoriesById, settings, loading } = useStore();
  const { add, favorites, toggleFavorite } = useCart();
  const { toast, toastError } = useToast();

  const product = productsById.get(id);
  const [active, setActive] = useState(0);
  const [qty, setQty] = useState(1);
  const [option, setOption] = useState('');
  const [note, setNote] = useState('');
  const [optionError, setOptionError] = useState(false);
  const [zoom, setZoom] = useState(false);
  const galleryRef = useRef<HTMLDivElement>(null);
  const addRef = useRef<HTMLButtonElement>(null);
  const favRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    setActive(0);
    setQty(1);
    setOption('');
    setNote('');
    setOptionError(false);
  }, [id]);

  useEffect(() => {
    if (product) document.title = `${product.name} · ${settings.storeName}`;
    return () => {
      document.title = `${settings.storeName} · Crochet y flores eternas`;
    };
  }, [product, settings.storeName]);

  useEffect(() => {
    if (!zoom) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setZoom(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [zoom]);

  const related = useMemo(() => {
    if (!product) return [];
    return products.filter((p) => p.id !== product.id && p.categoryId === product.categoryId).slice(0, 4);
  }, [products, product]);

  if (loading && !product) return <PageLoader />;
  if (!product) {
    return (
      <div className="container">
        <EmptyState
          emoji="🥺"
          title="Este producto no está disponible"
          text="Puede que se haya agotado o ya no esté en el catálogo."
          action={
            <Link to="/catalogo" className="btn btn--primary">
              Ver catálogo
            </Link>
          }
        />
      </div>
    );
  }

  const p = product;
  const images = p.images;
  const category = categoriesById.get(p.categoryId);
  const availability = AVAILABILITY[p.availability];
  const soldOut = p.availability === 'agotado';
  const fav = favorites.has(p.id);

  function goTo(i: number) {
    const n = images.length;
    if (!n) return;
    const next = (i + n) % n;
    setActive(next);
    const el = galleryRef.current;
    if (el) el.scrollTo({ left: el.clientWidth * next, behavior: 'smooth' });
  }

  function onGalleryScroll() {
    const el = galleryRef.current;
    if (!el || !el.clientWidth) return;
    const i = Math.round(el.scrollLeft / el.clientWidth);
    if (i !== active) setActive(i);
  }

  function addToCart(goToCart: boolean) {
    if (soldOut) return;
    if (p.options.length > 0 && !option) {
      setOptionError(true);
      toastError(`Elegí ${p.optionsLabel.toLowerCase()} antes de agregar`);
      return;
    }
    add(p.id, qty, option, note);
    effects.burstFrom(addRef.current, 22);
    if (goToCart) {
      navigate('/carrito');
    } else {
      toast(`${qty > 1 ? `${qty} × ` : ''}${p.name} en tu carrito`, '🛍️');
      setNote('');
    }
  }

  async function share() {
    const url = window.location.href;
    try {
      if (navigator.share) {
        await navigator.share({ title: p.name, text: `Mirá este producto de ${settings.storeName} 💖`, url });
      } else {
        await navigator.clipboard.writeText(url);
        toast('Enlace copiado', '🔗');
      }
    } catch {
      /* la persona canceló */
    }
  }

  return (
    <div className="container product-page">
      <BackLink to={category ? `/catalogo?cat=${category.id}` : '/catalogo'}>{category ? category.name : 'Catálogo'}</BackLink>

      <div className="product-layout">
        {/* Galería */}
        <div className="gallery">
          <div className="gallery__main">
            <div className="gallery__track" ref={galleryRef} onScroll={onGalleryScroll}>
              {images.length === 0 ? (
                <div className="gallery__slide">
                  <div className="img-placeholder img-placeholder--lg">🧶</div>
                </div>
              ) : (
                images.map((src, i) => (
                  <button type="button" className="gallery__slide" key={src + i} onClick={() => setZoom(true)} aria-label="Ver foto en grande">
                    <img
                      src={cld(src, 900)}
                      srcSet={cldSrcSet(src, [600, 900, 1300])}
                      sizes="(max-width: 900px) 100vw, 560px"
                      alt={`${p.name} – foto ${i + 1}`}
                      loading={i === 0 ? 'eager' : 'lazy'}
                      decoding="async"
                    />
                  </button>
                ))
              )}
            </div>
            {images.length > 1 && (
              <>
                <button type="button" className="gallery__nav gallery__nav--prev" onClick={() => goTo(active - 1)} aria-label="Foto anterior">
                  <ChevronLeft />
                </button>
                <button type="button" className="gallery__nav gallery__nav--next" onClick={() => goTo(active + 1)} aria-label="Foto siguiente">
                  <ChevronRight />
                </button>
                <div className="gallery__dots" aria-hidden="true">
                  {images.map((_, i) => (
                    <span key={i} className={i === active ? 'is-active' : ''} />
                  ))}
                </div>
              </>
            )}
            <button
              ref={favRef}
              type="button"
              className={`fav-btn fav-btn--lg${fav ? ' is-fav' : ''}`}
              aria-label={fav ? 'Quitar de favoritos' : 'Agregar a favoritos'}
              aria-pressed={fav}
              onClick={() => {
                if (toggleFavorite(p.id)) effects.burstFrom(favRef.current, 12);
              }}
            >
              <HeartIcon filled={fav} />
            </button>
          </div>
          {images.length > 1 && (
            <div className="gallery__thumbs">
              {images.map((src, i) => (
                <button
                  key={src + i}
                  type="button"
                  className={`gallery__thumb${i === active ? ' is-active' : ''}`}
                  onClick={() => goTo(i)}
                  aria-label={`Ver foto ${i + 1}`}
                >
                  <img src={cld(src, 160)} alt="" loading="lazy" />
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Información */}
        <div className="product-info">
          <div className="product-info__tags">
            {category && (
              <Link to={`/catalogo?cat=${category.id}`} className="badge badge--pink">
                {category.emoji} {category.name}
              </Link>
            )}
            <span className={`badge ${availability.className}`}>
              {availability.emoji} {availability.label}
            </span>
          </div>
          <h1 className="product-info__name">{p.name}</h1>
          <div className="product-info__price">{crc(p.price)}</div>

          <div className="deposit-box">
            <span className="deposit-box__emoji" aria-hidden="true">
              💸
            </span>
            <div>
              {p.minDeposit > 0 ? (
                <>
                  <strong>Adelanto mínimo: {crc(p.minDeposit)}</strong>
                  <p>Se paga por SINPE Móvil para confirmar tu pedido. El resto, al recibirlo.</p>
                </>
              ) : (
                <>
                  <strong>Sin adelanto</strong>
                  <p>Este producto no requiere adelanto para confirmarse.</p>
                </>
              )}
            </div>
          </div>

          {p.leadTime && (
            <p className="lead-time">
              ⏳ Tiempo de elaboración: <strong>{p.leadTime}</strong>
            </p>
          )}

          {p.description && <div className="product-info__desc">{p.description}</div>}

          {!soldOut && (
            <div className="buy-box">
              {p.options.length > 0 && (
                <div className={`field${optionError ? ' has-error' : ''}`}>
                  <span className="field__label">{p.optionsLabel}</span>
                  <div className="chips chips--wrap" role="radiogroup" aria-label={p.optionsLabel}>
                    {p.options.map((o) => (
                      <button
                        key={o}
                        type="button"
                        role="radio"
                        aria-checked={option === o}
                        className={`chip${option === o ? ' is-active' : ''}`}
                        onClick={() => {
                          setOption(o);
                          setOptionError(false);
                        }}
                      >
                        {o}
                      </button>
                    ))}
                  </div>
                  {optionError && <span className="field__error">Elegí una opción 💕</span>}
                </div>
              )}

              <div className="field">
                <label htmlFor="note">
                  Personalización <span className="optional">(opcional)</span>
                </label>
                <textarea
                  id="note"
                  rows={2}
                  maxLength={300}
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="Colores, nombre, dedicatoria, ocasión... ✨"
                />
              </div>

              <div className="buy-box__row">
                <div className="qty" aria-label="Cantidad">
                  <button type="button" onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Menos" disabled={qty <= 1}>
                    <MinusIcon size={18} />
                  </button>
                  <span aria-live="polite">{qty}</span>
                  <button type="button" onClick={() => setQty((q) => Math.min(MAX_QTY, q + 1))} aria-label="Más" disabled={qty >= MAX_QTY}>
                    <PlusIcon size={18} />
                  </button>
                </div>
                <button ref={addRef} type="button" className="btn btn--primary btn--lg btn--grow" onClick={() => addToCart(false)}>
                  <CartIcon size={20} /> Agregar al carrito
                </button>
              </div>
              <button type="button" className="btn btn--ghost btn--block" onClick={() => addToCart(true)}>
                Comprar ahora 💖
              </button>
            </div>
          )}

          {soldOut && (
            <div className="alert alert--soft">
              💤 Este producto está agotado por ahora. {settings.whatsapp ? 'Escribinos y te avisamos cuando vuelva.' : ''}
            </div>
          )}

          <div className="product-info__extra">
            {settings.whatsapp && (
              <a
                className="btn btn--whatsapp btn--sm"
                href={whatsappLink(settings.whatsapp, `¡Hola! 💖 Quiero consultar por "${p.name}": ${window.location.href}`)}
                target="_blank"
                rel="noreferrer"
              >
                <WhatsAppIcon size={18} /> Consultar
              </a>
            )}
            <button type="button" className="btn btn--soft btn--sm" onClick={share}>
              <ShareIcon size={18} /> Compartir
            </button>
          </div>
        </div>
      </div>

      {related.length > 0 && (
        <section className="section">
          <h2 className="section__title">También te puede gustar 💕</h2>
          <div className="product-grid">
            {related.map((r, i) => (
              <ProductCard key={r.id} product={r} index={i} />
            ))}
          </div>
        </section>
      )}

      {zoom && images.length > 0 && (
        <div className="lightbox" role="dialog" aria-modal="true" aria-label={p.name} onClick={() => setZoom(false)}>
          <button type="button" className="lightbox__close" aria-label="Cerrar" onClick={() => setZoom(false)}>
            <CloseIcon />
          </button>
          {images.length > 1 && (
            <button
              type="button"
              className="lightbox__nav lightbox__nav--prev"
              aria-label="Foto anterior"
              onClick={(e) => {
                e.stopPropagation();
                goTo(active - 1);
              }}
            >
              <ChevronLeft />
            </button>
          )}
          <img src={cld(images[active], 1600)} alt={p.name} onClick={(e) => e.stopPropagation()} />
          {images.length > 1 && (
            <button
              type="button"
              className="lightbox__nav lightbox__nav--next"
              aria-label="Foto siguiente"
              onClick={(e) => {
                e.stopPropagation();
                goTo(active + 1);
              }}
            >
              <ChevronRight />
            </button>
          )}
        </div>
      )}
    </div>
  );
}
