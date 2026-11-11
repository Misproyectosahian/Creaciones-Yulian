/**
 * Devuelve una versión optimizada de una foto de Cloudinary
 * (formato moderno, calidad automática y del tamaño justo) para que la web cargue rápido.
 */
export function cld(url: string | undefined, width: number): string {
  if (!url) return '';
  const marker = '/image/upload/';
  const i = url.indexOf(marker);
  if (i < 0 || !url.includes('res.cloudinary.com')) return url;
  const head = url.slice(0, i + marker.length);
  const tail = url.slice(i + marker.length);
  return `${head}f_auto,q_auto,c_limit,w_${width}/${tail}`;
}

/** srcset con varios tamaños para pantallas normales y retina. */
export function cldSrcSet(url: string | undefined, widths: number[]): string | undefined {
  if (!url || !url.includes('res.cloudinary.com')) return undefined;
  return widths.map((w) => `${cld(url, w)} ${w}w`).join(', ');
}
