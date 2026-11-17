import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../services/format.dart';
import '../theme.dart';
import 'bits.dart';
import 'sample_badge.dart';

/// De kaart die je swipet.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.isSample,
    this.dragProgress = 0,
    this.onNoteTap,
  });

  final Transaction transaction;
  final bool isSample;

  /// -1 (volledig links, spijt) … 0 … 1 (volledig rechts, opnieuw).
  final double dragProgress;
  final VoidCallback? onNoteTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final c = t.category.color;
    final p = dragProgress.clamp(-1.0, 1.0);
    final edge = p > 0
        ? Color.lerp(AppColors.line, AppColors.keep, p)!
        : Color.lerp(AppColors.line, AppColors.regret, -p)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: edge, width: p == 0 ? 1 : 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card - 1),
        child: Stack(
          children: [
            // Zachte gloed in de categoriekleur.
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CategoryPill(category: t.category, dense: true),
                      const Spacer(),
                      if (isSample) const SampleBadge(compact: true),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Center(child: MerchantAvatar(name: t.merchant, category: t.category, size: 72)),
                  const SizedBox(height: 14),
                  Text(
                    t.merchant,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(euro(t.amount), style: moneyStyle(50)),
                  ),
                  if (t.foreignAmount != null) ...[
                    const SizedBox(height: 6),
                    Center(child: _ForeignTag(t: t)),
                  ],
                  const Spacer(flex: 2),
                  _InfoRow(
                    icon: Icons.event_rounded,
                    text: t.settlementDate != null &&
                            t.settlementDate != t.date
                        ? '${longDate(t.date)} · verrekend ${dayMonth(t.settlementDate!)}'
                        : longDate(t.date),
                  ),
                  if (t.source.isNotEmpty)
                    _InfoRow(icon: Icons.account_balance_rounded, text: t.source),
                  const SizedBox(height: 4),
                  Text(
                    t.rawDescriptor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.stone,
                      letterSpacing: 0.3,
                      fontFeatures: tabular,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NoteButton(t: t, onTap: onNoteTap),
                ],
              ),
            ),
            if (p != 0) _Tint(progress: p),
            if (p != 0) VerdictStamp(progress: p),
          ],
        ),
      ),
    );
  }
}

class _ForeignTag extends StatelessWidget {
  const _ForeignTag({required this.t});
  final Transaction t;

  @override
  Widget build(BuildContext context) {
    final rate = t.fxRate == null ? '' : ' · 1 EUR = ${t.fxRate!.toStringAsFixed(4).replaceAll('.', ',')} ${t.foreignCurrency}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.currency_exchange_rounded, size: 13, color: AppColors.stone),
          const SizedBox(width: 5),
          Text(
            '${number2(t.foreignAmount!)} ${t.foreignCurrency}$rate',
            style: const TextStyle(
                fontSize: 12, color: AppColors.stone, fontWeight: FontWeight.w600, fontFeatures: tabular),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.stone),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5C6170), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.t, this.onTap});
  final Transaction t;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final has = t.hasNote;
    final label = has
        ? [
            if (t.note.isNotEmpty) t.note,
            ...t.reasons.map((r) => r.label),
          ].join(' · ')
        : 'Wat was het?';
    return Pressable(
      semanticLabel: has ? 'Notitie: $label' : 'Wat was het?',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: has ? AppColors.brand.withValues(alpha: 0.08) : AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: has ? AppColors.brand.withValues(alpha: 0.3) : AppColors.line),
        ),
        child: Row(
          children: [
            Icon(has ? Icons.sticky_note_2_rounded : Icons.edit_note_rounded,
                size: 19, color: has ? AppColors.brand : AppColors.stone),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: has ? FontWeight.w700 : FontWeight.w600,
                  color: has ? AppColors.brand : const Color(0xFF5C6170),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: has ? AppColors.brand : AppColors.stone),
          ],
        ),
      ),
    );
  }
}

class _Tint extends StatelessWidget {
  const _Tint({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final keep = progress > 0;
    final color = keep ? AppColors.keep : AppColors.regret;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: keep ? Alignment.centerLeft : Alignment.centerRight,
              end: keep ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                color.withValues(alpha: 0.32 * progress.abs()),
                color.withValues(alpha: 0.05 * progress.abs()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stempel "OPNIEUW" / "SPIJT" met rotatie en een "plof"-schaal.
class VerdictStamp extends StatelessWidget {
  const VerdictStamp({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final keep = progress > 0;
    final strength = progress.abs().clamp(0.0, 1.0);
    final color = keep ? AppColors.keep : AppColors.regret;
    final scale = 1.5 - 0.5 * Curves.easeOutBack.transform(strength);
    return Positioned(
      top: 54,
      left: keep ? 22 : null,
      right: keep ? null : 22,
      child: IgnorePointer(
        child: Opacity(
          opacity: strength,
          child: Transform.rotate(
            angle: (keep ? -14 : 14) * math.pi / 180,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(keep ? Icons.replay_rounded : Icons.block_rounded,
                        color: color, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      keep ? 'OPNIEUW' : 'SPIJT',
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
