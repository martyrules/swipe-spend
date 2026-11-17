import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bits.dart';
import '../widgets/note_sheet.dart';
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
      Navigator.of(context).pushReplacementNamed(SummaryScreen.route, arguments: true);
    }
  }

  void _openNote(AppState state, Transaction t) {
    showNoteSheet(context, transaction: t, onSave: (n, r) => state.setNote(t, n, r));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final total = state.transactions.length;
    final shown = (state.currentIndex + 1).clamp(0, total);
    final regretSoFar = state.transactions
        .where((t) => t.verdict == Verdict.regret)
        .fold<double>(0, (s, t) => s + t.amount);
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
                        Semantics(
                          label: 'Voortgang $shown van $total',
                          excludeSemantics: true,
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: '$shown', style: moneyStyle(20)),
                              TextSpan(text: '/$total', style: moneyStyle(20, color: AppColors.stone, weight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: total == 0 ? 0 : state.reviewedCount / total),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 8,
                                color: AppColors.brand,
                                backgroundColor: AppColors.line,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(children: [
                          const Icon(Icons.block_rounded, size: 15, color: AppColors.regret),
                          const SizedBox(width: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Text(euroRound(regretSoFar),
                                key: ValueKey(regretSoFar),
                                style: moneyStyle(14, color: AppColors.regret, weight: FontWeight.w800)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.west_rounded, size: 15, color: AppColors.regret),
                        SizedBox(width: 4),
                        Text('spijt', style: TextStyle(color: AppColors.regret, fontWeight: FontWeight.w800)),
                        Spacer(),
                        Text('tik op de kaart voor een notitie',
                            style: TextStyle(color: AppColors.stone, fontSize: 12)),
                        Spacer(),
                        Text('opnieuw', style: TextStyle(color: AppColors.keep, fontWeight: FontWeight.w800)),
                        SizedBox(width: 4),
                        Icon(Icons.east_rounded, size: 15, color: AppColors.keep),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
                      child: SwipeDeck(
                        transactions: state.transactions,
                        currentIndex: state.currentIndex,
                        isSample: state.isSample,
                        controller: _deck,
                        onSwiped: (v) => _onSwiped(state, v),
                        onNoteTap: (t) => _openNote(state, t),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoundAction(
                          label: 'Spijt (links)',
                          icon: Icons.close_rounded,
                          color: AppColors.regret,
                          size: 70,
                          onPressed: () => _deck.swipe(Verdict.regret),
                        ),
                        const SizedBox(width: 20),
                        RoundAction(
                          label: 'Ongedaan maken',
                          icon: Icons.undo_rounded,
                          color: AppColors.stone,
                          size: 50,
                          onPressed: state.canUndo ? state.undo : null,
                        ),
                        const SizedBox(width: 20),
                        RoundAction(
                          label: 'Opnieuw (rechts)',
                          icon: Icons.check_rounded,
                          color: AppColors.keep,
                          size: 70,
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
