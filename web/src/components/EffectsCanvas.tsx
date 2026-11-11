import { useEffect, useRef } from 'react';
import { effects } from '../lib/effects';

/** Lienzo invisible donde se dibujan la estela, los corazones y el confeti. */
export default function EffectsCanvas() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    if (!ref.current) return;
    return effects.mount(ref.current);
  }, []);
  return <canvas ref={ref} className="effects-canvas" aria-hidden="true" />;
}
