import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Lichtgewicht confetti (eigen painter, geen package).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.play = true});
  final bool play;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  _Piece(math.Random r)
      : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
        speed = 0.55 + r.nextDouble() * 0.75,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 6 + r.nextDouble() * 7,
        drift = (r.nextDouble() - 0.5) * 0.3,
        color = _colors[r.nextInt(_colors.length)],
        circle = r.nextDouble() < 0.3;

  static const _colors = [
    AppColors.keep, AppColors.regret, AppColors.brand, AppColors.sample,
    Color(0xFF7C5CFA), Color(0xFF2E9BE6),
  ];

  final double angle, speed, spin, size, drift;
  final Color color;
  final bool circle;
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  final _pieces = List.generate(140, (i) => _Piece(math.Random(i * 7919)));

  @override
  void initState() {
    super.initState();
    if (widget.play) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isCompleted || _c.value == 0
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _c.value),
              ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.28);
    final paint = Paint();
    final fade = t > 0.75 ? (1 - (t - 0.75) / 0.25) : 1.0;
    for (final p in pieces) {
      final v = p.speed * size.height * 0.9;
      final dx = math.cos(p.angle) * v * t + p.drift * size.width * t;
      final dy = math.sin(p.angle) * v * t + 0.5 * 1.6 * size.height * t * t;
      final pos = origin + Offset(dx, dy);
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
              const Radius.circular(1.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
