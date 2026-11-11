import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// API global para lanzar efectos desde cualquier pantalla.
class Effects {
  Effects._();
  static _CuteEffectsState? _state;

  /// Lluvia de confeti y corazones desde arriba.
  static void confetti() => _state?._confetti();

  /// Explosión de corazones en un punto de la pantalla.
  static void burst(Offset globalPosition, {int count = 14}) => _state?._burst(globalPosition, count);

  /// Explosión de corazones desde el centro de un widget.
  static void burstFrom(BuildContext context, {int count = 14}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    burst(box.localToGlobal(box.size.center(Offset.zero)), count: count);
  }
}

enum _Kind { heart, sparkle, dot, confetti, flower }

const _palette = [
  AppColors.pink300,
  AppColors.pink400,
  AppColors.pink500,
  AppColors.lilac300,
  AppColors.lilac500,
  AppColors.butter,
  AppColors.mint,
  Color(0xFFFFB5D3),
];

class _Particle {
  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
    required this.kind,
    this.gravity = 0,
    this.drag = 0.985,
    this.rot = 0,
    this.spin = 0,
  }) : maxLife = life;

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final _Kind kind;
  final double gravity;
  final double drag;
  double rot;
  final double spin;

  double get t => (life / maxLife).clamp(0.0, 1.0);

  void update(double dt) {
    vel = Offset(vel.dx * drag, vel.dy * drag + gravity * dt);
    pos += vel * dt;
    rot += spin * dt;
    life -= dt;
  }
}

class _TrailPoint {
  _TrailPoint(this.pos);
  final Offset pos;
  double life = 0.45;
}

/// Envuelve toda la app: dibuja una estela linda donde pasa el dedo
/// (línea rosa-lila con corazones y destellos) y permite lanzar confeti.
/// No interfiere con los toques ni con el scroll.
class CuteEffects extends StatefulWidget {
  const CuteEffects({super.key, required this.child});
  final Widget child;

  @override
  State<CuteEffects> createState() => _CuteEffectsState();
}

