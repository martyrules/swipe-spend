import 'package:material_ui/material_ui.dart';

import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final SpendCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 16, color: category.color),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              color: category.color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
