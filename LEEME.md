# 🧶 Creaciones Yulian

Tienda en línea de crochet, ramos y flores eternas, con:

- **Página web** (`web/`) para clientes, en **Netlify**: catálogos, búsqueda, filtros, favoritos, carrito, cuentas, pedidos y **seguimiento en vivo** del pedido.
- **App de administración** (`admin_app/`) en **Flutter** para Android: crear/editar productos con fotos, ver pedidos con los datos del cliente, cambiar estados, registrar pagos y recibir **notificaciones de pedidos nuevos**.

Todo funciona con planes **gratuitos y sin tarjeta de crédito**:

| Servicio | Para qué | Plan |
|---|---|---|
| Firebase (Spark) | Cuentas, base de datos y notificaciones push | Gratis |
| Cloudinary | Fotos de los productos (las optimiza para que la web cargue rápido) | Gratis |
| Netlify | Publicar la web y las funciones del servidor | Gratis |

---

## Cómo funciona

```
 Cliente (web)                 Netlify Functions                 App de Yulian
 ─────────────                 ─────────────────                 ─────────────
 Ve productos  ◄── Firestore (en vivo) ──────────────────────►  Crea/edita productos
 Hace pedido   ──►  create-order: valida precios reales,         Recibe notificación 🔔
                    crea el pedido CY-0001 y avisa  ───── FCM ─►  Ve nombre, teléfono,
 Ve su estado  ◄── Firestore (en vivo) ◄──────────────────────   dirección; cambia estado
                                                                  Sube fotos ──► Cloudinary
```

- Los **precios y adelantos los calcula el servidor** desde la base de datos: nadie puede alterar el precio desde el navegador.
- Cada pedido guarda una copia de los datos del cliente (nombre, teléfono, correo, provincia, cantón, dirección).
- Estados del pedido: **Pendiente de pago → Pago recibido → Pedido en proceso → Listo para entregar → En camino → Entregado** (o Cancelado). El cliente ve cada cambio al instante, con confeti 🎉.
- Cada producto tiene **"Monto mínimo de adelanto"**, que se muestra en la web y se suma en el carrito y en el pedido.

---

## Guía de instalación (paso a paso)

> Tiempo aproximado: 45–60 minutos la primera vez.

### 1. Firebase

1. Entrá a <https://console.firebase.google.com> → **Agregar proyecto** (por ejemplo `creaciones-yulian`). Google Analytics no es necesario.
2. **Authentication** → *Comenzar* → *Método de acceso* → habilitá **Correo electrónico/contraseña**.
3. **Firestore Database** → *Crear base de datos* → modo **producción** → ubicación `nam5 (us-central)` o la más cercana.
4. **Reglas de seguridad**: en esta carpeta del proyecto, ejecutá:
   ```bash
   firebase login
   firebase deploy --only firestore --project creaciones-yulian
   ```
   (También podés copiar el contenido de `firebase/firestore.rules` en *Firestore → Reglas* y publicar.)
5. **App web**: ⚙️ *Configuración del proyecto* → *Tus apps* → ícono `</>` → registrá la app (sin Hosting). Copiá los valores de `firebaseConfig`: los vas a usar en Netlify (paso 3).

   Valores de este proyecto (son públicos, no son secretos; `measurementId` y Analytics no se usan):

   ```js
   apiKey: "AIzaSyAgXuxCGq4y9oXuOJLX9HFlSDQzmtfZANA",
   authDomain: "creaciones-yulian.firebaseapp.com",
   projectId: "creaciones-yulian",
   storageBucket: "creaciones-yulian.firebasestorage.app",
   messagingSenderId: "172585350184",
   appId: "1:172585350184:web:01dd7ba2120f6df946b11d",
   ```

6. **Cuenta de servicio** (para el servidor): ⚙️ *Configuración del proyecto* → *Cuentas de servicio* → **Generar nueva clave privada**. Se descarga un `.json`. **No lo subas a GitHub ni lo compartas.**

### 2. Cloudinary (fotos)

1. Creá una cuenta gratis en <https://cloudinary.com>.
2. En el *Dashboard* (o *Settings → API Keys*) copiá **Cloud name**, **API Key** y **API Secret**.
   Cloud name de este proyecto: `m1hrg07f` (no es secreto).
   ⚠️ **El API Key y el API Secret NO se escriben en este archivo** (se sube a GitHub): van solo en Netlify (paso 3).

