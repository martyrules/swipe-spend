import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import 'transaction_card.dart';

/// Controller om een swipe vanuit knoppen te starten.
class SwipeDeckController {
  _SwipeDeckState? _state;

  void swipe(Verdict verdict) => _state?._flyOut(verdict);
}

/// Kaartenstapel met eigen drag-gestures (Tinder-stijl): diepte, veer-terug
/// via een spring-simulatie, stempel bij slepen en een tik bij de drempel.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.transactions,
    required this.currentIndex,
    required this.isSample,
    required this.onSwiped,
    required this.controller,
    required this.onNoteTap,
  });

  final List<Transaction> transactions;
  final int currentIndex;
  final bool isSample;
  final ValueChanged<Verdict> onSwiped;
  final SwipeDeckController controller;
  final ValueChanged<Transaction> onNoteTap;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with TickerProviderStateMixin {
  late final AnimationController _fly;
  late final AnimationController _spring;
  late final AnimationController _enter;
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  Verdict? _pending;
  double _width = 360;
  bool _pastThreshold = false;

  static const _threshold = 0.3; // fractie van de breedte

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 240))
      ..addListener(() {
        final t = Curves.easeIn.transform(_fly.value);
        setState(() => _drag = Offset.lerp(_from, _to, t)!);
      })
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          final v = _pending;
          _pending = null;
          _drag = Offset.zero;
          _pastThreshold = false;
          if (v != null) widget.onSwiped(v);
          _enter.forward(from: 0);
        }
      });
    // Onbegrensd: de veer schiet een beetje door het midden (bounce).
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _drag = _from * (1 - _spring.value));
      });
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1)
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._state = this;
    if (oldWidget.currentIndex > widget.currentIndex) {
      // Undo: kaart komt terug van opzij.
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _fly.dispose();
    _spring.dispose();
    _enter.dispose();
    super.dispose();
  }

  bool get _hasCard => widget.currentIndex < widget.transactions.length;

  void _flyOut(Verdict verdict) {
    if (!_hasCard || _fly.isAnimating) return;
    _spring.stop();
    HapticFeedback.mediumImpact();
    final dir = verdict == Verdict.keep ? 1.0 : -1.0;
    _pending = verdict;
    _from = _drag;
    _to = Offset(dir * _width * 1.6, _drag.dy + 60);
    _fly.forward(from: 0);
  }

  void _springBack(double velocity) {
    _from = _drag;
    const spring = SpringDescription(mass: 1, stiffness: 420, damping: 17);
    _spring.value = 0;
    _spring.animateWith(SpringSimulation(spring, 0, 1, velocity));
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _drag += d.delta);
    final past = (_drag.dx / _width).abs() > _threshold;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      if (past) HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails d) {
    final progress = _drag.dx / _width;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (progress > _threshold || vx > 1000) {
      _flyOut(Verdict.keep);
    } else if (progress < -_threshold || vx < -1000) {
      _flyOut(Verdict.regret);
    } else {
      _pastThreshold = false;
      _springBack((vx.abs() / _width).clamp(0, 6));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      final progress = (_drag.dx / (_width * _threshold)).clamp(-1.0, 1.0);
      final lift = progress.abs();
      final cards = <Widget>[];

      // Achterliggende kaarten (max 2): kleiner, lager, iets doorschijnend.
      for (var depth = 2; depth >= 1; depth--) {
        final i = widget.currentIndex + depth;
        if (i >= widget.transactions.length) continue;
        final d = depth - (depth == 1 ? lift : lift * 0.5);
        cards.add(Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, 14.0 * d),
              child: Transform.scale(
                scale: 1 - 0.05 * d,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: (1 - 0.25 * d).clamp(0.0, 1.0),
                  child: ExcludeSemantics(
                    child: TransactionCard(
                      key: ValueKey('bg${widget.transactions[i].id}'),
                      transaction: widget.transactions[i],
                      isSample: widget.isSample,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
      }

      if (_hasCard) {
        final t = widget.transactions[widget.currentIndex];
        final angle = (_drag.dx / _width) * (math.pi / 10);
        final e = Curves.easeOutBack.transform(_enter.value);
        cards.add(Positioned.fill(
          child: GestureDetector(
            onTap: () => widget.onNoteTap(t),
            onPanStart: (_) {
              _spring.stop();
              _fly.stop();
            },
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _drag + Offset(0, 10 * (1 - e)),
              child: Transform.rotate(
                angle: angle,
                alignment: const Alignment(0, 1.4),
                child: Transform.scale(
                  scale: 0.96 + 0.04 * e,
                  child: TransactionCard(
                    key: ValueKey(t.id),
                    transaction: t,
                    isSample: widget.isSample,
                    dragProgress: progress,
                    onNoteTap: () => widget.onNoteTap(t),
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      return Stack(clipBehavior: Clip.none, children: cards);
    });
  }
}
