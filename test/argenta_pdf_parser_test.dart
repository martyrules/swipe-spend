import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_spend/models/category.dart';
import 'package:swipe_spend/services/argenta_pdf_parser.dart';

/// Tests op een VERZONNEN afschrift (test/fixtures/argenta_voorbeeld.pdf,
/// tekst via pdf.js). Een optionele lokale fixture met een echt afschrift
/// staat in test/fixtures/private/ (gitignored, nooit committen).
void main() {
  const parser = ArgentaPdfParser();

  group('voorbeeld-afschrift (pdf.js-tekst)', () {
    final text = File('test/fixtures/argenta_voorbeeld_pdfjs.txt').readAsStringSync();
    final r = parser.parse(text);

    test('aantal, totaal en saldo-controle', () {
      expect(ArgentaPdfParser.looksLikeArgenta(text), isTrue);
      expect(r.expenses.length, 14);
      expect(r.skippedIncome, 1); // Amazon-terugbetaling
      expect(r.total, closeTo(226.79, 0.001));
      expect(r.check!.statementNewBalance, closeTo(202.80, 0.001));
      expect(r.check!.matches, isTrue);
      expect(r.check!.periodFrom, DateTime(2026, 10, 5));
    });

    test('vreemde munt + koers', () {
      final tv = r.expenses.firstWhere((t) => t.merchant == 'TradingView');
      expect(tv.amount, 13.64);
      expect(tv.foreignAmount, 15.0);
      expect(tv.foreignCurrency, 'USD');
      expect(tv.fxRate, closeTo(1.0997067, 1e-9));
      expect(tv.date, DateTime(2026, 10, 9));
    });

    test('kosten geldopname horen bij de opname', () {
      final cash = r.expenses.firstWhere((t) => t.merchant == 'Geldopname');
      final fee = r.expenses.firstWhere((t) => t.merchant == 'Kosten geldopname');
      expect(fee.amount, 6.0);
      expect(fee.date, cash.date);
      expect(fee.category, SpendCategory.cash);
      expect(r.expenses.indexOf(fee), r.expenses.indexOf(cash) + 1);
    });

    test('jaar uit de periode, ook voor november', () {
      final f1 = r.expenses.firstWhere((t) => t.merchant == 'F1 TV');
      expect(f1.date, DateTime(2026, 11, 2));
      expect(f1.settlementDate, DateTime(2026, 11, 3));
    });

    test('domiciliering en saldi worden niet als uitgave geteld', () {
      expect(r.expenses.any((t) => t.rawDescriptor.contains('DOMICILIERING')), isFalse);
      expect(r.expenses.any((t) => t.rawDescriptor.contains('saldo')), isFalse);
    });
  });

  test('ook pdftotext -layout-tekst (veel spaties, ingesprongen kosten)', () {
    const text = '''
Transacties van 05/10/2026 tot 04/11/2026
ARGENTA
                                  Vorig saldo van 05/10/2026                       100,00-
04/10          14/10              DOMICILIERING VIA UW BANK                        100,00+
19/10          20/10              CASH Iets Gent BEL                                40,00-
                                  KOSTEN OP GELDOPNEMING                             5,50-
22/10          23/10              VOORBEELD SHOP Wilmington DE        150,00-USD   136,40-
                                                                     1 EUR=1,0997067 USD
Nieuw Saldo                                                                        181,90-
''';
    final r = parser.parse(text);
    expect(r.expenses.length, 3);
    expect(r.total, closeTo(181.90, 0.001));
    expect(r.check!.matches, isTrue);
    expect(r.expenses.last.fxRate, closeTo(1.0997067, 1e-9));
  });

  test('jaarovergang: december-transacties op een januari-afschrift', () {
    const text = '''
Transacties van 05/12/2026 tot 04/01/2027
ARGENTA
28/12   29/12   WL STEAM PURCHASE BELLEVUE WA   9,99-
02/01   03/01   WWW.F1.COM LONDON LND   10,99-
''';
    final r = parser.parse(text);
    expect(r.expenses[0].date, DateTime(2026, 12, 28));
    expect(r.expenses[1].date, DateTime(2027, 1, 2));
  });

  final private = File('test/fixtures/private/argenta_echt_pdfjs.txt');
  test('echt afschrift (enkel lokaal, gitignored)', () {
    final r = parser.parse(private.readAsStringSync());
    expect(r.check!.matches, isTrue,
        reason: 'som ${r.check!.computedNewBalance} vs saldo ${r.check!.statementNewBalance}');
    // ignore: avoid_print
    print('Echt afschrift: ${r.expenses.length} uitgaven, totaal ${r.total.toStringAsFixed(2)}, '
        'Nieuw Saldo ${r.check!.statementNewBalance}, klopt: ${r.check!.matches}');
    final layout = File('test/fixtures/private/argenta_echt_layout.txt');
    if (layout.existsSync()) {
      final r2 = parser.parse(layout.readAsStringSync());
      expect(r2.expenses.length, r.expenses.length);
      expect(r2.total, closeTo(r.total, 0.001));
    }
  }, skip: private.existsSync() ? false : 'geen lokale private fixture');
}
