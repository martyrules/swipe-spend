import 'package:material_ui/material_ui.dart';

/// Uitgavencategorieën voor de automatische indeling.
enum SpendCategory {
  boodschappen('Boodschappen', Icons.shopping_basket_rounded, Color(0xFF3DAA5C)),
  uitEten('Uit eten/Takeaway', Icons.restaurant_rounded, Color(0xFFF28C28)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFE0479E)),
  abonnementen('Abonnementen', Icons.autorenew_rounded, Color(0xFF7C5CFA)),
  vervoer('Vervoer', Icons.electric_car_rounded, Color(0xFF2E9BE6)),
  ontspanning('Ontspanning', Icons.sports_esports_rounded, Color(0xFFE2A80F)),
  cash('Cash & kosten', Icons.local_atm_rounded, Color(0xFF5B6B7F)),
  overig('Overig', Icons.category_rounded, Color(0xFF8A8F9C));

  const SpendCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static SpendCategory byName(String? name) => SpendCategory.values
      .firstWhere((c) => c.name == name, orElse: () => SpendCategory.overig);
}
