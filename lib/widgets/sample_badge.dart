import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Duidelijk label dat de getoonde data voorbeelddata is.
class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key, this.compact = false, this.onDark = false});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? const Color(0xFFFFD27A) : AppColors.sampleInk;
    return Semantics(
      label: 'Voorbeelddata',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12, vertical: compact ? 4 : 6),
        decoration: BoxDecoration(
          color: AppColors.sample.withValues(alpha: onDark ? 0.18 : 0.16),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.sample.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded, size: compact ? 13 : 16, color: fg),
            const SizedBox(width: 4),
            Text(
              'Voorbeelddata',
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner bovenaan schermen die voorbeelddata tonen.
class SampleBanner extends StatelessWidget {
  const SampleBanner({super.key, this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 10)});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.sample.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, size: 17, color: AppColors.sampleInk),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Voorbeelddata: verzonnen uitgaven, geen echte bankgegevens.',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sampleInk),
            ),
          ),
        ],
      ),
    );
  }
}
