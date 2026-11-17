import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_config.dart';
import '../theme.dart';

/// Merkteken: verloop koraal -> indigo met een wit, gekanteld kaartje en een "R"
/// (zelfde ontwerp als de app-iconen uit tool/make_icons.py).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.regret, AppColors.brand],
        ),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: 10 * math.pi / 180,
        child: Container(
          width: size * 0.5,
          height: size * 0.62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: size * 0.06, offset: Offset(0, size * 0.03))],
          ),
          child: Stack(
            children: [
              Center(
                child: Text('R',
                    style: TextStyle(
                        fontSize: size * 0.38, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1)),
              ),
              Positioned(
                right: size * 0.05,
                bottom: size * 0.05,
                child: Container(
                  width: size * 0.09,
                  height: size * 0.09,
                  decoration: const BoxDecoration(color: AppColors.keep, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Woordmerk: naam in Inter Black, laatste letter in koraal.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.onDark = false, this.fontSize = 19});
  final bool onDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    const name = AppConfig.appName;
    final base = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: fontSize,
      letterSpacing: -fontSize * 0.04,
      color: onDark ? Colors.white : AppColors.ink,
    );
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: name.substring(0, name.length - 1), style: base),
        TextSpan(text: name.substring(name.length - 1), style: base.copyWith(color: AppColors.regret)),
      ])),
    );
  }
}

/// Logo + woordmerk naast elkaar.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoMark(size: 34),
          const SizedBox(width: 10),
          Wordmark(onDark: onDark),
        ],
      );
}
