import { Link } from 'react-router-dom';
import { EmptyState } from '../components/Bits';

export function NotFoundPage() {
  return (
    <div className="container">
      <EmptyState
        emoji="🧶"
        title="Ups, esta página se destejió"
        text="No encontramos lo que buscabas."
        action={
          <Link to="/" className="btn btn--primary">
            Volver al inicio
          </Link>
        }
      />
    </div>
  );
}

/** Se muestra si faltan las variables de Firebase (VITE_FIREBASE_...). */
export function SetupNeededPage() {
  return (
    <div className="setup">
      <div className="auth-card">
        <div className="auth-card__emoji">🧶</div>
        <h1 className="page-title">Falta un pasito</h1>
        <p>
          La tienda todavía no está conectada a Firebase. Agregá las variables <code>VITE_FIREBASE_…</code> en Netlify
          (Site configuration → Environment variables) y volvé a publicar.
        </p>
        <p className="muted">Revisá el archivo LEEME.md del proyecto, sección “Página web”.</p>
      </div>
    </div>
  );
}
