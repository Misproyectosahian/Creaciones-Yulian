import { loadJson, saveJson } from './storage';

/**
 * Motor de efectos "cute": estela rosa-lila con corazones y destellos donde pasa
 * el dedo o el mouse, explosiones de corazones y lluvia de confeti.
 * Usa un solo <canvas> fijo encima de la página que no bloquea clics ni scroll,
 * y solo anima cuando hay algo que dibujar (no gasta batería en reposo).
 */

type Kind = 'heart' | 'sparkle' | 'dot' | 'confetti' | 'flower';

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  max: number;
  size: number;
  color: string;
  kind: Kind;
  rot: number;
  spin: number;
  gravity: number;
  drag: number;
}

interface TrailPoint {
  x: number;
  y: number;
  life: number;
}

const COLORS = ['#ff9fc4', '#f77fae', '#e85d97', '#c9aefc', '#9b7be0', '#ffe08a', '#7fd8b5', '#ffb5d3'];
const TRAIL_LIFE = 0.45;
const STORAGE_KEY = 'cy-effects';
const TOUCH_OFFSET = 100000;

const rnd = (min: number, max: number) => min + Math.random() * (max - min);
const pick = <T,>(list: T[]) => list[Math.floor(Math.random() * list.length)];

function lerpColor(a: [number, number, number], b: [number, number, number], t: number) {
  return `rgb(${Math.round(a[0] + (b[0] - a[0]) * t)},${Math.round(a[1] + (b[1] - a[1]) * t)},${Math.round(a[2] + (b[2] - a[2]) * t)})`;
}
const LILAC: [number, number, number] = [201, 174, 252];
const PINK: [number, number, number] = [247, 127, 174];

class EffectsEngine {
  private ctx: CanvasRenderingContext2D | null = null;
  private particles: Particle[] = [];
  private trails = new Map<number, TrailPoint[]>();
  private lastSpawn = new Map<number, { x: number; y: number }>();
  private raf = 0;
  private last = 0;
  private w = 0;
  private h = 0;
  private dpr = 1;
  private heart: Path2D | null = null;
  private sparkle: Path2D | null = null;
  private reducedMotion = false;
  private listeners = new Set<(enabled: boolean) => void>();
  private userEnabled = loadJson<boolean>(STORAGE_KEY, true);

  get enabled() {
    return this.userEnabled && !this.reducedMotion;
  }

  get userPreference() {
    return this.userEnabled;
  }

  setEnabled(value: boolean) {
    this.userEnabled = value;
    saveJson(STORAGE_KEY, value);
    if (!value) this.clear();
    this.listeners.forEach((fn) => fn(this.enabled));
  }

  subscribe(fn: (enabled: boolean) => void) {
    this.listeners.add(fn);
    return () => {
      this.listeners.delete(fn);
    };
  }

  mount(canvas: HTMLCanvasElement): () => void {
    this.ctx = canvas.getContext('2d');
    this.heart = this.buildHeart();
    this.sparkle = this.buildSparkle();

    const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
    this.reducedMotion = motion.matches;
    const onMotion = () => {
      this.reducedMotion = motion.matches;
      this.listeners.forEach((fn) => fn(this.enabled));
    };

    const resize = () => {
      this.dpr = Math.min(window.devicePixelRatio || 1, 2);
      this.w = window.innerWidth;
      this.h = window.innerHeight;
      canvas.width = Math.round(this.w * this.dpr);
      canvas.height = Math.round(this.h * this.dpr);
      canvas.style.width = `${this.w}px`;
      canvas.style.height = `${this.h}px`;
    };
    resize();

    const onPointerMove = (e: PointerEvent) => {
      if (e.pointerType === 'touch') return; // el touch se maneja con touchmove
      this.move(e.pointerId, e.clientX, e.clientY);
    };
    const onPointerDown = (e: PointerEvent) => {
      if (e.button > 0) return;
      this.lastSpawn.delete(e.pointerType === 'touch' ? -1 : e.pointerId);
      this.tap(e.clientX, e.clientY);
    };
    const onPointerUp = (e: PointerEvent) => {
      this.lastSpawn.delete(e.pointerId);
    };
    const onTouchMove = (e: TouchEvent) => {
      for (const t of Array.from(e.changedTouches)) this.move(TOUCH_OFFSET + t.identifier, t.clientX, t.clientY);
    };
    const onTouchEnd = (e: TouchEvent) => {
      for (const t of Array.from(e.changedTouches)) this.lastSpawn.delete(TOUCH_OFFSET + t.identifier);
    };

    window.addEventListener('resize', resize);
    window.addEventListener('pointermove', onPointerMove, { passive: true });
    window.addEventListener('pointerdown', onPointerDown, { passive: true });
    window.addEventListener('pointerup', onPointerUp, { passive: true });
    window.addEventListener('touchmove', onTouchMove, { passive: true });
    window.addEventListener('touchend', onTouchEnd, { passive: true });
    window.addEventListener('touchcancel', onTouchEnd, { passive: true });
    motion.addEventListener('change', onMotion);

    return () => {
      window.removeEventListener('resize', resize);
      window.removeEventListener('pointermove', onPointerMove);
      window.removeEventListener('pointerdown', onPointerDown);
      window.removeEventListener('pointerup', onPointerUp);
      window.removeEventListener('touchmove', onTouchMove);
      window.removeEventListener('touchend', onTouchEnd);
      window.removeEventListener('touchcancel', onTouchEnd);
      motion.removeEventListener('change', onMotion);
      cancelAnimationFrame(this.raf);
      this.raf = 0;
      this.ctx = null;
    };
  }

