import { useState } from 'react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import ProfileFields, { EMPTY_PROFILE_FORM, validateProfile, type ProfileForm } from '../components/ProfileFields';
import { authErrorMessage, useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import { effects } from '../lib/effects';
import { PageLoader } from '../components/Bits';

/** Solo permite volver a rutas internas (evita redirecciones a otros sitios). */
function safeReturn(raw: string | null): string {
  if (!raw || !raw.startsWith('/') || raw.startsWith('//')) return '/mis-pedidos';
  return raw;
}

function AuthShell({ emoji, title, subtitle, children }: { emoji: string; title: string; subtitle: string; children: React.ReactNode }) {
  return (
    <div className="container auth">
      <div className="auth-card">
        <div className="auth-card__emoji" aria-hidden="true">
          {emoji}
        </div>
        <h1 className="page-title">{title}</h1>
        <p className="muted">{subtitle}</p>
        {children}
      </div>
    </div>
  );
}

export function LoginPage() {
  const { login, user, ready } = useAuth();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const back = safeReturn(params.get('volver'));
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (!ready) return <PageLoader />;
  if (user && !busy) return <Navigate to={back} replace />;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await login(email, password);
      effects.confetti(80);
      navigate(back, { replace: true });
    } catch (err) {
      setError(authErrorMessage(err));
      setBusy(false);
    }
  }

  return (
    <AuthShell emoji="🌸" title="¡Hola de nuevo!" subtitle="Ingresá para hacer pedidos y ver cómo van.">
      <form className="form" onSubmit={submit}>
        <div className="field">
          <label htmlFor="login-email">Correo</label>
          <input id="login-email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="login-pass">Contraseña</label>
          <input
            id="login-pass"
            type="password"
            autoComplete="current-password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>
        {error && (
          <div className="alert alert--error" role="alert">
            {error}
          </div>
        )}
        <button type="submit" className="btn btn--primary btn--lg btn--block" disabled={busy}>
          {busy ? 'Ingresando...' : 'Ingresar 💖'}
        </button>
        <Link to="/recuperar" className="btn btn--link btn--block">
          ¿Olvidaste tu contraseña?
        </Link>
      </form>
      <p className="auth__switch">
        ¿Primera vez por aquí?{' '}
        <Link to={`/registro?volver=${encodeURIComponent(back)}`} className="link-strong">
          Creá tu cuenta
        </Link>
      </p>
    </AuthShell>
  );
}

export function RegisterPage() {
  const { register, user, ready } = useAuth();
  const { toast } = useToast();
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const back = safeReturn(params.get('volver'));
  const [form, setForm] = useState<ProfileForm>(EMPTY_PROFILE_FORM);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [password2, setPassword2] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (!ready) return <PageLoader />;
  if (user && !busy) return <Navigate to={back} replace />;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const v: Record<string, string> = { ...validateProfile(form) };
    if (!/^\S+@\S+\.\S+$/.test(email.trim())) v.email = 'Escribí un correo válido';
    if (password.length < 6) v.password = 'Mínimo 6 caracteres';
    if (password !== password2) v.password2 = 'Las contraseñas no coinciden';
    setErrors(v);
    if (Object.keys(v).length) {
      setError('Revisá los campos marcados ✏️');
      return;
    }
    setBusy(true);
    try {
      await register({ ...form, email, password });
      effects.confetti(160);
      toast(`¡Bienvenida/o, ${form.name.trim().split(/\s+/)[0]}!`, '🎉');
      navigate(back, { replace: true });
    } catch (err) {
      setError(authErrorMessage(err));
      setBusy(false);
    }
  }

  return (
    <AuthShell emoji="🧶" title="Creá tu cuenta" subtitle="Así podemos contactarte sobre tus pedidos y podés ver su estado.">
      <form className="form" onSubmit={submit} noValidate>
        <ProfileFields value={form} onChange={setForm} errors={errors} />
        <div className="field">
          <label htmlFor="reg-email">Correo</label>
          <input id="reg-email" type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} aria-invalid={!!errors.email} />
          {errors.email && <span className="field__error">{errors.email}</span>}
        </div>
        <div className="field-row">
          <div className="field">
            <label htmlFor="reg-pass">Contraseña</label>
            <input
              id="reg-pass"
              type="password"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              aria-invalid={!!errors.password}
            />
            {errors.password && <span className="field__error">{errors.password}</span>}
          </div>
          <div className="field">
            <label htmlFor="reg-pass2">Repetir contraseña</label>
            <input
              id="reg-pass2"
              type="password"
              autoComplete="new-password"
              value={password2}
              onChange={(e) => setPassword2(e.target.value)}
              aria-invalid={!!errors.password2}
            />
            {errors.password2 && <span className="field__error">{errors.password2}</span>}
          </div>
        </div>
        {error && (
          <div className="alert alert--error" role="alert">
            {error}
          </div>
        )}
        <button type="submit" className="btn btn--primary btn--lg btn--block" disabled={busy}>
          {busy ? 'Creando tu cuenta...' : 'Crear cuenta 💖'}
        </button>
      </form>
      <p className="auth__switch">
        ¿Ya tenés cuenta?{' '}
        <Link to={`/ingresar?volver=${encodeURIComponent(back)}`} className="link-strong">
          Ingresá
        </Link>
      </p>
    </AuthShell>
  );
}

export function ForgotPasswordPage() {
  const { resetPassword } = useAuth();
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await resetPassword(email);
      setSent(true);
    } catch (err) {
      setError(authErrorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthShell emoji="🔑" title="Recuperar contraseña" subtitle="Te enviaremos un correo para crear una contraseña nueva.">
      {sent ? (
        <div className="alert alert--ok">
          📬 ¡Listo! Si existe una cuenta con <strong>{email}</strong>, te llegará un correo en unos minutos. Revisá también la carpeta de spam.
        </div>
      ) : (
        <form className="form" onSubmit={submit}>
          <div className="field">
            <label htmlFor="fp-email">Correo</label>
            <input id="fp-email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          {error && (
            <div className="alert alert--error" role="alert">
              {error}
            </div>
          )}
          <button type="submit" className="btn btn--primary btn--lg btn--block" disabled={busy}>
            {busy ? 'Enviando...' : 'Enviar correo'}
          </button>
        </form>
      )}
      <p className="auth__switch">
        <Link to="/ingresar" className="link-strong">
          ← Volver a ingresar
        </Link>
      </p>
    </AuthShell>
  );
}
