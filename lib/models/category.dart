import 'package:material_ui/material_ui.dart';

/// Uitgavencategorieën voor de automatische indeling.
enum SpendCategory {
  boodschappen('Boodschappen', Icons.shopping_basket_rounded, Color(0xFF22A06B)),
  uitEten('Uit eten/Takeaway', Icons.restaurant_rounded, Color(0xFFF97316)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  abonnementen('Abonnementen', Icons.autorenew_rounded, Color(0xFF8B5CF6)),
  vervoer('Vervoer', Icons.directions_car_rounded, Color(0xFF0EA5E9)),
  ontspanning('Ontspanning', Icons.celebration_rounded, Color(0xFFEAB308)),
  overig('Overig', Icons.more_horiz_rounded, Color(0xFF64748B));

  const SpendCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