### 3. Netlify (página web)

1. Subí esta carpeta a un repositorio de **GitHub** (privado está bien).
2. En <https://app.netlify.com> → *Add new site* → *Import an existing project* → elegí el repositorio. Netlify lee `netlify.toml` solito (carpeta `web`, comando `npm run build`).
3. Antes de publicar, en *Site configuration → Environment variables* agregá:

   | Variable | Valor |
   |---|---|
   | `VITE_FIREBASE_API_KEY` | `apiKey` de la app web |
   | `VITE_FIREBASE_AUTH_DOMAIN` | `authDomain` |
   | `VITE_FIREBASE_PROJECT_ID` | `projectId` |
   | `VITE_FIREBASE_STORAGE_BUCKET` | `storageBucket` |
   | `VITE_FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` |
   | `VITE_FIREBASE_APP_ID` | `appId` |
   | `FIREBASE_PROJECT_ID` | `project_id` del `.json` de la cuenta de servicio |
   | `FIREBASE_CLIENT_EMAIL` | `client_email` del `.json` |
   | `FIREBASE_PRIVATE_KEY` | `private_key` del `.json` (completa, con `-----BEGIN PRIVATE KEY-----` y `-----END PRIVATE KEY-----`) |
   | `CLOUDINARY_CLOUD_NAME` | Cloud name |
   | `CLOUDINARY_API_KEY` | API Key |
   | `CLOUDINARY_API_SECRET` | API Secret |

4. *Deploy*. Al terminar tendrás una dirección como `https://creaciones-yulian.netlify.app` (podés cambiar el nombre en *Site configuration → Change site name*, o conectar un dominio propio).
5. En Firebase → *Authentication → Configuración → Dominios autorizados*, agregá tu dominio de Netlify (por ejemplo `creaciones-yulian.netlify.app`).

### 4. Cuenta de administradora

1. Firebase → *Authentication → Users* → **Agregar usuario**: el correo y contraseña con los que tu amiga va a entrar a la app.
2. Copiá el **UID** de ese usuario.
3. Firestore → *Iniciar colección* → ID `admins` → ID del documento: **el UID** → agregá un campo `nombre` = `Yulian` → Guardar.

¡Listo! Esa cuenta ya puede usar la app. (Si entra con otra cuenta, la app le muestra el UID que habría que agregar.)

### 5. App móvil (Flutter, Android)

Requisitos: Flutter instalado (`flutter doctor`) y Android SDK.

```bash
cd admin_app

# 1) Conectar la app con Firebase (crea lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure --project=TU_ID_DE_PROYECTO --platforms=android

# 2) Generar el instalador (APK) con la dirección de tu web de Netlify
flutter build apk --release --dart-define=API_BASE_URL=https://TU-SITIO.netlify.app
```

> También podés cambiar la dirección por defecto en `admin_app/lib/config.dart` y compilar sin `--dart-define`.

> 💡 Para un instalador más liviano (~18 MB en vez de ~46 MB) agregá `--split-per-abi` y usá el archivo `app-arm64-v8a-release.apk` (sirve para casi todos los celulares de los últimos años).

El instalador queda en `admin_app/build/app/outputs/flutter-apk/app-release.apk`. Pasalo al celular de tu amiga (WhatsApp, Drive o cable), abrilo y aceptá "instalar apps de origen desconocido". La primera vez que entre, la app le pedirá permiso para **notificaciones**: tiene que aceptar.

En *Ajustes* de la app hay un botón **"Enviar notificación de prueba"** para confirmar que todo está bien conectado.

### 6. Primeros pasos en la app

1. **Ajustes**: número de **SINPE Móvil** y a nombre de quién, **WhatsApp**, redes sociales, formas de entrega y el texto "Sobre mí". Esto aparece en la web.
2. **Catálogos**: creá los grupos (ej. 💐 Ramos eternos, 🧸 Amigurumis, 🔑 Llaveros). Se pueden reordenar arrastrando.
3. **Productos**: fotos, nombre, descripción, precio, **monto mínimo de adelanto**, catálogo, disponibilidad (Disponible / Por encargo / Agotado), tiempo de elaboración, opciones (colores, tamaños) y si es **Destacado** (sale en la portada).