class _CuteEffectsState extends State<CuteEffects> with SingleTickerProviderStateMixin {
  final _particles = <_Particle>[];
  final _trails = <int, List<_TrailPoint>>{};
  final _lastSpawn = <int, Offset>{};
  final _rand = math.Random();
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    Effects._state = this;
  }

  @override
  void dispose() {
    if (Effects._state == this) Effects._state = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  double _rnd(double min, double max) => min + _rand.nextDouble() * (max - min);
  Color get _color => _palette[_rand.nextInt(_palette.length)];

  void _start() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;

    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.life <= 0 || p.pos.dy > _size.height + 60);

    for (final trail in _trails.values) {
      for (final pt in trail) {
        pt.life -= dt;
      }
      trail.removeWhere((pt) => pt.life <= 0);
    }
    _trails.removeWhere((_, trail) => trail.isEmpty);

    if (_particles.isEmpty && _trails.isEmpty) _ticker.stop();
    _repaint.value++;
  }

  // ── Interacción con el dedo ──

  void _onDown(PointerDownEvent e) {
    if (_reduceMotion) return;
    _lastSpawn[e.pointer] = e.position;
    for (var i = 0; i < 5; i++) {
      final a = _rnd(0, math.pi * 2);
      final s = _rnd(40, 110);
      _particles.add(_Particle(
        pos: e.position,
        vel: Offset(math.cos(a) * s, math.sin(a) * s - 40),
        life: _rnd(0.5, 0.8),
        size: _rnd(6, 10),
        color: _color,
        kind: i.isEven ? _Kind.heart : _Kind.sparkle,
        gravity: -30,
        drag: 0.96,
        rot: _rnd(-0.4, 0.4),
      ));
    }
    _start();
  }

  void _onMove(PointerMoveEvent e) {
    if (_reduceMotion) return;
    final trail = _trails.putIfAbsent(e.pointer, () => <_TrailPoint>[]);
    trail.add(_TrailPoint(e.position));
    if (trail.length > 48) trail.removeAt(0);

    final last = _lastSpawn[e.pointer];
    if (last == null || (e.position - last).distance > 20) {
      _lastSpawn[e.pointer] = e.position;
      final roll = _rand.nextDouble();
      _particles.add(_Particle(
        pos: e.position + Offset(_rnd(-6, 6), _rnd(-6, 6)),
        vel: Offset(_rnd(-25, 25), _rnd(-70, -20)),
        life: _rnd(0.6, 1.0),
        size: _rnd(5, 11),
        color: _color,
        kind: roll < 0.45 ? _Kind.heart : (roll < 0.8 ? _Kind.sparkle : _Kind.dot),
        gravity: -15,
        drag: 0.97,
        rot: _rnd(-0.5, 0.5),
        spin: _rnd(-2, 2),
      ));
    }
    _start();
  }

  void _onUp(PointerEvent e) => _lastSpawn.remove(e.pointer);

  // ── Efectos lanzados por código ──

  void _burst(Offset at, int count) {
    if (_reduceMotion) return;
    for (var i = 0; i < count; i++) {
      final a = _rnd(0, math.pi * 2);
      final s = _rnd(120, 320);
      _particles.add(_Particle(
        pos: at,
        vel: Offset(math.cos(a) * s, math.sin(a) * s - 120),
        life: _rnd(0.8, 1.3),
        size: _rnd(7, 14),
        color: _color,
        kind: i % 3 == 0 ? _Kind.sparkle : (i % 5 == 0 ? _Kind.flower : _Kind.heart),
        gravity: 420,
        drag: 0.975,
        rot: _rnd(-0.6, 0.6),
        spin: _rnd(-3, 3),
      ));
    }
    _start();
  }

  void _confetti() {
    if (_reduceMotion || _size.isEmpty) return;
    for (var i = 0; i < 110; i++) {
      final roll = _rand.nextDouble();
      _particles.add(_Particle(
        pos: Offset(_rnd(0, _size.width), _rnd(-120, -10)),
        vel: Offset(_rnd(-60, 60), _rnd(90, 260)),
        life: _rnd(2.2, 3.4),
        size: _rnd(6, 12),
        color: _color,
        kind: roll < 0.55 ? _Kind.confetti : (roll < 0.8 ? _Kind.heart : (roll < 0.92 ? _Kind.flower : _Kind.sparkle)),
        gravity: 90,
        drag: 0.995,
        rot: _rnd(0, math.pi),
        spin: _rnd(-6, 6),
      ));
    }
    _start();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _EffectsPainter(_particles, _trails, _repaint),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  _EffectsPainter(this.particles, this.trails, Listenable repaint) : super(repaint: repaint);

  final List<_Particle> particles;
  final Map<int, List<_TrailPoint>> trails;

  static final Path _heart = _buildHeart();
  static final Path _sparkle = _buildSparkle();

  static Path _buildHeart() {
    const k = 1.0;
    return Path()
      ..moveTo(0, -k * 0.35)
      ..cubicTo(-k * 0.1, -k * 0.8, -k, -k * 0.7, -k, -k * 0.1)
      ..cubicTo(-k, k * 0.4, -k * 0.3, k * 0.7, 0, k)
      ..cubicTo(k * 0.3, k * 0.7, k, k * 0.4, k, -k * 0.1)
      ..cubicTo(k, -k * 0.7, k * 0.1, -k * 0.8, 0, -k * 0.35)
      ..close();
  }

  static Path _buildSparkle() {
    return Path()
      ..moveTo(0, -1)
      ..quadraticBezierTo(0, 0, 1, 0)
      ..quadraticBezierTo(0, 0, 0, 1)
      ..quadraticBezierTo(0, 0, -1, 0)
      ..quadraticBezierTo(0, 0, 0, -1)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Estela del dedo
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final trail in trails.values) {
      for (var i = 1; i < trail.length; i++) {
        final a = trail[i - 1];
        final b = trail[i];
        final t = (b.life / 0.45).clamp(0.0, 1.0);
        final along = i / trail.length;
        linePaint
          ..strokeWidth = 2 + 7 * t
          ..color = Color.lerp(AppColors.lilac300, AppColors.pink400, along)!.withValues(alpha: 0.65 * t);
        canvas.drawLine(a.pos, b.pos, linePaint);
      }
    }

    // Partículas
    final fill = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final alpha = p.kind == _Kind.confetti ? math.min(1.0, p.t * 2.5) : p.t;
      fill.color = p.color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rot);
      switch (p.kind) {
        case _Kind.heart:
          canvas.scale(p.size);
          canvas.drawPath(_heart, fill);
        case _Kind.sparkle:
          canvas.scale(p.size * 0.9);
          canvas.drawPath(_sparkle, fill);
        case _Kind.dot:
          canvas.drawCircle(Offset.zero, p.size * 0.35, fill);
        case _Kind.confetti:
          // Simula giro 3D achicando el ancho
          final w = p.size * (0.35 + 0.65 * math.cos(p.rot * 2).abs());
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: p.size * 0.55), const Radius.circular(2)),
            fill,
          );
        case _Kind.flower:
          final r = p.size * 0.32;
          for (var i = 0; i < 5; i++) {
            final ang = i * math.pi * 2 / 5;
            canvas.drawCircle(Offset(math.cos(ang) * r, math.sin(ang) * r), r * 0.85, fill);
          }
          canvas.drawCircle(Offset.zero, r * 0.7, Paint()..color = AppColors.butter.withValues(alpha: alpha.clamp(0.0, 1.0)));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EffectsPainter oldDelegate) => false;
}
