import { initializeApp } from 'firebase/app';
import { browserLocalPersistence, connectAuthEmulator, indexedDBLocalPersistence, initializeAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore/lite';

const env = import.meta.env;

const config = {
  apiKey: env.VITE_FIREBASE_API_KEY ?? '',
  authDomain: env.VITE_FIREBASE_AUTH_DOMAIN ?? '',
  projectId: env.VITE_FIREBASE_PROJECT_ID ?? '',
  storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET ?? '',
  messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '',
  appId: env.VITE_FIREBASE_APP_ID ?? '',
};

/** true si las variables de Firebase están configuradas. */
export const firebaseConfigured = Boolean(config.apiKey && config.projectId && config.appId);

// Si falta la configuración se usan valores de relleno para que nada se caiga;
// la app muestra una pantalla de "configuración pendiente".
export const app = initializeApp(
  firebaseConfigured ? config : { ...config, apiKey: 'sin-configurar', projectId: 'sin-configurar', appId: 'sin-configurar' },
);

// initializeAuth (en vez de getAuth) evita cargar el código de ventanas emergentes
// de Google/Facebook que no usamos: la web pesa menos.
export const auth = initializeAuth(app, {
  persistence: [indexedDBLocalPersistence, browserLocalPersistence],
});
auth.languageCode = 'es';

/**
 * Firestore "lite": versión liviana (~30 KB) para el catálogo y los datos del cliente.
 * Las páginas de pedidos usan la versión completa en vivo (ver live.ts), que se
 * descarga solo cuando se abren.
 */
export const db = getFirestore(app);

/** Solo en desarrollo: usar los emuladores locales de Firebase (VITE_USE_EMULATORS=true). */
export const useEmulators = import.meta.env.DEV && env.VITE_USE_EMULATORS === 'true';
if (useEmulators) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
}
