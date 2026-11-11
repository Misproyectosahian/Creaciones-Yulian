import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { STATUS } from '../lib/status';
import type { OrderStatus } from '../lib/types';

export function HeartLoader({ label = 'Cargando...' }: { label?: string }) {
  return (
    <div className="loader" role="status">
      <span className="loader__heart" aria-hidden="true">
        💖
      </span>
      <span className="loader__label">{label}</span>
    </div>
  );
}

export function PageLoader() {
  return (
    <div className="page-loader">
      <HeartLoader />
    </div>
  );
}

export function EmptyState({
  emoji,
  title,
  text,
  action,
}: {
  emoji: string;
  title: string;
  text?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="empty">
      <div className="empty__emoji" aria-hidden="true">
        {emoji}
      </div>
      <h2 className="empty__title">{title}</h2>
      {text && <p className="empty__text">{text}</p>}
      {action && <div className="empty__action">{action}</div>}
    </div>
  );
}

export function StatusBadge({ status, large }: { status: OrderStatus; large?: boolean }) {
  const s = STATUS[status];
  return (
    <span className={`status-badge${large ? ' status-badge--lg' : ''}`} style={{ '--c': s.color } as React.CSSProperties}>
      <span aria-hidden="true">{s.emoji}</span> {s.label}
    </span>
  );
}

export function BackLink({ to, children }: { to: string; children: ReactNode }) {
  return (
    <Link to={to} className="back-link">
      ← {children}
    </Link>
  );
}
