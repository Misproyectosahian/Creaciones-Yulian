import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Corazón que late (cargando).
class HeartLoader extends StatefulWidget {
  const HeartLoader({super.key, this.size = 46, this.label});
  final double size;
  final String? label;

  @override
  State<HeartLoader> createState() => _HeartLoaderState();
}

class _HeartLoaderState extends State<HeartLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.12).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
          child: Icon(Icons.favorite_rounded, size: widget.size, color: AppColors.pink400),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(widget.label!, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        ],
      ],
    );
  }
}

class CenteredLoader extends StatelessWidget {
  const CenteredLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) => Center(child: HeartLoader(label: label));
}

/// Mensaje lindo cuando no hay datos.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action});
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradient),
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: fredoka(size: 20)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Mensaje de error amigable.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final text = '$error';
    final permission = text.contains('permission-denied');
    return EmptyState(
      emoji: '🥺',
      title: permission ? 'Sin permiso' : 'Algo salió mal',
      subtitle: permission
          ? 'Esta cuenta no tiene permiso de administración. Revisá que exista el documento admins/{tu UID} en Firestore.'
          : text,
    );
  }
}

/// Imagen de internet con placeholder tierno.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.width, this.height, this.radius = 16, this.thumbWidth = 400});
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final int thumbWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      alignment: Alignment.center,
      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
    );
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (u == null || u.isEmpty)
          ? placeholder
          : CachedNetworkImage(
              imageUrl: cloudinaryThumb(u, width: thumbWidth),
              width: width,
              height: height,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 220),
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.compact = false});
  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: status.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: TextStyle(
          color: Color.lerp(status.color, AppColors.ink, 0.35),
          fontWeight: FontWeight.w800,
          fontSize: compact ? 11.5 : 13,
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.pink500, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 3)],
          Text(text, style: TextStyle(color: Color.lerp(color, AppColors.ink, 0.3), fontWeight: FontWeight.w800, fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Tarjeta con título para agrupar secciones.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon, this.trailing});
  final String title;
  final Widget child;
  final String? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8)],
                Expanded(child: Text(title, style: fredoka(size: 18))),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: AppColors.pink50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.pink500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.pink300),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de confirmación lindo.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Sí',
  String cancel = 'Cancelar',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: const Color(0xFFD9534F), minimumSize: const Size(64, 44)) : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Fondo con burbujas suaves rosadas/lilas.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -80, right: -60, child: _blob(220, AppColors.pink100)),
        Positioned(top: 160, left: -90, child: _blob(180, AppColors.lilac100)),
        Positioned(bottom: -70, right: -40, child: _blob(200, AppColors.lilac100)),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.8)),
      );
}
