import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../services/format.dart';
import '../theme.dart';

/// Categorie-pil met icoon (kleur nooit alleen).
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category, this.dense = false});

  final SpendCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 11, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: dense ? 13 : 15, color: category.color),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: TextStyle(
              color: Color.lerp(category.color, Colors.black, 0.25),
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo-vervanger: initialen op een verloop in de categoriekleur, met een
/// klein categorie-icoon. Geen externe logo's (geen licentiegedoe).
class MerchantAvatar extends StatelessWidget {
  const MerchantAvatar({
    super.key,
    required this.name,
    required this.category,
    this.size = 64,
  });

  final String name;
  final SpendCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(c, Colors.white, 0.15)!, Color.lerp(c, Colors.black, 0.25)!],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.36,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paper, width: 2),
              ),
              child: Icon(category.icon, size: size * 0.22, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Knop die "indeukt" bij tikken (haptic-achtige micro-animatie).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Ronde actieknop onder de kaartenstapel.
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: label,
      child: Pressable(
        semanticLabel: label,
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: filled ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.9), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: enabled ? 0.28 : 0),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: size * 0.46, color: filled ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}

/// Telt een bedrag op van 0 naar [value].
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    required this.style,
    this.rounded = false,
    this.duration = const Duration(milliseconds: 1300),
  });

  final double value;
  final TextStyle style;
  final bool rounded;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(rounded ? euroRound(v) : euro(v), style: style),
    );
  }
}
