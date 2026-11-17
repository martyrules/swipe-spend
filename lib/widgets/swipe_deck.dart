import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import 'transaction_card.dart';

/// Controller om een swipe vanuit knoppen te starten.
class SwipeDeckController {
  _SwipeDeckState? _state;

  void swipe(Verdict verdict) => _state?._animateOut(verdict);
}

/// Kaartenstapel met eigen drag-gestures (Tinder-stijl).
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.transactions,
    required this.currentIndex,
    required this.isSample,
    required this.onSwiped,
    required this.controller,
  });

  final List<Transaction> transactions;
  final int currentIndex;
  final bool isSample;
  final ValueChanged<Verdict> onSwiped;
  final SwipeDeckController controller;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  Verdict? _pending;
  double _width = 360;

  static const _threshold = 0.28; // fractie van de breedte

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )
      ..addListener(() {
        setState(() {
          final t = Curves.easeOut.transform(_anim.value);
          _drag = Offset.lerp(_from, _to, t)!;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final v = _pending;
          _pending = null;
          setState(() => _drag = Offset.zero);
          if (v != null) widget.onSwiped(v);
        }
      });
  }

  @override
  void didUpdateWidget(covariant SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._state = this;
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _anim.dispose();
    super.dispose();
  }

  bool get _hasCard => widget.currentIndex < widget.transactions.length;

  void _animateOut(Verdict verdict) {
    if (!_hasCard || _anim.isAnimating) return;
    final dir = verdict == Verdict.keep ? 1.0 : -1.0;
    _pending = verdict;
    _from = _drag;
    _to = Offset(dir * _width * 1.5, _drag.dy + 40);
    _anim.forward(from: 0);
  }

  void _animateBack() {
    _pending = null;
    _from = _drag;
    _to = Offset.zero;
    _anim.forward(from: 0);
  }

  void _onPanEnd(DragEndDetails d) {
    final progress = _drag.dx / _width;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (progress > _threshold || vx > 900) {
      _animateOut(Verdict.keep);
    } else if (progress < -_threshold || vx < -900) {
      _animateOut(Verdict.regret);
    } else {
      _animateBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _width = constraints.maxWidth;
      final progress = (_drag.dx / (_width * _threshold)).clamp(-1.0, 1.0);
      final cards = <Widget>[];

      // Achterliggende kaarten (max 2), iets kleiner en lager.
      for (var depth = 2; depth >= 1; depth--) {
        final i = widget.currentIndex + depth;
        if (i >= widget.transactions.length) continue;
        // Kaart eronder schuift naar voren naarmate je sleept.
        final lift = depth == 1 ? progress.abs() : 0.0;
        final scale = 1 - 0.05 * (depth - lift);
        final dy = 9.0 * (depth - lift);
        cards.add(Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: ExcludeSemantics(
                child: TransactionCard(
                  key: ValueKey(widget.transactions[i].id),
                  transaction: widget.transactions[i],
                  isSample: widget.isSample,
                ),
              ),
            ),
          ),
        ));
      }

      if (_hasCard) {
        final t = widget.transactions[widget.currentIndex];
        final angle = (_drag.dx / _width) * (math.pi / 12);
        cards.add(Positioned.fill(
          child: GestureDetector(
            onPanStart: (_) => _anim.stop(),
            onPanUpdate: (d) => setState(() => _drag += d.delta),
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _drag,
              child: Transform.rotate(
                angle: angle,
                child: TransactionCard(
                  key: ValueKey(t.id),
                  transaction: t,
                  isSample: widget.isSample,
                  dragProgress: progress,
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
