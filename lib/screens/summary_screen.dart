import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../services/format.dart';
import '../services/insights.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/sample_badge.dart';
import 'import_screen.dart';
import 'swipe_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  static const route = '/overzicht';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insights = SpendInsights(state.transactions);
    final theme = Theme.of(context);
    final regrets = insights.regrets;
    final cats = insights.byCategory;
    final top = insights.topRegretMerchant;
    final unreviewed = state.transactions.length - state.reviewedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spijt-overzicht'),
        actions: [
          if (state.isSample)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SampleBadge(compact: true),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (state.isSample)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: SampleBanner(),
              ),
            if (unreviewed > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Nog $unreviewed uitgave(n) niet beoordeeld.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            _HeroCard(insights: insights),
            const SizedBox(height: 12),
            _SavingsCard(insights: insights, top: top),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spijt per categorie',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (insights.totalRegret > 0)
                      SizedBox(
                        height: 180,
                        child: _Donut(insights: insights, stats: cats),
                      ),
                    const SizedBox(height: 12),
                    for (final c in cats) _CategoryRow(stat: c),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Je spijt-uitgaven (${regrets.length})',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (regrets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Geen spijt. Proper gedaan!'),
                      ),
                    for (final t in regrets)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              t.category.color.withValues(alpha: 0.14),
                          child: Icon(t.category.icon,
                              color: t.category.color, size: 20),
                        ),
                        title: Text(t.merchant,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${shortDate(t.date)} · ${t.category.label}'),
                        trailing: Text(
                          euro(t.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.regret),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (unreviewed > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Verder swipen'),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () {
                state.restartReview();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    SwipeScreen.route,
                    (r) => r.settings.name == ImportScreen.route);
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Opnieuw swipen'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  ImportScreen.route, (r) => false),
              child: const Text('Andere maand inladen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.insights});
  final SpendInsights insights;

  @override
  Widget build(BuildContext context) {
    final share = insights.regretShare;
    return Card(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deze maand',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                      label: 'Uitgegeven',
                      value: euro(insights.totalSpent),
                      color: Colors.white),
                ),
                Expanded(
                  child: _Figure(
                      label: 'Spijt',
                      value: euro(insights.totalRegret),
                      color: const Color(0xFFFF8A8E)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 12,
                color: AppColors.regret,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percent(share)} van je uitgaven was spijt',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.insights, required this.top});
  final SpendInsights insights;
  final (String, int, double)? top;

  @override
  Widget build(BuildContext context) {
    final hasRegret = insights.totalRegret > 0;
    return Card(
      color: AppColors.accent.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.savings_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasRegret
                        ? 'Als je dit niet meer doet, bespaar je ${euro(insights.monthlySavings)} per maand.'
                        : 'Geen spijt-uitgaven: niks te schrappen deze maand.',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17, height: 1.3),
                  ),
                  if (hasRegret) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Dat is ${euroRound(insights.yearlySavings)} op een jaar.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  if (top != null && top!.$2 > 1) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Grootste boosdoener: ${top!.$1} (${top!.$2}x, ${euro(top!.$3)}).',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({required this.insights, required this.stats});
  final SpendInsights insights;
  final List<CategoryStat> stats;

  @override
  Widget build(BuildContext context) {
    final withRegret = stats.where((s) => s.regret > 0).toList();
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 54,
            startDegreeOffset: -90,
            sections: [
              for (final s in withRegret)
                PieChartSectionData(
                  value: s.regret,
                  color: s.category.color,
                  radius: 30,
                  title: '',
                ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(euroRound(insights.totalRegret),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 20)),
            const Text('spijt', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ],
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
              CategoryChip(category: stat.category),
              const Spacer(),
              Text(
                '${euro(stat.regret)} / ${euro(stat.spent)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: stat.regretShare,
              minHeight: 8,
              color: stat.category.color,
              backgroundColor: stat.category.color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${percent(stat.regretShare)} spijt · ${stat.regretCount} uitgave(n)',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
