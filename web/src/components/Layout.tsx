import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { effects } from '../lib/effects';
import { whatsappLink } from '../lib/format';
import {
  CartIcon,
  FacebookIcon,
  GitHubIcon,
  GridIcon,
  HeartIcon,
  HomeIcon,
  InstagramIcon,
  ReceiptIcon,
  SparkleIcon,
  TikTokIcon,
  UserIcon,
  WhatsAppIcon,
} from './Icons';

function useBump(value: number) {
  const [bump, setBump] = useState(false);
  const prev = useRef(value);
  useEffect(() => {
    if (value > prev.current) {
      setBump(true);
      const t = window.setTimeout(() => setBump(false), 600);
      prev.current = value;
      return () => window.clearTimeout(t);
    }
    prev.current = value;
  }, [value]);
  return bump;
}

export function Logo() {
  const { settings } = useStore();
  return (
    <Link to="/" className="logo" aria-label={`${settings.storeName}, inicio`}>
      <span className="logo__mark" aria-hidden="true">
        <HeartIcon filled size={20} />
      </span>
      <span className="logo__text">{settings.storeName}</span>
    </Link>
  );
}

function Header() {
  const { count } = useCart();
  const { user } = useAuth();
  const bump = useBump(count);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header className={`header${scrolled ? ' header--scrolled' : ''}`}>
      <div className="container header__inner">
        <Logo />
        <nav className="header__nav" aria-label="Principal">
          <NavLink to="/" end>
            Inicio
          </NavLink>
          <NavLink to="/catalogo">Catálogo</NavLink>
          <NavLink to="/mis-pedidos">Mis pedidos</NavLink>
        </nav>
        <div className="header__actions">
          <Link to={user ? '/perfil' : '/ingresar'} className="icon-btn hide-mobile" aria-label={user ? 'Mi cuenta' : 'Ingresar'}>
            <UserIcon />
          </Link>
          <Link to="/carrito" className={`icon-btn icon-btn--cart${bump ? ' is-bumping' : ''}`} aria-label={`Carrito, ${count} productos`}>
            <CartIcon />
            {count > 0 && <span className="cart-count">{count > 99 ? '99+' : count}</span>}
          </Link>
        </div>
      </div>
    </header>
  );
}

function MobileNav() {
  const { count } = useCart();
  const { user } = useAuth();
  const bump = useBump(count);
  return (
    <nav className="mobile-nav" aria-label="Navegación">
      <NavLink to="/" end>
        <HomeIcon />
        <span>Inicio</span>
      </NavLink>
      <NavLink to="/catalogo">
        <GridIcon />
        <span>Catálogo</span>
      </NavLink>
      <NavLink to="/carrito" className={bump ? 'is-bumping' : undefined}>
        <span className="mobile-nav__cart">
          <CartIcon />
          {count > 0 && <span className="cart-count">{count > 99 ? '99+' : count}</span>}
        </span>
        <span>Carrito</span>
      </NavLink>
      <NavLink to="/mis-pedidos">
        <ReceiptIcon />
        <span>Pedidos</span>
      </NavLink>
      <NavLink to={user ? '/perfil' : '/ingresar'}>
        <UserIcon />
        <span>{user ? 'Cuenta' : 'Ingresar'}</span>
      </NavLink>
    </nav>
  );
}

/** Datos del desarrollador de la página (créditos en el pie de página). */
const DEVELOPER = {
  name: 'Ahian Quesada',
  role: 'Desarrollador Full-Stack · Ingeniería en TI (UTN)',
  whatsapp: '89649932',
  github: 'https://github.com/Ahian0',
  skills: ['React', 'Flutter', 'Python', 'Firebase'],
};

