import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Llamadas a las funciones del servidor (Netlify Functions) y a Cloudinary.
class ApiService {
  ApiService._();

  static Future<Map<String, dynamic>> _post(String function, [Map<String, dynamic>? body]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('Tu sesión expiró. Volvé a ingresar.');
    final token = await user.getIdToken();
    if (token == null) throw ApiException('Tu sesión expiró. Volvé a ingresar.');

    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(AppConfig.functionUrl(function)),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado. Revisá tu internet e intentá de nuevo.');
    } catch (_) {
      throw ApiException('No hay conexión con el servidor. Revisá tu internet.');
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(data['error']?.toString() ?? 'Error del servidor (${res.statusCode}).');
    }
    return data;
  }

  /// Envía una notificación de prueba a los celulares de administración.
  static Future<int> sendTestPush() async {
    final data = await _post('test-push');
    return (data['sent'] as num?)?.toInt() ?? 0;
  }

  /// Sube una foto a Cloudinary (firmada por el servidor) y devuelve su URL.
  static Future<String> uploadImage(XFile file) async {
    final sig = await _post('cloudinary-sign');
    final cloudName = sig['cloudName'];
    final apiKey = sig['apiKey'];
    final signature = sig['signature'];
    final folder = sig['folder'];
    final timestamp = sig['timestamp'];
    if (cloudName is! String || apiKey is! String || signature is! String || timestamp == null) {
      throw ApiException('El servidor no devolvió la firma para subir fotos. Revisá la configuración de Cloudinary.');
    }

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    )
      ..fields['api_key'] = apiKey
      ..fields['timestamp'] = '$timestamp'
      ..fields['signature'] = signature;
    if (folder is String && folder.isNotEmpty) req.fields['folder'] = folder;
    req.files.add(http.MultipartFile.fromBytes('file', await file.readAsBytes(), filename: file.name));

    final http.StreamedResponse streamed;
    try {
      streamed = await req.send().timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw ApiException('La foto tardó demasiado en subir. Intentá de nuevo.');
    } catch (_) {
      throw ApiException('No se pudo subir la foto. Revisá tu internet.');
    }
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    final url = data['secure_url'];
    if (streamed.statusCode != 200 || url is! String) {
      final err = data['error'];
      final msg = err is Map ? err['message'] : null;
      throw ApiException('No se pudo subir la foto${msg != null ? ': $msg' : '.'}');
    }
    return url;
  }
}
