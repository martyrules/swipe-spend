import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../services/format.dart';
import '../services/insights.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_menu.dart';
import '../widgets/bits.dart';
import '../widgets/confetti.dart';
import '../widgets/note_sheet.dart';
import '../widgets/sample_badge.dart';
import 'import_screen.dart';
import 'swipe_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  static const route = '/overzicht';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final celebrate = ModalRoute.of(context)?.settings.arguments == true;
    final insights = SpendInsights(state.transactions);
    final regrets = insights.regrets;
    final cats = insights.byCategory;
    final unreviewed = state.transactions.length - state.reviewedCount;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(
                  insights: insights,
                  isSample: state.isSample,
                  done: unreviewed == 0,
                  canPop: Navigator.of(context).canPop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                sliver: SliverList.list(children: [
                  if (state.isSample) const SampleBanner(margin: EdgeInsets.only(bottom: 12)),
                  if (unreviewed > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Nog $unreviewed uitgave(n) niet beoordeeld.',
                          style: const TextStyle(color: AppColors.stone)),
                    ),
                  _SavingsCard(insights: insights),
                  const SizedBox(height: 12),
                  _CategoryCard(insights: insights, stats: cats),
                  const SizedBox(height: 12),
                  _RegretList(regrets: regrets, state: state),
                  const SizedBox(height: 18),
                  if (unreviewed > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).canPop()
                            ? Navigator.of(context).pop()
                            : Navigator.of(context).pushReplacementNamed(SwipeScreen.route),
                        child: const Text('Verder swipen'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      state.restartReview();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          SwipeScreen.route, (r) => r.settings.name == ImportScreen.route);
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Opnieuw swipen'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(ImportScreen.route, (r) => false),
                    child: const Text('Andere maand inladen'),
                  ),
                ]),
              ),
            ],
          ),
          if (celebrate) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.insights, required this.isSample, required this.done, required this.canPop});
  final SpendInsights insights;
  final bool isSample;
  final bool done;
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final share = insights.regretShare;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 6, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Terug',
                    onPressed: () => canPop
                        ? Navigator.of(context).pop()
                        : Navigator.of(context).pushReplacementNamed(ImportScreen.route),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Text('Spijt-overzicht',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  if (isSample) const SampleBadge(compact: true, onDark: true),
                  const AppMenu(onDark: true),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(done ? 'Klaar! Deze maand had je' : 'Tot nu toe had je',
                        style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 6),
                    AnimatedMoney(
                      value: insights.totalRegret,
                      style: moneyStyle(52, color: const Color(0xFFFF8F7E)),
                    ),
                    Text('spijt van ${euro(insights.totalSpent)} uitgegeven',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: tabular)),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share),
                        duration: const Duration(milliseconds: 1300),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 12,
                          color: AppColors.regret,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Stat(icon: Icons.block_rounded, color: AppColors.regret, label: '${percent(share)} spijt'),
                        const SizedBox(width: 16),
                        _Stat(
                            icon: Icons.replay_rounded,
                            color: AppColors.keep,
                            label: '${insights.keepCount} keer opnieuw'),
                        const SizedBox(width: 16),
                        _Stat(
                            icon: Icons.close_rounded,
                            color: AppColors.regret,
                            label: '${insights.regrets.length} keer spijt'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]);
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.insights});
  final SpendInsights insights;

  @override
  Widget build(BuildContext context) {
    final hasRegret = insights.totalRegret > 0;
    final top = insights.topRegretMerchant;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B87A), Color(0xFF0B8C5C)],
        ),
        boxShadow: [BoxShadow(color: AppColors.keep.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.savings_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Als je dit niet meer doet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (hasRegret) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedMoney(value: insights.monthlySavings, style: moneyStyle(40, color: Colors.white)),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 4),
                  child: Text('per maand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('bespaar je. Dat is ${euroRound(insights.yearlySavings)} op een jaar.',
                style: const TextStyle(color: Colors.white, fontSize: 14.5, fontFeatures: tabular)),
            if (top != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                child: Text(
                  'Grootste boosdoener: ${top.$1} (${top.$2}x, ${euro(top.$3)})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ] else
            const Text('Geen spijt-uitgaven: proper gedaan, niks te schrappen.',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.insights, required this.stats});
  final SpendInsights insights;
  final List<CategoryStat> stats;

  @override
  Widget build(BuildContext context) {
    final withRegret = stats.where((s) => s.regret > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Spijt per categorie', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            if (withRegret.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 58,
                          startDegreeOffset: -90,
                          sections: [
                            for (final s in withRegret)
                              PieChartSectionData(
                                value: s.regret,
                                color: s.category.color,
                                radius: 20 + 12 * v,
                                showTitle: false,
                              ),
                            if (v < 1)
                              PieChartSectionData(
                                value: insights.totalRegret * (1 - v) / v.clamp(0.001, 1),
                                color: Colors.transparent,
                                radius: 1,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(euroRound(insights.totalRegret * v), style: moneyStyle(24)),
                        const Text('spijt', style: TextStyle(color: AppColors.stone)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final c in stats) _CategoryRow(stat: c),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.stat});
  final CategoryStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryPill(category: stat.category),
              const Spacer(),
              Text.rich(TextSpan(children: [
                TextSpan(text: euro(stat.regret), style: moneyStyle(14, weight: FontWeight.w800)),
                TextSpan(text: ' / ${euro(stat.spent)}', style: moneyStyle(13, color: AppColors.stone, weight: FontWeight.w600)),
              ])),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stat.regretShare),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: stat.category.color,
                backgroundColor: stat.category.color.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text('${percent(stat.regretShare)} spijt · ${stat.regretCount} uitgave(n)',
              style: const TextStyle(fontSize: 12, color: AppColors.stone)),
        ],
      ),
    );
  }
}

class _RegretList extends StatelessWidget {
  const _RegretList({required this.regrets, required this.state});
  final List<Transaction> regrets;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.block_rounded, color: AppColors.regret, size: 20),
              const SizedBox(width: 6),
              Text('Je spijt-uitgaven (${regrets.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ]),
            const SizedBox(height: 6),
            if (regrets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Geen spijt. Proper gedaan!'),
              ),
            for (final t in regrets)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showNoteSheet(context,
                    transaction: t, onSave: (n, r) => state.setNote(t, n, r)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MerchantAvatar(name: t.merchant, category: t.category, size: 42),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.merchant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text('${shortDate(t.date)} · ${t.category.label}',
                                style: const TextStyle(color: AppColors.stone, fontSize: 12.5)),
                            if (t.hasNote) ...[
                              const SizedBox(height: 5),
                              Wrap(spacing: 6, runSpacing: 4, children: [
                                if (t.note.isNotEmpty)
                                  _NoteTag(icon: Icons.sticky_note_2_rounded, text: t.note, strong: true),
                                for (final r in t.reasons) _NoteTag(icon: r.icon, text: r.label),
                              ]),
                            ] else
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text('+ Wat was het?',
                                    style: TextStyle(color: AppColors.brand, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                      Text(euro(t.amount), style: moneyStyle(15, color: AppColors.regret, weight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteTag extends StatelessWidget {
  const _NoteTag({required this.icon, required this.text, this.strong = false});
  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: strong ? AppColors.brand.withValues(alpha: 0.1) : AppColors.paper,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: strong ? AppColors.brand : AppColors.stone),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: strong ? AppColors.brand : const Color(0xFF5C6170))),
          ),
        ]),
      );
}
