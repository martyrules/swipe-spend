import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../theme.dart';
import 'bits.dart';

/// Vector-illustraties voor de onboarding: opgebouwd uit widgets en iconen,
/// dus geen externe beelden of licenties. Zweven zachtjes.
class FloatingIllustration extends StatefulWidget {
  const FloatingIllustration({super.key, required this.step});
  final int step;

  @override
  State<FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<FloatingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final s = math.sin(_c.value * 2 * math.pi);
        return SizedBox(
          width: 300,
          height: 280,
          child: switch (widget.step) {
            0 => _Receipts(s: s),
            1 => _SwipeDemo(s: s),
            _ => _Savings(s: s),
          },
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)]),
          ),
        ),
      );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.name, required this.amount, required this.category, this.border});
  final String name;
  final String amount;
  final SpendCategory category;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border ?? Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MerchantAvatar(name: name, category: category, size: 40),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(amount, style: moneyStyle(24)),
        ],
      ),
    );
  }
}

class _Receipts extends StatelessWidget {
  const _Receipts({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _Glow(color: AppColors.brand),
        Transform.translate(
          offset: Offset(-62, 18 + 4 * s),
          child: Transform.rotate(angle: -0.22, child: const _MiniCard(name: 'Takeaway', amount: '€ 26,30', category: SpendCategory.uitEten)),
        ),
        Transform.translate(
          offset: Offset(62, 22 - 4 * s),
          child: Transform.rotate(angle: 0.2, child: const _MiniCard(name: 'Zalando', amount: '€ 54,90', category: SpendCategory.shopping)),
        ),
        Transform.translate(
          offset: Offset(0, -6 + 6 * s),
          child: const _MiniCard(name: 'Laadpaal', amount: '€ 4,73', category: SpendCategory.vervoer),
        ),
        Positioned(
          top: 6,
          right: 30,
          child: Transform.translate(
            offset: Offset(0, -5 * s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.sample, borderRadius: BorderRadius.circular(99)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_file_rounded, size: 15, color: AppColors.ink),
                SizedBox(width: 4),
                Text('CSV · PDF', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.keep});
  final bool keep;

  @override
  Widget build(BuildContext context) {
    final c = keep ? AppColors.keep : AppColors.regret;
    return Transform.rotate(
      angle: keep ? -0.25 : 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: c, width: 3),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(keep ? Icons.replay_rounded : Icons.block_rounded, color: c, size: 16),
          const SizedBox(width: 4),
          Text(keep ? 'OPNIEUW' : 'SPIJT', style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
        ]),
      ),
    );
  }
}

class _SwipeDemo extends StatelessWidget {
  const _SwipeDemo({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    final tilt = s; // -1..1: kaart wiegt heen en weer
    return Stack(
      alignment: Alignment.center,
      children: [
        _Glow(color: tilt > 0 ? AppColors.keep : AppColors.regret),
        Positioned(
          left: 0,
          top: 18,
          child: Opacity(
            opacity: (0.4 + 0.6 * (-tilt).clamp(0.0, 1.0)),
            child: const _Stamp(keep: false),
          ),
        ),
        Positioned(
          right: 0,
          top: 18,
          child: Opacity(
            opacity: (0.4 + 0.6 * tilt.clamp(0.0, 1.0)),
            child: const _Stamp(keep: true),
          ),
        ),
        Transform.translate(
          offset: Offset(26 * tilt, 22),
          child: Transform.rotate(
            angle: 0.16 * tilt,
            child: _MiniCard(
              name: 'Uber Eats',
              amount: '€ 22,10',
              category: SpendCategory.uitEten,
              border: Color.lerp(Colors.white, tilt > 0 ? AppColors.keep : AppColors.regret, tilt.abs()),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.west_rounded, color: AppColors.regret),
            const SizedBox(width: 6),
            Icon(Icons.swipe_rounded, color: Colors.white.withValues(alpha: 0.8), size: 30),
            const SizedBox(width: 6),
            const Icon(Icons.east_rounded, color: AppColors.keep),
          ]),
        ),
      ],
    );
  }
}

class _Savings extends StatelessWidget {
  const _Savings({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _Glow(color: AppColors.keep),
        SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(painter: _RingPainter()),
        ),
        Transform.translate(
          offset: Offset(0, 4 * s),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.keep, Color(0xFF0C8F5E)]),
              boxShadow: [BoxShadow(color: AppColors.keep.withValues(alpha: 0.5), blurRadius: 30)],
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 54),
          ),
        ),
        for (var i = 0; i < 3; i++)
          Positioned(
            top: 30.0 + 10 * i + 8 * math.sin(s * math.pi + i),
            left: 40.0 + 90 * i,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
              child: Text(['+ € 12', '+ € 48', '+ € 25'][i],
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0C8F5E), fontFeatures: tabular)),
            ),
          ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    const segs = [
      (0.34, Color(0xFFE0479E)),
      (0.26, Color(0xFFF28C28)),
      (0.14, Color(0xFF7C5CFA)),
      (0.12, Color(0xFF2E9BE6)),
    ];
    var start = -math.pi / 2;
    for (final (f, c) in segs) {
      p.color = c;
      final sweep = f * 2 * math.pi;
      canvas.drawArc(rect.deflate(8), start + 0.08, sweep - 0.16, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
