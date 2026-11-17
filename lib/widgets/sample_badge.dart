import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Duidelijk label dat de getoonde data voorbeelddata is.
class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Voorbeelddata',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
        decoration: BoxDecoration(
          color: AppColors.sample.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.sample.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_rounded,
                size: compact ? 13 : 16, color: const Color(0xFFB45309)),
            const SizedBox(width: 4),
            Text(
              'Voorbeelddata',
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309),
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
  const SampleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sample.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, size: 18, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Voorbeelddata: verzonnen uitgaven, geen echte bankgegevens.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
