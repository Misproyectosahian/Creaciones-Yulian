import { createHash } from 'node:crypto';
import { handler, HttpError, json, requireAdmin } from '../lib/server';

/**
 * Firma la subida de una foto a Cloudinary. Solo la administradora puede pedir
 * una firma, así nadie más puede subir fotos a la cuenta.
 */
export default handler(async (req) => {
  await requireAdmin(req);

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;
  if (!cloudName || !apiKey || !apiSecret) {
    throw new HttpError(500, 'Falta configurar Cloudinary en Netlify (CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET).');
  }

  const folder = 'creaciones-yulian/productos';
  const timestamp = Math.round(Date.now() / 1000);
  // Cloudinary: parámetros en orden alfabético + secreto, en SHA-1
  const toSign = `folder=${folder}&timestamp=${timestamp}`;
  const signature = createHash('sha1').update(toSign + apiSecret).digest('hex');

  return json({ cloudName, apiKey, timestamp, folder, signature });
});
