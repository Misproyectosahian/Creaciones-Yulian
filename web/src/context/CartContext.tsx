import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { loadJson, saveJson } from '../lib/storage';

export const MAX_QTY = 20;

export interface CartItem {
  key: string;
  productId: string;
  qty: number;
  option: string;
  note: string;
}

interface CartState {
  items: CartItem[];
  count: number;
  add: (productId: string, qty: number, option?: string, note?: string) => void;
  setQty: (key: string, qty: number) => void;
  remove: (key: string) => void;
  clear: () => void;
  favorites: Set<string>;
  toggleFavorite: (productId: string) => boolean;
}

const CART_KEY = 'cy-cart-v1';
const FAV_KEY = 'cy-favs-v1';

const CartContext = createContext<CartState | null>(null);

function sanitize(raw: unknown): CartItem[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((i): i is CartItem => !!i && typeof i === 'object' && typeof (i as CartItem).productId === 'string')
    .map((i) => ({
      key: String(i.key || `${i.productId}|${i.option ?? ''}|${i.note ?? ''}`),
      productId: i.productId,
      qty: Math.min(MAX_QTY, Math.max(1, Math.floor(Number(i.qty) || 1))),
      option: typeof i.option === 'string' ? i.option : '',
      note: typeof i.note === 'string' ? i.note : '',
    }));
}

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>(() => sanitize(loadJson<unknown>(CART_KEY, [])));
  const [favorites, setFavorites] = useState<Set<string>>(
    () => new Set(loadJson<unknown[]>(FAV_KEY, []).filter((x): x is string => typeof x === 'string')),
  );

  useEffect(() => saveJson(CART_KEY, items), [items]);
  useEffect(() => saveJson(FAV_KEY, [...favorites]), [favorites]);

  // Sincroniza el carrito entre pestañas abiertas
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === CART_KEY) setItems(sanitize(loadJson<unknown>(CART_KEY, [])));
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  const add = useCallback((productId: string, qty: number, option = '', note = '') => {
    const cleanNote = note.trim().slice(0, 300);
    const key = `${productId}|${option}|${cleanNote}`;
    setItems((prev) => {
      const existing = prev.find((i) => i.key === key);
      if (existing) {
        return prev.map((i) => (i.key === key ? { ...i, qty: Math.min(MAX_QTY, i.qty + qty) } : i));
      }
      return [...prev, { key, productId, qty: Math.min(MAX_QTY, Math.max(1, qty)), option, note: cleanNote }];
    });
  }, []);

  const setQty = useCallback((key: string, qty: number) => {
    setItems((prev) => prev.map((i) => (i.key === key ? { ...i, qty: Math.min(MAX_QTY, Math.max(1, qty)) } : i)));
  }, []);

  const remove = useCallback((key: string) => setItems((prev) => prev.filter((i) => i.key !== key)), []);
  const clear = useCallback(() => setItems([]), []);

  const toggleFavorite = useCallback(
    (productId: string) => {
      const nowFav = !favorites.has(productId);
      setFavorites((prev) => {
        const next = new Set(prev);
        if (nowFav) next.add(productId);
        else next.delete(productId);
        return next;
      });
      return nowFav;
    },
    [favorites],
  );

  const value = useMemo<CartState>(
    () => ({
      items,
      count: items.reduce((s, i) => s + i.qty, 0),
      add,
      setQty,
      remove,
      clear,
      favorites,
      toggleFavorite,
    }),
    [items, favorites, add, setQty, remove, clear, toggleFavorite],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartState {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart debe usarse dentro de CartProvider');
  return ctx;
}