---

## El día a día

1. Un cliente hace un pedido en la web → a la app llega una notificación **"🧶 ¡Nuevo pedido CY-0007!"**.
2. El cliente ve en su pedido el monto del adelanto y el número de SINPE, y puede enviar el comprobante por WhatsApp con un botón.
3. En la app: **Registrar pago** (monto recibido) → la app sugiere pasar a **"Pago recibido"**.
4. Cambiar el estado a **"Pedido en proceso"**, **"Listo para entregar"**, etc. Cada cambio se ve en la web al instante. Después de cada cambio aparece **"Avisar 💬"** para mandarle al cliente un WhatsApp ya escrito con el enlace de seguimiento.
5. "Mensaje para el cliente": un texto que el cliente ve en su página del pedido.

---

## Probar en tu computadora

```bash
cd web
cp .env.example .env      # y completá los valores
npm install
npm run dev               # web en http://localhost:5173 (sin funciones del servidor)
```

Para probar también la creación de pedidos (funciones del servidor) usá Netlify CLI:

```bash
npm install -g netlify-cli
cd ..            # carpeta raíz del proyecto
netlify dev      # web + funciones en http://localhost:8888
```

**Modo de pruebas sin tocar la tienda real** (emuladores de Firebase, requiere Java 21):

```bash
firebase emulators:start --only firestore,auth --project demo-yulian
# en otra terminal, dentro de web/ con un .env que tenga:
#   VITE_FIREBASE_API_KEY=demo-key  VITE_FIREBASE_PROJECT_ID=demo-yulian
#   VITE_FIREBASE_APP_ID=1:1:web:1  VITE_USE_EMULATORS=true
npm run dev
```

Para la app: `cd admin_app && flutter run` con el celular conectado por USB (depuración USB activada).

---

## Estructura

```
├── netlify.toml                 Configuración de Netlify
├── firebase.json                Configuración de Firebase CLI
├── firebase/firestore.rules     Reglas de seguridad de la base de datos
├── web/                         Página web (React + Vite + TypeScript)
│   ├── src/pages/               Inicio, catálogo, producto, carrito, checkout, cuenta, pedidos
│   ├── src/lib/effects.ts       Estela del dedo, corazones y confeti ✨
│   └── netlify/functions/       create-order · cloudinary-sign · test-push
└── admin_app/                   App de administración (Flutter)
    └── lib/
        ├── screens/             Inicio, pedidos, detalle, productos, catálogos, ajustes
        ├── services/            Firestore, notificaciones, subida de fotos
        └── widgets/cute_effects.dart   Estela del dedo y confeti en la app
```

---

## Límites gratuitos (de sobra para empezar)

- **Firestore**: 50 000 lecturas y 20 000 escrituras por día. La web guarda caché local, así que las visitas repetidas casi no consumen.
- **Netlify**: 125 000 llamadas a funciones y 100 GB de tráfico al mes.
- **Cloudinary**: 25 créditos al mes (miles de fotos optimizadas).
- **Notificaciones (FCM)**: ilimitadas.

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| La web dice "Falta un pasito" | Faltan las variables `VITE_FIREBASE_…` en Netlify. Agregalas y volvé a publicar (*Deploys → Trigger deploy*). |
| "El servidor no está configurado" al hacer un pedido | Faltan `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL` o `FIREBASE_PRIVATE_KEY` en Netlify. |
| La app dice "Cuenta sin acceso" | Falta el documento `admins/{UID}` en Firestore (paso 4). |
| No se pueden subir fotos | Revisá las 3 variables de Cloudinary en Netlify y que `API_BASE_URL` de la app sea la dirección correcta de la web. |
| No llegan notificaciones | Aceptá el permiso de notificaciones (Ajustes del celular → Apps → Creaciones Yulian), y probá con "Enviar notificación de prueba". Algunos celulares (Xiaomi, Huawei, Samsung) necesitan desactivar el "ahorro de batería" para la app. |
| No puedo iniciar sesión con Google/otro dominio en la web | Agregá el dominio en Firebase → *Authentication → Dominios autorizados*. |
