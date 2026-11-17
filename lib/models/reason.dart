import 'package:material_ui/material_ui.dart';

/// Snelle reden-chips bij "Wat was het?".
enum Reason {
  impuls('Impuls', Icons.bolt_rounded),
  verveling('Verveling', Icons.hourglass_empty_rounded),
  nodig('Nodig', Icons.check_circle_outline_rounded),
  cadeau('Cadeau', Icons.card_giftcard_rounded),
  gepland('Gepland', Icons.event_available_rounded);

  const Reason(this.label, this.icon);

  final String label;
  final IconData icon;

  static Reason? byName(String name) {
    for (final r in Reason.values) {
      if (r.name == name) return r;
    }
    return null;
  }
}
