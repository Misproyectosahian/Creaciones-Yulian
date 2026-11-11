/** Ilustración del inicio: ramo de flores eternas + ovillo de lana con ganchillo. */
export default function HeroArt() {
  return (
    <svg className="hero-art" viewBox="0 0 420 420" role="img" aria-label="Ramo de flores y ovillo de lana">
      <defs>
        <linearGradient id="ha-paper" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#ffc8de" />
          <stop offset="1" stopColor="#f77fae" />
        </linearGradient>
        <linearGradient id="ha-paper2" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#e2d1ff" />
          <stop offset="1" stopColor="#c9aefc" />
        </linearGradient>
        <radialGradient id="ha-yarn" cx=".35" cy=".35" r=".8">
          <stop offset="0" stopColor="#d9c6ff" />
          <stop offset="1" stopColor="#9b7be0" />
        </radialGradient>
        <radialGradient id="ha-glow" cx=".5" cy=".5" r=".5">
          <stop offset="0" stopColor="#fff" stopOpacity=".9" />
          <stop offset="1" stopColor="#fff" stopOpacity="0" />
        </radialGradient>
      </defs>

      <circle cx="210" cy="210" r="190" fill="url(#ha-glow)" />
      <circle cx="210" cy="215" r="165" fill="#fff5f9" />

      {/* Tallos y hojas */}
      <g stroke="#7fc7a2" strokeWidth="5" strokeLinecap="round" fill="none">
        <path d="M200 300 C195 250 170 210 150 170" />
        <path d="M205 300 C205 240 210 190 215 140" />
        <path d="M210 300 C220 250 245 210 270 175" />
        <path d="M203 300 C190 260 150 245 120 230" />
        <path d="M208 300 C230 265 270 255 300 245" />
      </g>
      <g fill="#9bdcb9">
        <ellipse cx="168" cy="220" rx="16" ry="7" transform="rotate(-35 168 220)" />
        <ellipse cx="245" cy="215" rx="16" ry="7" transform="rotate(35 245 215)" />
        <ellipse cx="210" cy="190" rx="14" ry="6" transform="rotate(-80 210 190)" />
      </g>

      {/* Flores */}
      <g className="hero-art__flowers">
        <g transform="translate(150 165)">
          {[0, 72, 144, 216, 288].map((a) => (
            <ellipse key={a} cx="0" cy="-17" rx="12" ry="18" fill="#ff9fc4" transform={`rotate(${a})`} />
          ))}
          <circle r="10" fill="#ffe08a" />
        </g>
        <g transform="translate(215 130)">
          {[0, 45, 90, 135, 180, 225, 270, 315].map((a) => (
            <ellipse key={a} cx="0" cy="-19" rx="9" ry="17" fill="#c9aefc" transform={`rotate(${a})`} />
          ))}
          <circle r="11" fill="#ffd36e" />
        </g>
        <g transform="translate(272 172)">
          {[0, 72, 144, 216, 288].map((a) => (
            <ellipse key={a} cx="0" cy="-16" rx="12" ry="17" fill="#f77fae" transform={`rotate(${a})`} />
          ))}
          <circle r="9" fill="#fff1b8" />
        </g>
        <g transform="translate(118 228)">
          {[0, 60, 120, 180, 240, 300].map((a) => (
            <circle key={a} cx="0" cy="-11" r="9" fill="#ffd1e3" transform={`rotate(${a})`} />
          ))}
          <circle r="7" fill="#f77fae" />
        </g>
        <g transform="translate(302 242)">
          {[0, 60, 120, 180, 240, 300].map((a) => (
            <circle key={a} cx="0" cy="-11" r="9" fill="#e2d1ff" transform={`rotate(${a})`} />
          ))}
          <circle r="7" fill="#9b7be0" />
        </g>
        {/* Rosa */}
        <g transform="translate(205 205)">
          <circle r="24" fill="#e85d97" />
          <path d="M-12 -4 C-6 -18 10 -16 12 -4 C14 8 -2 14 -8 6 C-12 0 -4 -8 2 -4" stroke="#ffc8de" strokeWidth="3.5" fill="none" strokeLinecap="round" />
        </g>
      </g>

      {/* Papel del ramo */}
      <path d="M135 262 L210 372 L285 262 Z" fill="url(#ha-paper2)" />
      <path d="M150 268 L210 372 L270 268 L245 300 L210 285 L175 300 Z" fill="url(#ha-paper)" />
      {/* Lazo */}
      <g transform="translate(210 318)">
        <path d="M0 0 C-30 -22 -42 6 -18 10 Z" fill="#fff" stroke="#f77fae" strokeWidth="3" />
        <path d="M0 0 C30 -22 42 6 18 10 Z" fill="#fff" stroke="#f77fae" strokeWidth="3" />
        <path d="M-4 4 L-16 34 M4 4 L16 34" stroke="#f77fae" strokeWidth="4" strokeLinecap="round" />
        <circle r="7" fill="#f77fae" />
      </g>

      {/* Ovillo con ganchillo */}
      <g className="hero-art__yarn" transform="translate(330 320)">
        <circle r="44" fill="url(#ha-yarn)" />
        <g stroke="#f1e8ff" strokeWidth="3" fill="none" opacity=".8" strokeLinecap="round">
          <path d="M-38 -14 C-10 -30 20 -26 40 -6" />
          <path d="M-42 4 C-12 -14 22 -10 42 12" />
          <path d="M-34 24 C-8 6 20 10 34 28" />
          <path d="M-14 -40 C-30 -10 -26 20 -6 42" />
        </g>
        <path d="M-40 30 C-70 50 -90 30 -120 50" stroke="#9b7be0" strokeWidth="3" fill="none" strokeLinecap="round" />
        <rect x="-6" y="-80" width="8" height="90" rx="4" fill="#ffd36e" transform="rotate(30)" />
        <circle cx="38" cy="-62" r="5" fill="#ffd36e" />
      </g>

      {/* Corazoncitos */}
      <g className="hero-art__hearts" fill="#f77fae">
        <path d="M70 120 c-6-8 -18-2 -12 7 l12 12 l12-12 c6-9 -6-15 -12-7z" />
        <path d="M352 110 c-4-6 -13-1 -9 5 l9 9 l9-9 c4-6 -5-11 -9-5z" fill="#c9aefc" />
        <path d="M86 320 c-4-6 -13-1 -9 5 l9 9 l9-9 c4-6 -5-11 -9-5z" fill="#ff9fc4" />
        <path d="M330 60 l4 10 l10 4 l-10 4 l-4 10 l-4-10 l-10-4 l10-4z" fill="#ffd36e" />
        <path d="M60 220 l3 8 l8 3 l-8 3 l-3 8 l-3-8 l-8-3 l8-3z" fill="#c9aefc" />
      </g>
    </svg>
  );
}
