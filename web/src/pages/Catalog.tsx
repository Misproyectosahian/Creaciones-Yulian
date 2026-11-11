import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { EmptyState, HeartLoader } from '../components/Bits';
import { CloseIcon, FilterIcon, HeartIcon, SearchIcon } from '../components/Icons';
import ProductCard from '../components/ProductCard';
import { useCart } from '../context/CartContext';
import { useStore } from '../context/StoreContext';
import { crc, normalize } from '../lib/format';
import type { Availability } from '../lib/types';

type Sort = 'nuevos' | 'precio-asc' | 'precio-desc' | 'nombre';

const SORTS: { value: Sort; label: string }[] = [
  { value: 'nuevos', label: 'Más nuevos' },
  { value: 'precio-asc', label: 'Precio: menor a mayor' },
  { value: 'precio-desc', label: 'Precio: mayor a menor' },
  { value: 'nombre', label: 'Nombre (A-Z)' },
];

export default function Catalog() {
  const { products, categories, categoriesById, loading, error } = useStore();
  const { favorites } = useCart();
  const [params, setParams] = useSearchParams();
  const [filtersOpen, setFiltersOpen] = useState(false);

  const q = params.get('q') ?? '';
  const cat = params.get('cat') ?? '';
  const sort = (params.get('orden') as Sort) || 'nuevos';
  const disp = (params.get('disp') ?? '') as Availability | '';
  const favOnly = params.get('fav') === '1';
  const min = Number(params.get('min') ?? '') || 0;
  const max = Number(params.get('max') ?? '') || 0;

  const [search, setSearch] = useState(q);
  useEffect(() => setSearch(q), [q]);

  // Búsqueda instantánea (con una pequeña pausa para no saturar el historial)
  useEffect(() => {
    if (search === q) return;
    const t = window.setTimeout(() => update({ q: search }), 250);
    return () => window.clearTimeout(t);
  }, [search]); // eslint-disable-line react-hooks/exhaustive-deps

  function update(changes: Record<string, string>) {
    setParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        for (const [k, v] of Object.entries(changes)) {
          if (v) next.set(k, v);
          else next.delete(k);
        }
        return next;
      },
      { replace: true },
    );
  }

  const priceBounds = useMemo(() => {
    if (!products.length) return { lo: 0, hi: 0 };
    const prices = products.map((p) => p.price);
    return { lo: Math.min(...prices), hi: Math.max(...prices) };
  }, [products]);

  const results = useMemo(() => {
    const words = normalize(q).split(/\s+/).filter(Boolean);
    const list = products.filter((p) => {
      if (cat && p.categoryId !== cat) return false;
      if (disp && p.availability !== disp) return false;
      if (favOnly && !favorites.has(p.id)) return false;
      if (min && p.price < min) return false;
      if (max && p.price > max) return false;
      if (words.length) {
        const hay = normalize(`${p.name} ${p.description} ${categoriesById.get(p.categoryId)?.name ?? ''} ${p.options.join(' ')}`);
        if (!words.every((w) => hay.includes(w))) return false;
      }
      return true;
    });
    const sorted = [...list];
    switch (sort) {
      case 'precio-asc':
        sorted.sort((a, b) => a.price - b.price);
        break;
      case 'precio-desc':
        sorted.sort((a, b) => b.price - a.price);
        break;
      case 'nombre':
        sorted.sort((a, b) => a.name.localeCompare(b.name, 'es'));
        break;
      default:
        sorted.sort((a, b) => b.createdAt - a.createdAt);
    }
    return sorted;
  }, [products, q, cat, disp, favOnly, favorites, min, max, sort, categoriesById]);

  const activeCategory = categoriesById.get(cat);
  const activeFilters = [disp, favOnly, min, max].filter(Boolean).length;
  const hasAnyFilter = !!(q || cat || activeFilters);

  return (
    <div className="container catalog">
      <header className="catalog__head">
        <h1 className="page-title">
          {activeCategory ? (
            <>
              <span aria-hidden="true">{activeCategory.emoji}</span> {activeCategory.name}
            </>
          ) : (
            'Catálogo 🌷'
          )}
        </h1>
        {activeCategory?.description && <p className="page-subtitle">{activeCategory.description}</p>}
        <div className="search-box">
          <SearchIcon />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar ramos, amigurumis, colores..."
            aria-label="Buscar productos"
          />
          {search && (
            <button type="button" className="search-box__clear" aria-label="Borrar búsqueda" onClick={() => setSearch('')}>
              <CloseIcon size={18} />
            </button>
          )}
        </div>
      </header>

      <div className="chips" role="tablist" aria-label="Catálogos">
        <button type="button" role="tab" aria-selected={!cat} className={`chip${!cat ? ' is-active' : ''}`} onClick={() => update({ cat: '' })}>
          ✨ Todo
        </button>
        {categories.map((c) => (
          <button
            key={c.id}
            type="button"
            role="tab"
            aria-selected={cat === c.id}
            className={`chip${cat === c.id ? ' is-active' : ''}`}
            onClick={() => update({ cat: cat === c.id ? '' : c.id })}
          >
            {c.emoji} {c.name}
          </button>
        ))}
      </div>

      <div className="catalog__toolbar">
        <button type="button" className={`btn btn--soft btn--sm${activeFilters ? ' has-dot' : ''}`} onClick={() => setFiltersOpen((v) => !v)} aria-expanded={filtersOpen}>
          <FilterIcon size={18} /> Filtros{activeFilters ? ` (${activeFilters})` : ''}
        </button>
        <span className="catalog__count">
          {loading ? 'Cargando...' : `${results.length} ${results.length === 1 ? 'producto' : 'productos'}`}
        </span>
        <label className="sort-select">
          <span className="sr-only">Ordenar</span>
          <select value={sort} onChange={(e) => update({ orden: e.target.value === 'nuevos' ? '' : e.target.value })}>
            {SORTS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>
      </div>

      {filtersOpen && (
        <div className="filters">
          <div className="filters__group">
            <span className="filters__label">Disponibilidad</span>
            <div className="chips chips--wrap">
              {(
                [
                  ['', 'Todas'],
                  ['disponible', '✅ Disponible'],
                  ['encargo', '🧶 Por encargo'],
                ] as const
              ).map(([value, label]) => (
                <button key={value} type="button" className={`chip chip--sm${disp === value ? ' is-active' : ''}`} onClick={() => update({ disp: value })}>
                  {label}
                </button>
              ))}
            </div>
          </div>
          <div className="filters__group">
            <span className="filters__label">
              Precio {priceBounds.hi > 0 && <small>({crc(priceBounds.lo)} – {crc(priceBounds.hi)})</small>}
            </span>
            <div className="price-range">
              <input
                type="number"
                inputMode="numeric"
                min={0}
                placeholder="Mínimo"
                value={min || ''}
                onChange={(e) => update({ min: e.target.value })}
                aria-label="Precio mínimo"
              />
              <span>—</span>
              <input
                type="number"
                inputMode="numeric"
                min={0}
                placeholder="Máximo"
                value={max || ''}
                onChange={(e) => update({ max: e.target.value })}
                aria-label="Precio máximo"
              />
            </div>
          </div>
          <div className="filters__group">
            <button type="button" className={`chip${favOnly ? ' is-active' : ''}`} onClick={() => update({ fav: favOnly ? '' : '1' })}>
              <HeartIcon size={16} filled={favOnly} /> Solo mis favoritos ({favorites.size})
            </button>
          </div>
          {hasAnyFilter && (
            <button type="button" className="btn btn--link" onClick={() => setParams(new URLSearchParams(), { replace: true })}>
              Limpiar todo
            </button>
          )}
        </div>
      )}

      {error && <div className="alert alert--error">{error}</div>}

      {loading ? (
        <HeartLoader label="Cargando creaciones..." />
      ) : results.length === 0 ? (
        <EmptyState
          emoji={products.length === 0 ? '🧶' : favOnly ? '💔' : '🔍'}
          title={products.length === 0 ? 'Muy pronto, nuevas creaciones' : favOnly ? 'Aún no tenés favoritos aquí' : 'No encontramos nada'}
          text={
            products.length === 0
              ? 'Estamos preparando cositas lindas. ¡Volvé pronto!'
              : favOnly
                ? 'Tocá el corazón de los productos que te gusten para guardarlos.'
                : 'Probá con otras palabras o quitá algunos filtros.'
          }
          action={
            hasAnyFilter ? (
              <button type="button" className="btn btn--primary" onClick={() => setParams(new URLSearchParams(), { replace: true })}>
                Ver todo el catálogo
              </button>
            ) : undefined
          }
        />
      ) : (
        <div className="product-grid">
          {results.map((p, i) => (
            <ProductCard key={p.id} product={p} index={i} />
          ))}
        </div>
      )}
    </div>
  );
}
