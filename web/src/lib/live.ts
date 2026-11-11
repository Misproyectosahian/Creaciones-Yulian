import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { app, useEmulators } from './firebase';

/**
 * Firestore completo (con actualizaciones en vivo). Solo lo importan las páginas
 * de pedidos, que se cargan aparte; así la portada y el catálogo cargan rapidísimo.
 */
export const liveDb = getFirestore(app);

if (useEmulators) connectFirestoreEmulator(liveDb, '127.0.0.1', 8080);
