import { PROVINCES } from '../lib/costaRica';

export interface ProfileForm {
  name: string;
  phone: string;
  province: string;
  canton: string;
  district: string;
  address: string;
}

export const EMPTY_PROFILE_FORM: ProfileForm = {
  name: '',
  phone: '',
  province: '',
  canton: '',
  district: '',
  address: '',
};

export function validateProfile(f: ProfileForm): Partial<Record<keyof ProfileForm, string>> {
  const errors: Partial<Record<keyof ProfileForm, string>> = {};
  if (f.name.trim().length < 3) errors.name = 'Escribí tu nombre completo';
  const digits = f.phone.replace(/\D/g, '');
  if (digits.length < 8 || digits.length > 15) errors.phone = 'Escribí un teléfono válido (8 dígitos)';
  if (!f.province) errors.province = 'Elegí tu provincia';
  if (f.canton.trim().length < 2) errors.canton = 'Escribí tu cantón';
  return errors;
}

/** Campos de datos personales (registro y "Mis datos"). */
export default function ProfileFields({
  value,
  onChange,
  errors,
}: {
  value: ProfileForm;
  onChange: (v: ProfileForm) => void;
  errors: Partial<Record<keyof ProfileForm, string>>;
}) {
  const set = (key: keyof ProfileForm) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    onChange({ ...value, [key]: e.target.value });

  return (
    <>
      <div className="field">
        <label htmlFor="pf-name">Nombre completo</label>
        <input id="pf-name" autoComplete="name" value={value.name} onChange={set('name')} maxLength={80} aria-invalid={!!errors.name} placeholder="Ej: María Fernanda Rojas" />
        {errors.name && <span className="field__error">{errors.name}</span>}
      </div>
      <div className="field">
        <label htmlFor="pf-phone">Teléfono / WhatsApp</label>
        <input
          id="pf-phone"
          type="tel"
          inputMode="tel"
          autoComplete="tel"
          value={value.phone}
          onChange={set('phone')}
          maxLength={20}
          aria-invalid={!!errors.phone}
          placeholder="8888-8888"
        />
        {errors.phone && <span className="field__error">{errors.phone}</span>}
      </div>
      <div className="field-row">
        <div className="field">
          <label htmlFor="pf-province">Provincia</label>
          <select id="pf-province" autoComplete="address-level1" value={value.province} onChange={set('province')} aria-invalid={!!errors.province}>
            <option value="">Elegí...</option>
            {PROVINCES.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
          {errors.province && <span className="field__error">{errors.province}</span>}
        </div>
        <div className="field">
          <label htmlFor="pf-canton">Cantón</label>
          <input id="pf-canton" autoComplete="address-level2" value={value.canton} onChange={set('canton')} maxLength={60} aria-invalid={!!errors.canton} placeholder="Ej: Escazú" />
          {errors.canton && <span className="field__error">{errors.canton}</span>}
        </div>
      </div>
      <div className="field">
        <label htmlFor="pf-district">
          Distrito <span className="optional">(opcional)</span>
        </label>
        <input id="pf-district" autoComplete="address-level3" value={value.district} onChange={set('district')} maxLength={60} placeholder="Ej: San Rafael" />
      </div>
      <div className="field">
        <label htmlFor="pf-address">
          Dirección / señas <span className="optional">(para entregas)</span>
        </label>
        <textarea
          id="pf-address"
          rows={2}
          autoComplete="street-address"
          value={value.address}
          onChange={set('address')}
          maxLength={400}
          placeholder="Ej: 200 m norte de la iglesia, casa rosada 🌸"
        />
      </div>
    </>
  );
}
