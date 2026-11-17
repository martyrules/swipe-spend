import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../services/format.dart';
import '../theme.dart';
import 'category_chip.dart';
import 'sample_badge.dart';

/// De kaart die je swipet.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.isSample,
    this.dragProgress = 0,
  });

  final Transaction transaction;
  final bool isSample;

  /// -1 (volledig links, spijt) … 0 … 1 (volledig rechts, opnieuw).
  final double dragProgress;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Kleurband bovenaan in de categoriekleur.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 150,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.category.color.withValues(alpha: 0.22),
                      t.category.color.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryChip(category: t.category),
                      const Spacer(),
                      if (isSample) const SampleBadge(compact: true),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: t.category.color.withValues(alpha: 0.15),
                      child: Icon(t.category.icon,
                          size: 38, color: t.category.color),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      t.merchant,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      euro(t.amount),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 18, color: Colors.black45),
                      const SizedBox(width: 6),
                      Text(shortDate(t.date),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
                ],
              ),
            ),
            if (dragProgress != 0) _Overlay(progress: dragProgress),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final keep = progress > 0;
    final color = keep ? AppColors.keep : AppColors.regret;
    final strength = progress.abs().clamp(0.0, 1.0);
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: color.withValues(alpha: 0.55 * strength),
          alignment: keep ? Alignment.topLeft : Alignment.topRight,
          padding: const EdgeInsets.all(28),
          child: Opacity(
            opacity: strength,
            child: Transform.rotate(
              angle: keep ? -0.25 : 0.25,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  keep ? 'OPNIEUW' : 'SPIJT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
