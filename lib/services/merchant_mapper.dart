import '../models/category.dart';
import 'categorizer.dart';

/// Resultaat van het opkuisen van een ruwe bank-omschrijving.
class MerchantInfo {
  const MerchantInfo(this.name, this.category);
  final String name;
  final SpendCategory category;
}

class _Rule {
  const _Rule(this.pattern, this.name, [this.category]);
  final String pattern;
  final String name;
  final SpendCategory? category;
}

/// Zet ruwe descriptors ("Public Charging Belgiu Bruxelles BEL") om naar een
/// leesbare naam + categorie ("Laadpaal", Vervoer). Uitbreidbaar: voeg regels
/// toe aan [_rules]; volgorde telt (specifiek vóór algemeen).
class MerchantMapper {
  const MerchantMapper({this.categorizer = const Categorizer()});

  final Categorizer categorizer;

  static const _rules = <_Rule>[
    _Rule(r'kosten op geldopneming|kosten geldopname', 'Kosten geldopname', SpendCategory.cash),
    _Rule(r'(^|\s)cash\s|geldopname|geldafhaling', 'Geldopname', SpendCategory.cash),
    _Rule(r'public charging|laadpaal|allego|ionity|blue corner', 'Laadpaal', SpendCategory.vervoer),
    _Rule(r'amazon', 'Amazon', SpendCategory.shopping),
    _Rule(r'steam', 'Steam', SpendCategory.ontspanning),
    _Rule(r'battle\.net|blizzard', 'Battle.net', SpendCategory.ontspanning),
    _Rule(r'f1\.com|f1 tv', 'F1 TV', SpendCategory.abonnementen),
    _Rule(r'tradingview', 'TradingView', SpendCategory.abonnementen),
    _Rule(r'anthropic|claude', 'Claude', SpendCategory.abonnementen),
    _Rule(r'\bgrok\b|\bxai\b|x\.ai', 'Grok', SpendCategory.abonnementen),
    _Rule(r'hetzner', 'Hetzner', SpendCategory.abonnementen),
    _Rule(r'openai|chatgpt', 'ChatGPT', SpendCategory.abonnementen),
    _Rule(r'carrefour', 'Carrefour', SpendCategory.boodschappen),
    _Rule(r'bpost', 'bpost', SpendCategory.overig),
    _Rule(r'breakoutprop', 'Breakout Prop', SpendCategory.overig),
    _Rule(r'bol\.com', 'Bol.com', SpendCategory.shopping),
    _Rule(r'zalando', 'Zalando', SpendCategory.shopping),
    _Rule(r'uber ?eats', 'Uber Eats', SpendCategory.uitEten),
    _Rule(r'takeaway|thuisbezorgd', 'Takeaway', SpendCategory.uitEten),
    _Rule(r'deliveroo', 'Deliveroo', SpendCategory.uitEten),
    _Rule(r'starbucks', 'Starbucks', SpendCategory.uitEten),
    _Rule(r'delhaize', 'Delhaize', SpendCategory.boodschappen),
    _Rule(r'colruyt', 'Colruyt', SpendCategory.boodschappen),
    _Rule(r'spotify', 'Spotify', SpendCategory.abonnementen),
    _Rule(r'netflix', 'Netflix', SpendCategory.abonnementen),
    _Rule(r'disney', 'Disney+', SpendCategory.abonnementen),
    _Rule(r'basic-?fit', 'Basic-Fit', SpendCategory.abonnementen),
    _Rule(r'\bnmbs\b|\bsncb\b', 'NMBS', SpendCategory.vervoer),
    _Rule(r'\bq8\b', 'Q8', SpendCategory.vervoer),
    _Rule(r'\baction\b', 'Action', SpendCategory.shopping),
    _Rule(r'kinepolis', 'Kinepolis', SpendCategory.ontspanning),
    _Rule(r'ticketmaster', 'Ticketmaster', SpendCategory.ontspanning),
    _Rule(r'primark', 'Primark', SpendCategory.shopping),
  ];

  static final _compiled = [
    for (final r in _rules) (RegExp(r.pattern, caseSensitive: false), r),
  ];

  /// Plaatsen die vaak achteraan een kaart-descriptor staan.
  static const _cities = [
    'antwerpen', 'gent', 'brussel', 'bruxelles', 'leuven', 'mechelen',
    'brugge', 'hasselt',
    'luxembourg', 'dublin', 'london', 'amsterdam', 'paris', 'berlin',
    'kortrijk', 'oostende', 'aalst', 'lier', 'genk', 'namur', 'liège',
  ];

  static const _legal = {'bvba', 'bv', 'nv', 'srl', 'sprl', 'gmbh', 'ltd', 'inc', 'sa', 'vzw'};

  MerchantInfo map({required String descriptor, String counterparty = ''}) {
    final haystack = '$counterparty $descriptor '.trim();
    for (final (re, rule) in _compiled) {
      if (re.hasMatch(haystack)) {
        return MerchantInfo(
          rule.name,
          rule.category ?? categorizer.categorize(descriptor, counterparty),
        );
      }
    }
    final name = counterparty.trim().isNotEmpty
        ? counterparty.trim()
        : cleanDescriptor(descriptor);
    return MerchantInfo(name, categorizer.categorize(descriptor, counterparty));
  }

  /// Generieke opkuis: landcode, stad en rechtsvorm eraf, nette hoofdletters.
  static String cleanDescriptor(String raw) {
    var words = raw.trim().split(RegExp(r'\s+'));
    if (words.length > 1 && RegExp(r'^[A-Z]{2,3}$').hasMatch(words.last)) {
      words = words.sublist(0, words.length - 1);
    }
    final lowerJoined = words.map((w) => w.toLowerCase()).toList();
    for (var i = 1; i < words.length; i++) {
      final w = lowerJoined[i];
      if (_cities.any((c) => w.startsWith(c)) ||
          RegExp(r'^(sint|st|saint|sankt)-').hasMatch(w)) {
        words = words.sublist(0, i);
        break;
      }
    }
    while (words.length > 1 && _legal.contains(words.last.toLowerCase())) {
      words = words.sublist(0, words.length - 1);
    }
    var name = words.join(' ');
    if (name.isEmpty) name = raw.trim();
    if (name == name.toUpperCase() && name.length > 3) {
      name = name
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }
    return name;
  }
}
