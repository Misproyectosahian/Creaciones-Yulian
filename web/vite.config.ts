import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    target: 'es2022',
    chunkSizeWarningLimit: 700,
    rolldownOptions: {
      output: {
        // Librerías en archivos separados: se guardan en caché del navegador
        // y no se vuelven a descargar cuando cambia el código de la tienda.
        codeSplitting: {
          groups: [
            // Firestore liviano (catálogo, se carga al inicio)
            {
              name: 'firestore-lite',
              test: /node_modules[\\/](@firebase[\\/]firestore[\\/]dist[\\/]lite|firebase[\\/]firestore[\\/]lite)[\\/]/,
              priority: 4,
            },
            // Firestore completo (seguimiento en vivo, solo en páginas de pedidos)
            {
              name: 'firestore',
              test: /node_modules[\\/](@firebase[\\/](firestore|webchannel-wrapper)|firebase[\\/]firestore)[\\/]/,
              priority: 3,
            },
            { name: 'firebase', test: /node_modules[\\/](@firebase|firebase)[\\/]/, priority: 2 },
            { name: 'react', test: /node_modules[\\/](react|react-dom|react-router|react-router-dom|scheduler)[\\/]/, priority: 1 },
          ],
        },
      },
    },
  },
});
