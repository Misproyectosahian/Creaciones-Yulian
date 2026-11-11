const crcFormat = new Intl.NumberFormat('es-CR', {
  style: 'currency',
  currency: 'CRC',
  maximumFractionDigits: 0,
  minimumFractionDigits: 0,
});

/** 25000 → ₡25 000 */
export const crc = (n: number) => crcFormat.format(Math.round(n));

const dateTime = new Intl.DateTimeFormat('es-CR', { dateStyle: 'long', timeStyle: 'short' });
const shortDate = new Intl.DateTimeFormat('es-CR', { day: 'numeric', month: 'short', year: 'numeric' });
const longDay = new Intl.DateTimeFormat('es-CR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });

export const formatDateTime = (ms: number | null) => (ms ? dateTime.format(ms) : '—');
export const formatShortDate = (ms: number | null) => (ms ? shortDate.format(ms) : '—');

/** "2026-12-24" → "jueves, 24 de diciembre de 2026" */
export function formatIsoDay(iso: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  if (!m) return iso;
  return longDay.format(new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
}

export function timeAgo(ms: number | null): string {
  if (!ms) return 'ahora';
  const diff = Date.now() - ms;
  const min = Math.floor(diff / 60000);
  if (min < 1) return 'hace un momento';
  if (min < 60) return `hace ${min} min`;
  const h = Math.floor(min / 60);
  if (h < 24) return `hace ${h} h`;
  const d = Math.floor(h / 24);
  if (d === 1) return 'ayer';
  if (d < 7) return `hace ${d} días`;
  return formatShortDate(ms);
}

export const onlyDigits = (s: string) => s.replace(/\D/g, '');

/** 88887777 → 8888-7777 */
export function formatPhone(phone: string): string {
  const d = onlyDigits(phone);
  if (d.length === 8) return `${d.slice(0, 4)}-${d.slice(4)}`;
  if (d.length === 11 && d.startsWith('506')) return `+506 ${d.slice(3, 7)}-${d.slice(7)}`;
  return phone;
}

/** Enlace de WhatsApp (agrega 506 a números de Costa Rica de 8 dígitos). */
export function whatsappLink(phone: string, text?: string): string {
  let d = onlyDigits(phone);
  if (d.length === 8) d = '506' + d;
  const q = text ? `?text=${encodeURIComponent(text)}` : '';
  return `https://wa.me/${d}${q}`;
}

/** Quita tildes y pasa a minúsculas para buscar. */
export const normalize = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

export const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;
