import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { collection, doc, getDoc, getDocs, query, where } from 'firebase/firestore/lite';
import { db } from '../lib/firebase';
import { DEFAULT_SETTINGS, parseCategory, parseProduct, parseSettings } from '../lib/parse';
import { loadJson, saveJson } from '../lib/storage';
import type { Category, Product, StoreSettings } from '../lib/types';

interface StoreState {
  products: Product[];
  productsById: Map<string, Product>;
  categories: Category[];
  categoriesById: Map<string, Category>;
  settings: StoreSettings;
  loading: boolean;
  error: string | null;
}

interface StoreCache {
  v: 1;
  savedAt: number;
  products: Product[];
  categories: Category[];
  settings: StoreSettings;
}

const CACHE_KEY = 'cy-store-cache';
const REFRESH_AFTER_MS = 5 * 60 * 1000;

const StoreContext = createContext<StoreState | null>(null);

function readCache(): StoreCache | null {
  const c = loadJson<StoreCache | null>(CACHE_KEY, null);
  return c && c.v === 1 && Array.isArray(c.products) && Array.isArray(c.categories) && c.settings ? c : null;
}

/**
 * Carga los productos visibles, catálogos y ajustes.
 * Muestra al instante lo guardado de la visita anterior y lo actualiza en segundo plano.
 */
export function StoreProvider({ children }: { children: ReactNode }) {
  const [cache] = useState(readCache);
  const [products, setProducts] = useState<Product[]>(cache?.products ?? []);
  const [categories, setCategories] = useState<Category[]>(cache?.categories ?? []);
  const [settings, setSettings] = useState<StoreSettings>(cache ? { ...DEFAULT_SETTINGS, ...cache.settings } : DEFAULT_SETTINGS);
  const [loaded, setLoaded] = useState(!!cache);
  const [error, setError] = useState<string | null>(null);
  const lastFetch = useRef(0);

  const refresh = useCallback(async () => {
    lastFetch.current = Date.now();
    try {
      const [productSnap, categorySnap, settingsSnap] = await Promise.all([
        getDocs(query(collection(db, 'products'), where('active', '==', true))),
        getDocs(collection(db, 'categories')),
        getDoc(doc(db, 'settings', 'store')).catch(() => null),
      ]);
      const nextProducts = productSnap.docs.map((d) => parseProduct(d.id, d.data()));
      nextProducts.sort((a, b) => b.createdAt - a.createdAt);
      const nextCategories = categorySnap.docs.map((d) => parseCategory(d.id, d.data()));
      nextCategories.sort((a, b) => a.order - b.order || a.name.localeCompare(b.name, 'es'));
      const nextSettings = parseSettings(settingsSnap?.data());

      setProducts(nextProducts);
      setCategories(nextCategories);
      setSettings(nextSettings);
      setError(null);
      saveJson(CACHE_KEY, {
        v: 1,
        savedAt: Date.now(),
        products: nextProducts,
        categories: nextCategories,
        settings: nextSettings,
      } satisfies StoreCache);
    } catch (e) {
      console.error(e);
      setError('No pudimos cargar la tienda. Revisá tu conexión e intentá de nuevo.');
    } finally {
      setLoaded(true);
    }
  }, []);

  useEffect(() => {
    refresh();
    // Al volver a la pestaña después de un rato, se actualiza el catálogo
    const onVisible = () => {
      if (document.visibilityState === 'visible' && Date.now() - lastFetch.current > REFRESH_AFTER_MS) refresh();
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => document.removeEventListener('visibilitychange', onVisible);
  }, [refresh]);

  const value = useMemo<StoreState>(
    () => ({
      products,
      productsById: new Map(products.map((p) => [p.id, p])),
      categories,
      categoriesById: new Map(categories.map((c) => [c.id, c])),
      settings,
      loading: !loaded,
      error: products.length ? null : error,
    }),
    [products, categories, settings, loaded, error],
  );

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}

export function useStore(): StoreState {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore debe usarse dentro de StoreProvider');
  return ctx;
}
