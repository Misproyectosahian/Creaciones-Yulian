import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';

interface Toast {
  id: number;
  message: string;
  emoji: string;
  tone: 'ok' | 'error';
}

interface ToastState {
  toast: (message: string, emoji?: string) => void;
  toastError: (message: string) => void;
}

const ToastContext = createContext<ToastState | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const nextId = useRef(1);

  const push = useCallback((message: string, emoji: string, tone: Toast['tone']) => {
    const id = nextId.current++;
    setToasts((prev) => [...prev.slice(-2), { id, message, emoji, tone }]);
    window.setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), tone === 'error' ? 5000 : 3200);
  }, []);

  const value = useMemo<ToastState>(
    () => ({
      toast: (message, emoji = '💖') => push(message, emoji, 'ok'),
      toastError: (message) => push(message, '🥺', 'error'),
    }),
    [push],
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast toast--${t.tone}`}>
            <span className="toast__emoji" aria-hidden="true">
              {t.emoji}
            </span>
            <span>{t.message}</span>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast(): ToastState {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast debe usarse dentro de ToastProvider');
  return ctx;
}
