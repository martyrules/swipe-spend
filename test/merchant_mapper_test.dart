import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_spend/models/category.dart';
import 'package:swipe_spend/services/merchant_mapper.dart';

void main() {
  const m = MerchantMapper();

  final cases = <String, (String, SpendCategory)>{
    'Public Charging Belgiu Bruxelles BEL': ('Laadpaal', SpendCategory.vervoer),
    'AMAZON.BE B00AAA111 LUXEMBOURG DUB': ('Amazon', SpendCategory.shopping),
    'CASH Bancontact Gent BEL': ('Geldopname', SpendCategory.cash),
    'KOSTEN OP GELDOPNEMING': ('Kosten geldopname', SpendCategory.cash),
    'WL STEAM PURCHASE BELLEVUE WA': ('Steam', SpendCategory.ontspanning),
    'Battle.net Cork IRL': ('Battle.net', SpendCategory.ontspanning),
    'WWW.F1.COM LONDON LND': ('F1 TV', SpendCategory.abonnementen),
    'TRADINGVIEW CHARTING S Dublin D': ('TradingView', SpendCategory.abonnementen),
    'ANTHROPIC CLAUDE SUB SAN FRANCISCO CA': ('Claude', SpendCategory.abonnementen),
    'GROK XAI PALO ALTO CA': ('Grok', SpendCategory.abonnementen),
    'HETZNER ONLINE GMBH GUNZENHAUSEN DEU': ('Hetzner', SpendCategory.abonnementen),
    'CARREFOUR GENT ZUID GENT BEL': ('Carrefour', SpendCategory.boodschappen),
    'BPOST GENT Gent BEL': ('bpost', SpendCategory.overig),
    'BREAKOUTPROP.COM Wilmington DE': ('Breakout Prop', SpendCategory.overig),
  };

  for (final e in cases.entries) {
    test('mapt "${e.key}"', () {
      final info = m.map(descriptor: e.key);
      expect(info.name, e.value.$1);
      expect(info.category, e.value.$2);
    });
  }

  test('generieke opkuis van onbekende descriptors', () {
    expect(MerchantMapper.cleanDescriptor('Bakkerij Janssens Bvba Antwerpen BEL'), 'Bakkerij Janssens');
    expect(MerchantMapper.cleanDescriptor('Euro Winkel Sint-Truiden Sint-Truiden BEL'), 'Euro Winkel');
    expect(MerchantMapper.cleanDescriptor('SOME SHOP LONDON GBR'), 'Some Shop');
    expect(m.map(descriptor: 'Bistro De Hoek Gent BEL').name, 'Bistro De Hoek');
    expect(m.map(descriptor: 'Bistro De Hoek Gent BEL').category, SpendCategory.uitEten);
  });
}