  // ── Interacción ──

  private move(id: number, x: number, y: number) {
    if (!this.enabled || !this.ctx) return;
    let trail = this.trails.get(id);
    if (!trail) {
      trail = [];
      this.trails.set(id, trail);
    }
    trail.push({ x, y, life: TRAIL_LIFE });
    if (trail.length > 48) trail.shift();

    const last = this.lastSpawn.get(id);
    if (!last || Math.hypot(x - last.x, y - last.y) > 22) {
      this.lastSpawn.set(id, { x, y });
      const roll = Math.random();
      const life = rnd(0.6, 1);
      this.particles.push({
        x: x + rnd(-6, 6),
        y: y + rnd(-6, 6),
        vx: rnd(-25, 25),
        vy: rnd(-70, -20),
        life,
        max: life,
        size: rnd(5, 11),
        color: pick(COLORS),
        kind: roll < 0.45 ? 'heart' : roll < 0.8 ? 'sparkle' : 'dot',
        rot: rnd(-0.5, 0.5),
        spin: rnd(-2, 2),
        gravity: -15,
        drag: 0.97,
      });
    }
    this.start();
  }

  private tap(x: number, y: number) {
    if (!this.enabled || !this.ctx) return;
    for (let i = 0; i < 5; i++) {
      const a = rnd(0, Math.PI * 2);
      const s = rnd(40, 110);
      const life = rnd(0.5, 0.8);
      this.particles.push({
        x,
        y,
        vx: Math.cos(a) * s,
        vy: Math.sin(a) * s - 40,
        life,
        max: life,
        size: rnd(6, 10),
        color: pick(COLORS),
        kind: i % 2 === 0 ? 'heart' : 'sparkle',
        rot: rnd(-0.4, 0.4),
        spin: 0,
        gravity: -30,
        drag: 0.96,
      });
    }
    this.start();
  }

  /** Explosión de corazones en un punto de la pantalla. */
  burst(x: number, y: number, count = 16) {
    if (!this.enabled || !this.ctx) return;
    for (let i = 0; i < count; i++) {
      const a = rnd(0, Math.PI * 2);
      const s = rnd(120, 340);
      const life = rnd(0.8, 1.3);
      this.particles.push({
        x,
        y,
        vx: Math.cos(a) * s,
        vy: Math.sin(a) * s - 140,
        life,
        max: life,
        size: rnd(7, 14),
        color: pick(COLORS),
        kind: i % 3 === 0 ? 'sparkle' : i % 5 === 0 ? 'flower' : 'heart',
        rot: rnd(-0.6, 0.6),
        spin: rnd(-3, 3),
        gravity: 440,
        drag: 0.975,
      });
    }
    this.start();
  }

  /** Explosión desde el centro de un elemento (por ejemplo, un botón). */
  burstFrom(el: Element | null, count = 16) {
    if (!el) return;
    const r = el.getBoundingClientRect();
    this.burst(r.left + r.width / 2, r.top + r.height / 2, count);
  }

  /** Lluvia de confeti y corazones. */
  confetti(amount = 130) {
    if (!this.enabled || !this.ctx) return;
    for (let i = 0; i < amount; i++) {
      const roll = Math.random();
      const life = rnd(2.4, 3.6);
      this.particles.push({
        x: rnd(0, this.w),
        y: rnd(-140, -10),
        vx: rnd(-60, 60),
        vy: rnd(90, 260),
        life,
        max: life,
        size: rnd(7, 13),
        color: pick(COLORS),
        kind: roll < 0.55 ? 'confetti' : roll < 0.8 ? 'heart' : roll < 0.92 ? 'flower' : 'sparkle',
        rot: rnd(0, Math.PI),
        spin: rnd(-6, 6),
        gravity: 90,
        drag: 0.995,
      });
    }
    this.start();
  }

