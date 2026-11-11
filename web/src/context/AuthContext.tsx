import { createContext, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
  type User,
} from 'firebase/auth';
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore/lite';
import { auth, db } from '../lib/firebase';
import { parseProfile } from '../lib/parse';
import type { UserProfile } from '../lib/types';
import { onlyDigits } from '../lib/format';

interface AuthState {
  user: User | null;
  profile: UserProfile | null;
  /** true cuando ya se sabe si hay sesión y se cargó el perfil */
  ready: boolean;
  profileComplete: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: UserProfile & { password: string }) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  saveProfile: (data: Omit<UserProfile, 'email'>) => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function isProfileComplete(p: UserProfile | null): boolean {
  return !!p && p.name.trim().length >= 3 && onlyDigits(p.phone).length >= 8;
}

export function authErrorMessage(e: unknown): string {
  const code = (e as { code?: string })?.code ?? '';
  switch (code) {
    case 'auth/invalid-email':
      return 'El correo no es válido.';
    case 'auth/email-already-in-use':
      return 'Ya existe una cuenta con ese correo. ¿Querés iniciar sesión?';
    case 'auth/weak-password':
      return 'La contraseña es muy débil: usá al menos 6 caracteres.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
    case 'auth/invalid-login-credentials':
      return 'Correo o contraseña incorrectos.';
    case 'auth/too-many-requests':
      return 'Demasiados intentos. Esperá un momento e intentá de nuevo.';
    case 'auth/network-request-failed':
      return 'Sin conexión a internet.';
    case 'auth/user-disabled':
      return 'Esta cuenta está deshabilitada.';
    case 'permission-denied':
      return 'No tenés permiso para hacer esto.';
    default:
      return e instanceof Error && e.message ? e.message : 'Algo salió mal. Intentá de nuevo.';
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [authReady, setAuthReady] = useState(false);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [profileUid, setProfileUid] = useState<string | null>(null);

  useEffect(
    () =>
      onAuthStateChanged(auth, (u) => {
        setUser(u);
        setAuthReady(true);
      }),
    [],
  );

  // Cada vez que guardamos el perfil localmente sube la versión, para que una
  // lectura vieja que llegue tarde no lo sobrescriba.
  const profileVersion = useRef(0);

  useEffect(() => {
    if (!user) {
      setProfile(null);
      setProfileUid(null);
      return;
    }
    const uid = user.uid;
    const version = profileVersion.current;
    let cancelled = false;
    getDoc(doc(db, 'users', uid))
      .then((snap) => {
        if (cancelled || version !== profileVersion.current) return;
        setProfile(parseProfile(snap.data()));
        setProfileUid(uid);
      })
      .catch(() => {
        if (cancelled || version !== profileVersion.current) return;
        setProfile(null);
        setProfileUid(uid);
      });
    return () => {
      cancelled = true;
    };
  }, [user]);

  function setLocalProfile(uid: string, p: UserProfile) {
    profileVersion.current++;
    setProfile(p);
    setProfileUid(uid);
  }

  const ready = authReady && (!user || profileUid === user.uid);

  const value = useMemo<AuthState>(
    () => ({
      user,
      profile,
      ready,
      profileComplete: isProfileComplete(profile),
      async login(email, password) {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      },
      async register({ password, ...data }) {
        const cred = await createUserWithEmailAndPassword(auth, data.email.trim(), password);
        try {
          await updateProfile(cred.user, { displayName: data.name.trim() });
        } catch {
          /* no es crítico */
        }
        const newProfile: UserProfile = {
          name: data.name.trim(),
          phone: onlyDigits(data.phone),
          email: cred.user.email ?? data.email.trim(),
          province: data.province,
          canton: data.canton.trim(),
          district: data.district.trim(),
          address: data.address.trim(),
        };
        await setDoc(doc(db, 'users', cred.user.uid), {
          ...newProfile,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
        setLocalProfile(cred.user.uid, newProfile);
      },
      async logout() {
        await signOut(auth);
      },
      async resetPassword(email) {
        await sendPasswordResetEmail(auth, email.trim());
      },
      async saveProfile(data) {
        const u = auth.currentUser;
        if (!u) throw new Error('Necesitás iniciar sesión.');
        const updated: UserProfile = {
          name: data.name.trim(),
          phone: onlyDigits(data.phone),
          email: u.email ?? '',
          province: data.province,
          canton: data.canton.trim(),
          district: data.district.trim(),
          address: data.address.trim(),
        };
        await setDoc(doc(db, 'users', u.uid), { ...updated, updatedAt: serverTimestamp() }, { merge: true });
        setLocalProfile(u.uid, updated);
        if (u.displayName !== data.name.trim()) {
          updateProfile(u, { displayName: data.name.trim() }).catch(() => undefined);
        }
      },
    }),
    [user, profile, ready],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return ctx;
}
