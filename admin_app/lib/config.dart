/// Configuración general de la app de administración.
///
/// Cambiá [apiBaseUrl] por la dirección real de la página en Netlify
/// (por ejemplo `https://creaciones-yulian.netlify.app`), o pasala al compilar:
///   flutter build apk --dart-define=API_BASE_URL=https://mi-tienda.netlify.app
class AppConfig {
  AppConfig._();

  /// Dirección de la página web (Netlify). Se usa para:
  ///  - las funciones del servidor (subir fotos, notificación de prueba)
  ///  - el enlace de seguimiento que se le manda al cliente por WhatsApp
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://creaciones-yulian.netlify.app',
  );

  static String functionUrl(String name) => '$apiBaseUrl/.netlify/functions/$name';

  static String orderTrackingUrl(String orderId) => '$apiBaseUrl/pedido/$orderId';
}