  clear() {
    this.particles = [];
    this.trails.clear();
    if (this.ctx) this.ctx.clearRect(0, 0, this.w * this.dpr, this.h * this.dpr);
  }

  // ── Animación ──

  private start() {
    if (!this.raf) {
      this.last = performance.now();
      this.raf = requestAnimationFrame(this.frame);
    }
  }

  private frame = (now: number) => {
    const ctx = this.ctx;
    if (!ctx) {
      this.raf = 0;
      return;
    }
    const dt = Math.min(0.05, (now - this.last) / 1000);
    this.last = now;

    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    ctx.clearRect(0, 0, this.w, this.h);

    // Estela
    ctx.lineCap = 'round';
    for (const [id, trail] of this.trails) {
      for (const p of trail) p.life -= dt;
      while (trail.length && trail[0].life <= 0) trail.shift();
      if (trail.length === 0) {
        this.trails.delete(id);
        continue;
      }
      for (let i = 1; i < trail.length; i++) {
        const a = trail[i - 1];
        const b = trail[i];
        const t = Math.max(0, b.life / TRAIL_LIFE);
        ctx.globalAlpha = 0.65 * t;
        ctx.strokeStyle = lerpColor(LILAC, PINK, i / trail.length);
        ctx.lineWidth = 2 + 7 * t;
        ctx.beginPath();
        ctx.moveTo(a.x, a.y);
        ctx.lineTo(b.x, b.y);
        ctx.stroke();
      }
    }

    // Partículas
    const alive: Particle[] = [];
    for (const p of this.particles) {
      p.vx *= p.drag;
      p.vy = p.vy * p.drag + p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.spin * dt;
      p.life -= dt;
      if (p.life <= 0 || p.y > this.h + 60) continue;
      alive.push(p);

      const t = p.life / p.max;
      ctx.globalAlpha = Math.max(0, Math.min(1, p.kind === 'confetti' ? t * 2.5 : t));
      ctx.fillStyle = p.color;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      switch (p.kind) {
        case 'heart':
          ctx.scale(p.size, p.size);
          if (this.heart) ctx.fill(this.heart);
          break;
        case 'sparkle':
          ctx.scale(p.size * 0.9, p.size * 0.9);
          if (this.sparkle) ctx.fill(this.sparkle);
          break;
        case 'dot':
          ctx.beginPath();
          ctx.arc(0, 0, p.size * 0.35, 0, Math.PI * 2);
          ctx.fill();
          break;
        case 'confetti': {
          const w = p.size * (0.35 + 0.65 * Math.abs(Math.cos(p.rot * 2)));
          ctx.fillRect(-w / 2, -p.size * 0.28, w, p.size * 0.55);
          break;
        }
        case 'flower': {
          const r = p.size * 0.32;
          for (let i = 0; i < 5; i++) {
            const ang = (i * Math.PI * 2) / 5;
            ctx.beginPath();
            ctx.arc(Math.cos(ang) * r, Math.sin(ang) * r, r * 0.85, 0, Math.PI * 2);
            ctx.fill();
          }
          ctx.fillStyle = '#ffe08a';
          ctx.beginPath();
          ctx.arc(0, 0, r * 0.7, 0, Math.PI * 2);
          ctx.fill();
          break;
        }
      }
      ctx.restore();
    }
    this.particles = alive;
    ctx.globalAlpha = 1;

    if (this.particles.length || this.trails.size) {
      this.raf = requestAnimationFrame(this.frame);
    } else {
      ctx.clearRect(0, 0, this.w, this.h);
      this.raf = 0;
    }
  };

  private buildHeart() {
    const p = new Path2D();
    p.moveTo(0, -0.35);
    p.bezierCurveTo(-0.1, -0.8, -1, -0.7, -1, -0.1);
    p.bezierCurveTo(-1, 0.4, -0.3, 0.7, 0, 1);
    p.bezierCurveTo(0.3, 0.7, 1, 0.4, 1, -0.1);
    p.bezierCurveTo(1, -0.7, 0.1, -0.8, 0, -0.35);
    p.closePath();
    return p;
  }

  private buildSparkle() {
    const p = new Path2D();
    p.moveTo(0, -1);
    p.quadraticCurveTo(0, 0, 1, 0);
    p.quadraticCurveTo(0, 0, 0, 1);
    p.quadraticCurveTo(0, 0, -1, 0);
    p.quadraticCurveTo(0, 0, 0, -1);
    p.closePath();
    return p;
  }
}

export const effects = new EffectsEngine();
