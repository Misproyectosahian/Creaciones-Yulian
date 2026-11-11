import 'package:intl/intl.dart';

final _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

/// Formatea colones: 25000 → ₡25 000
String crc(num value) {
  final n = value.round();
  final digits = n.abs().toString().replaceAllMapped(_thousands, (_) => ' ');
  return '${n < 0 ? '-' : ''}₡$digits';
}

/// Convierte texto escrito por la usuaria ("₡25.000", "25 000") a entero.
int parseMoney(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

String onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

/// 88887777 → 8888-7777
String formatPhone(String phone) {
  final d = onlyDigits(phone);
  if (d.length == 8) return '${d.substring(0, 4)}-${d.substring(4)}';
  if (d.length == 11 && d.startsWith('506')) return '+506 ${d.substring(3, 7)}-${d.substring(7)}';
  return phone;
}

/// Número listo para wa.me (agrega 506 si es un número de Costa Rica de 8 dígitos)
String whatsappNumber(String phone) {
  final d = onlyDigits(phone);
  if (d.length == 8) return '506$d';
  return d;
}

String formatDate(DateTime? d) {
  if (d == null) return '—';
  return DateFormat("d 'de' MMMM yyyy, h:mm a", 'es').format(d);
}

String formatShortDate(DateTime? d) {
  if (d == null) return '—';
  return DateFormat('d MMM · h:mm a', 'es').format(d);
}

String formatDay(DateTime? d) {
  if (d == null) return '—';
  return DateFormat("EEEE d 'de' MMMM", 'es').format(d);
}

/// "2026-12-24" → "jueves 24 de diciembre"
String formatIsoDay(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final days = DateTime(d.year, d.month, d.day).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
  final when = days == 0
      ? ' (hoy)'
      : days == 1
          ? ' (mañana)'
          : days > 1
              ? ' (en $days días)'
              : '';
  return '${DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(d)}$when';
}

String timeAgo(DateTime? d) {
  if (d == null) return 'ahora';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  return formatShortDate(d);
}

/// Quita tildes y pasa a minúsculas para buscar sin importar acentos.
String normalize(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = s.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// Versión optimizada de una foto de Cloudinary (más liviana y rápida).
String cloudinaryThumb(String url, {int width = 400}) {
  const marker = '/image/upload/';
  final i = url.indexOf(marker);
  if (i < 0 || !url.contains('res.cloudinary.com')) return url;
  final head = url.substring(0, i + marker.length);
  final tail = url.substring(i + marker.length);
  return '${head}f_auto,q_auto,c_limit,w_$width/$tail';
}
