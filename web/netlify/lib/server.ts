import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type DecodedIdToken } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

let app: App | undefined;

function firebaseApp(): App {
  if (app) return app;
  const existing = getApps().find((a) => a.name === '[DEFAULT]');
  if (existing) {
    app = existing;
    return app;
  }
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  // Netlify guarda los saltos de línea como "\n" literales
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n').replace(/^"|"$/g, '');
  if (!projectId || !clientEmail || !privateKey) {
    throw new HttpError(500, 'El servidor no está configurado: faltan las variables de Firebase en Netlify.');
  }
  app = initializeApp({ credential: cert({ projectId, clientEmail, privateKey }) });
  return app;
}

export const db = () => getFirestore(firebaseApp());
export const adminAuth = () => getAuth(firebaseApp());
export const messaging = () => getMessaging(firebaseApp());

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      ...CORS_HEADERS,
    },
  });
}

/** Verifica la sesión de Firebase enviada en el encabezado Authorization. */
export async function requireUser(req: Request): Promise<DecodedIdToken> {
  const header = req.headers.get('authorization') ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError(401, 'Necesitás iniciar sesión.');
  try {
    return await adminAuth().verifyIdToken(match[1]);
  } catch {
    throw new HttpError(401, 'Tu sesión expiró. Volvé a iniciar sesión.');
  }
}

/** Igual que requireUser, pero además exige que la cuenta sea administradora. */
export async function requireAdmin(req: Request): Promise<DecodedIdToken> {
  const user = await requireUser(req);
  const snap = await db().collection('admins').doc(user.uid).get();
  if (!snap.exists) throw new HttpError(403, 'Esta cuenta no es de administración.');
  return user;
}

/** Envuelve una función: solo POST, errores en JSON y en español. */
export function handler(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS_HEADERS });
    if (req.method !== 'POST') return json({ error: 'Método no permitido.' }, 405);
    try {
      return await fn(req);
    } catch (e) {
      if (e instanceof HttpError) return json({ error: e.message }, e.status);
      console.error(e);
      return json({ error: 'Ocurrió un error inesperado. Intentá de nuevo en un momento.' }, 500);
    }
  };
}

export async function readJson(req: Request): Promise<Record<string, unknown>> {
  try {
    const body = await req.json();
    if (body && typeof body === 'object' && !Array.isArray(body)) return body as Record<string, unknown>;
  } catch {
    /* cuerpo vacío o inválido */
  }
  return {};
}

const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** Envía una notificación push a todos los celulares de administración. */
export async function notifyAdmins(message: {
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<number> {
  const devices = await db().collection('adminDevices').get();
  const tokens = devices.docs
    .map((d) => {
      const t = d.get('token');
      return typeof t === 'string' && t ? t : d.id;
    })
    .filter(Boolean);
  if (tokens.length === 0) return 0;

  let sent = 0;
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const res = await messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title: message.title, body: message.body },
      data: message.data ?? {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'pedidos',
          icon: 'ic_stat_heart',
          color: '#E85D97',
          sound: 'default',
        },
      },
    });
    sent += res.successCount;
    const stale = res.responses
      .map((r, idx) => (r.error && STALE_TOKEN_CODES.has(r.error.code) ? chunk[idx] : null))
      .filter((t): t is string => t !== null);
    await Promise.all(
      stale.map((t) =>
        db()
          .collection('adminDevices')
          .doc(t)
          .delete()
          .catch(() => undefined),
      ),
    );
  }
  return sent;
}
