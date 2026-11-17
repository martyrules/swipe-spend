import '../models/category.dart';

/// Eenvoudige categorisatie op basis van trefwoorden.
///
/// De volgorde telt: "uber eats" moet bij Uit eten landen vóór "uber" bij
/// Vervoer.
class Categorizer {
  const Categorizer();

  static const List<(SpendCategory, List<String>)> _rules = [
    (SpendCategory.uitEten, [
      'uber eats', 'takeaway', 'deliveroo', 'starbucks', 'mcdonald', 'frituur',
      'restaurant', 'pizza', 'burger', 'café', 'cafe', 'etentje', 'quick',
      'exki', 'panos',
    ]),
    (SpendCategory.boodschappen, [
      'delhaize', 'colruyt', 'aldi', 'lidl', 'carrefour', 'albert heijn',
      'okay', 'spar', 'bakkerij', 'bakker', 'slager', 'jumbo', 'intermarché',
    ]),
    (SpendCategory.abonnementen, [
      'spotify', 'netflix', 'disney', 'proximus', 'telenet', 'orange',
      'basic-fit', 'basic fit', 'apple.com', 'icloud', 'youtube', 'streamz',
      'hbo', 'prime video', 'chatgpt', 'domiciliering',
    ]),
    (SpendCategory.vervoer, [
      'nmbs', 'sncb', 'q8', 'totalenergies', 'total ', 'shell', 'esso',
      'de lijn', 'stib', 'blue-bike', 'parking', 'uber', 'bolt', 'poppy',
      'cambio', 'texaco', 'lukoil',
    ]),
    (SpendCategory.ontspanning, [
      'kinepolis', 'ticketmaster', 'bowling', 'steam', 'playstation',
      'nintendo', 'concert', 'cinema', 'museum', 'pretpark', 'walibi',
      'plopsa',
    ]),
    (SpendCategory.shopping, [
      'bol.com', 'zalando', 'action', 'amazon', 'h&m', 'primark', 'ikea',
      'coolblue', 'mediamarkt', 'decathlon', 'zara', 'fnac', 'hema', 'kruidvat',
      'shein', 'temu',
    ]),
  ];

  SpendCategory categorize(String description, String counterparty) {
    final text = '${counterparty.toLowerCase()} ${description.toLowerCase()} ';
    for (final (category, keywords) in _rules) {
      if (keywords.any(text.contains)) return category;
    }
    return SpendCategory.overig;
  }
}
