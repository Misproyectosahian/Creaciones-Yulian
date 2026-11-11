import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { EmptyState, HeartLoader } from '../components/Bits';
import HeroArt from '../components/HeroArt';
import { WhatsAppIcon } from '../components/Icons';
import ProductCard from '../components/ProductCard';
import { useStore } from '../context/StoreContext';
import { whatsappLink } from '../lib/format';

const STEPS = [
  { emoji: '💝', title: 'Elegí tus favoritos', text: 'Explorá los catálogos y agregá al carrito lo que te enamore.' },
  { emoji: '🧾', title: 'Hacé tu pedido', text: 'Creá tu cuenta y confirmá tu pedido en un minuto.' },
  { emoji: '💸', title: 'Pagá el adelanto', text: 'Por SINPE Móvil. Te mostramos el monto y el número.' },
  { emoji: '🎀', title: 'Seguí tu pedido', text: 'Mirá en tiempo real cómo va tu pedido hasta que llegue a tus manos.' },
];

export default function Home() {
  const { products, categories, settings, loading, error } = useStore();

  const featured = useMemo(() => {
    const f = products.filter((p) => p.featured);
    return (f.length ? f : products).slice(0, 8);
  }, [products]);

  const newest = useMemo(() => products.slice(0, 8), [products]);
  const showNewest = newest.some((p) => !featured.includes(p));

  const countByCategory = useMemo(() => {
    const m = new Map<string, number>();
    for (const p of products) m.set(p.categoryId, (m.get(p.categoryId) ?? 0) + 1);
    return m;
  }, [products]);

  return (
    <>
      <section className="hero">
        <div className="hero__bg" aria-hidden="true">
          {Array.from({ length: 12 }, (_, i) => (
            <span key={i} className="float-heart" style={{ '--i': i } as React.CSSProperties}>
              {i % 3 === 0 ? '💗' : i % 3 === 1 ? '🌸' : '✨'}
            </span>
          ))}
        </div>
        <div className="container hero__inner">
          <div className="hero__text">
            <span className="pill-tag">💗 Hecho a mano en Costa Rica</span>
            <h1 className="hero__title">
              <span className="script">{settings.storeName}</span>
            </h1>
            <p className="hero__tagline">{settings.tagline}</p>
            <div className="hero__cta">
              <Link to="/catalogo" className="btn btn--primary btn--lg">
                Ver catálogo 🌷
              </Link>
              <Link to="/mis-pedidos" className="btn btn--ghost btn--lg">
                Seguir mi pedido
              </Link>
            </div>
            <ul className="hero__perks">
              <li>🧶 100% artesanal</li>
              <li>🌹 Flores que no se marchitan</li>
              <li>💌 Detalles personalizados</li>
            </ul>
          </div>
          <div className="hero__art">
            <HeroArt />
          </div>
        </div>
      </section>

      {error && (
        <div className="container">
          <div className="alert alert--error">{error}</div>
        </div>
      )}

      {categories.length > 0 && (
        <section className="section container">
          <div className="section__head">
            <h2 className="section__title">Catálogos</h2>
            <Link to="/catalogo" className="link-more">
              Ver todo →
            </Link>
          </div>
          <div className="category-grid">
            {categories.map((c, i) => (
              <Link
                key={c.id}
                to={`/catalogo?cat=${c.id}`}
                className="category-card"
                style={{ animationDelay: `${i * 60}ms` }}
              >
                <span className="category-card__emoji" aria-hidden="true">
                  {c.emoji}
                </span>
                <span className="category-card__name">{c.name}</span>
                <span className="category-card__count">
                  {countByCategory.get(c.id) ?? 0} {countByCategory.get(c.id) === 1 ? 'producto' : 'productos'}
                </span>
              </Link>
            ))}
          </div>
        </section>
      )}

      <section className="section container">
        <div className="section__head">
          <h2 className="section__title">{products.some((p) => p.featured) ? 'Favoritos de la casa ⭐' : 'Nuestras creaciones'}</h2>
          <Link to="/catalogo" className="link-more">
            Ver catálogo →
          </Link>
        </div>
        {loading ? (
          <HeartLoader label="Cargando creaciones..." />
        ) : featured.length === 0 ? (
          <EmptyState emoji="🧶" title="Muy pronto, nuevas creaciones" text="Estamos tejiendo cositas lindas para vos. ¡Volvé pronto!" />
        ) : (
          <div className="product-grid">
            {featured.map((p, i) => (
              <ProductCard key={p.id} product={p} index={i} />
            ))}
          </div>
        )}
      </section>

      <section className="section container">
        <h2 className="section__title section__title--center">¿Cómo comprar?</h2>
        <ol className="steps">
          {STEPS.map((s, i) => (
            <li key={s.title} className="step">
              <span className="step__num">{i + 1}</span>
              <span className="step__emoji" aria-hidden="true">
                {s.emoji}
              </span>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </li>
          ))}
        </ol>
      </section>

      {showNewest && !loading && (
        <section className="section container">
          <div className="section__head">
            <h2 className="section__title">Lo más nuevo ✨</h2>
          </div>
          <div className="product-grid">
            {newest.map((p, i) => (
              <ProductCard key={p.id} product={p} index={i} />
            ))}
          </div>
        </section>
      )}

      <section className="section container">
        <div className="about-card">
          <div className="about-card__emoji" aria-hidden="true">
            👩‍🎨
          </div>
          <div>
            <h2 className="section__title">Hecho con amor, puntada a puntada</h2>
            <p>
              {settings.aboutText ||
                `En ${settings.storeName} cada pieza se crea a mano: amigurumis, ramos de flores eternas y detalles en crochet pensados para regalar (o regalarte) algo único. ¿Querés algo personalizado? ¡Escribinos!`}
            </p>
            {settings.whatsapp && (
              <a
                className="btn btn--whatsapp"
                href={whatsappLink(settings.whatsapp, '¡Hola! 💖 Quiero consultar por un pedido personalizado.')}
                target="_blank"
                rel="noreferrer"
              >
                <WhatsAppIcon size={20} /> Escribinos por WhatsApp
              </a>
            )}
          </div>
        </div>
      </section>
    </>
  );
}