function DeveloperCredits() {
  return (
    <aside className="dev-card" aria-label="Desarrollador de esta página">
      <div className="dev-card__avatar" aria-hidden="true">
        AQ
      </div>
      <div className="dev-card__body">
        <span className="dev-card__label">💻 Página desarrollada por</span>
        <h3 className="dev-card__name">{DEVELOPER.name}</h3>
        <p className="dev-card__role">{DEVELOPER.role}</p>
        <p className="dev-card__text">
          ¿Querés una página web o una app como esta para tu negocio? Creo tiendas en línea, apps móviles y sistemas a la medida.
        </p>
        <ul className="dev-card__skills" aria-label="Tecnologías">
          {DEVELOPER.skills.map((s) => (
            <li key={s}>{s}</li>
          ))}
        </ul>
      </div>
      <div className="dev-card__actions">
        <a
          className="btn btn--whatsapp btn--sm"
          href={whatsappLink(DEVELOPER.whatsapp, '¡Hola Ahian! 👋 Vi la página de Creaciones Yulian y me interesa una página o app.')}
          target="_blank"
          rel="noreferrer"
        >
          <WhatsAppIcon size={18} /> Escribime · 8964-9932
        </a>
        <a className="btn btn--soft btn--sm" href={DEVELOPER.github} target="_blank" rel="noreferrer">
          <GitHubIcon size={18} /> GitHub
        </a>
      </div>
    </aside>
  );
}

function Footer() {
  const { settings, categories } = useStore();
  const [effectsOn, setEffectsOn] = useState(effects.userPreference);
  const year = new Date().getFullYear();

  return (
    <footer className="footer">
      <div className="footer__wave" aria-hidden="true" />
      <div className="container footer__grid">
        <div>
          <Logo />
          <p className="footer__tagline">{settings.tagline}</p>
          <div className="socials">
            {settings.whatsapp && (
              <a href={whatsappLink(settings.whatsapp, '¡Hola! 💖 Vi tu tienda y quería consultar algo.')} target="_blank" rel="noreferrer" aria-label="WhatsApp">
                <WhatsAppIcon />
              </a>
            )}
            {settings.instagram && (
              <a href={settings.instagram} target="_blank" rel="noreferrer" aria-label="Instagram">
                <InstagramIcon />
              </a>
            )}
            {settings.facebook && (
              <a href={settings.facebook} target="_blank" rel="noreferrer" aria-label="Facebook">
                <FacebookIcon />
              </a>
            )}
            {settings.tiktok && (
              <a href={settings.tiktok} target="_blank" rel="noreferrer" aria-label="TikTok">
                <TikTokIcon />
              </a>
            )}
          </div>
        </div>
        <div>
          <h3 className="footer__title">Catálogos</h3>
          <ul className="footer__links">
            {categories.slice(0, 6).map((c) => (
              <li key={c.id}>
                <Link to={`/catalogo?cat=${c.id}`}>
                  {c.emoji} {c.name}
                </Link>
              </li>
            ))}
            <li>
              <Link to="/catalogo">✨ Ver todo</Link>
            </li>
          </ul>
        </div>
        <div>
          <h3 className="footer__title">Tu cuenta</h3>
          <ul className="footer__links">
            <li>
              <Link to="/mis-pedidos">🧾 Mis pedidos</Link>
            </li>
            <li>
              <Link to="/carrito">🛍️ Carrito</Link>
            </li>
            <li>
              <Link to="/perfil">👤 Mis datos</Link>
            </li>
          </ul>
        </div>
        <div>
          <h3 className="footer__title">Pagos y entregas</h3>
          <p className="footer__small">💸 SINPE Móvil</p>
          <p className="footer__small">🚚 {settings.deliveryMethods.join(' · ')}</p>
          <button
            type="button"
            className="effects-toggle"
            aria-pressed={effectsOn}
            onClick={() => {
              const next = !effectsOn;
              effects.setEnabled(next);
              setEffectsOn(next);
            }}
          >
            <SparkleIcon size={16} /> Efectos mágicos: {effectsOn ? 'activados' : 'desactivados'}
          </button>
        </div>
      </div>
      <div className="container">
        <DeveloperCredits />
      </div>
      <p className="footer__copy">
        © {year} {settings.storeName} · Hecho a mano con 💖 en Costa Rica
      </p>
    </footer>
  );
}

export function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'instant' as ScrollBehavior });
  }, [pathname]);
  return null;
}

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="app">
      <a href="#contenido" className="skip-link">
        Saltar al contenido
      </a>
      <Header />
      <main id="contenido" className="main">
        {children}
      </main>
      <Footer />
      <MobileNav />
    </div>
  );
}
