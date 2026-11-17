import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sample_badge.dart';
import '../widgets/swipe_deck.dart';
import 'summary_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  static const route = '/swipe';

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _deck = SwipeDeckController();

  void _onSwiped(AppState state, Verdict v) {
    state.swipe(v);
    if (state.isDone) {
      Navigator.of(context).pushReplacementNamed(SummaryScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final total = state.transactions.length;
    final shown = (state.currentIndex + 1).clamp(0, total);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zou je het opnieuw doen?'),
        actions: [
          IconButton(
            tooltip: 'Naar overzicht',
            onPressed: state.reviewedCount == 0
                ? null
                : () => Navigator.of(context).pushNamed(SummaryScreen.route),
            icon: const Icon(Icons.insights_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: !state.hasData
            ? const Center(child: Text('Nog geen uitgaven ingeladen.'))
            : Column(
                children: [
                  if (state.isSample) const SampleBanner(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          '$shown/$total',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: total == 0
                                  ? 0
                                  : state.reviewedCount / total,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.west_rounded,
                            size: 16, color: AppColors.regret),
                        SizedBox(width: 4),
                        Text('spijt',
                            style: TextStyle(
                                color: AppColors.regret,
                                fontWeight: FontWeight.w700)),
                        Spacer(),
                        Text('opnieuw',
                            style: TextStyle(
                                color: AppColors.keep,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.east_rounded,
                            size: 16, color: AppColors.keep),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                      child: SwipeDeck(
                        transactions: state.transactions,
                        currentIndex: state.currentIndex,
                        isSample: state.isSample,
                        controller: _deck,
                        onSwiped: (v) => _onSwiped(state, v),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundButton(
                          tooltip: 'Spijt (links)',
                          icon: Icons.thumb_down_alt_rounded,
                          color: AppColors.regret,
                          size: 68,
                          onPressed: () => _deck.swipe(Verdict.regret),
                        ),
                        const SizedBox(width: 22),
                        _RoundButton(
                          tooltip: 'Ongedaan maken',
                          icon: Icons.undo_rounded,
                          color: Colors.blueGrey,
                          size: 50,
                          onPressed: state.canUndo ? state.undo : null,
                        ),
                        const SizedBox(width: 22),
                        _RoundButton(
                          tooltip: 'Opnieuw (rechts)',
                          icon: Icons.thumb_up_alt_rounded,
                          color: AppColors.keep,
                          size: 68,
                          onPressed: () => _deck.swipe(Verdict.keep),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: enabled ? 4 : 0,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon,
                  size: size * 0.45,
                  color: enabled ? color : color.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ),
    );
  }
}
