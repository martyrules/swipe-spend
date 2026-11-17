import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_spend/models/category.dart';
import 'package:swipe_spend/models/reason.dart';
import 'package:swipe_spend/models/transaction.dart';
import 'package:swipe_spend/services/csv_parser.dart';
import 'package:swipe_spend/services/insights.dart';

void main() {
  const parser = CsvParser();
  final sample = File('assets/voorbeelddata_oktober_2026.csv').readAsStringSync();

  test('voorbeelddata: 41 uitgaven, loon overgeslagen', () {
    final r = parser.parse(sample);
    expect(r.expenses.length, 41);
    expect(r.skippedIncome, 1);
    expect(r.skippedInvalid, 0);
    final ue = r.expenses.firstWhere((t) => t.merchant == 'Uber Eats');
    expect(ue.category, SpendCategory.uitEten);
    expect(ue.amount, 27.45);
    expect(ue.date, DateTime(2026, 10, 3));
    SpendCategory cat(String m) => r.expenses.firstWhere((t) => t.merchant == m).category;
    expect(cat('NMBS'), SpendCategory.vervoer);
    expect(cat('Netflix'), SpendCategory.abonnementen);
    expect(cat('Zalando'), SpendCategory.shopping);
    expect(cat('Kinepolis'), SpendCategory.ontspanning);
    expect(cat('Colruyt'), SpendCategory.boodschappen);
    // Ruwe Argenta-stijl descriptors worden opgekuist.
    expect(cat('Laadpaal'), SpendCategory.vervoer);
    expect(cat('Amazon'), SpendCategory.shopping);
    expect(cat('Geldopname'), SpendCategory.cash);
    expect(cat('Kosten geldopname'), SpendCategory.cash);
    expect(cat('Steam'), SpendCategory.ontspanning);
    expect(cat('F1 TV'), SpendCategory.abonnementen);
    expect(cat('Hetzner'), SpendCategory.abonnementen);
    final amazon = r.expenses.firstWhere((t) => t.merchant == 'Amazon');
    expect(amazon.rawDescriptor, 'AMAZON.BE X7K2M9Q1A LUXEMBOURG DUB');
  });

  test('komma als scheidingsteken met quotes en duizendtallen', () {
    const raw = 'datum,omschrijving,tegenpartij,bedrag\n'
        '05/11/2026,"Aankoop, online",Bol.com,"-1.234,56"\n'
        '2026-11-06,Tankbeurt,Q8,-45.10\n';
    final r = parser.parse(raw);
    expect(r.expenses.length, 2);
    expect(r.expenses[0].amount, closeTo(1234.56, 1e-9));
    expect(r.expenses[0].rawDescriptor, 'Aankoop, online');
    expect(r.expenses[1].amount, closeTo(45.10, 1e-9));
  });

  test('bedrag-parsing', () {
    expect(CsvParser.parseAmount('-12,50'), -12.5);
    expect(CsvParser.parseAmount('€ -1.000,00'), -1000);
    expect(CsvParser.parseAmount('-1,000.25'), -1000.25);
    expect(CsvParser.parseAmount('abc'), isNull);
  });

  test('spijt-inzichten', () {
    final tx = parser.parse(sample).expenses;
    for (final t in tx) {
      t.verdict = t.category == SpendCategory.uitEten ? Verdict.regret : Verdict.keep;
    }
    final i = SpendInsights(tx);
    final expected = tx
        .where((t) => t.category == SpendCategory.uitEten)
        .fold<double>(0, (s, t) => s + t.amount);
    expect(i.totalRegret, closeTo(expected, 1e-9));
    expect(i.monthlySavings, closeTo(expected, 1e-9));
    expect(i.byCategory.first.category, SpendCategory.uitEten);
  });

  test('transactie JSON round-trip (lokale opslag)', () {
    final t = parser.parse(sample).expenses.first
      ..verdict = Verdict.regret
      ..note = 'testje'
      ..reasons = {Reason.impuls, Reason.verveling};
    final back = Transaction.fromJson(t.toJson());
    expect(back.merchant, t.merchant);
    expect(back.verdict, Verdict.regret);
    expect(back.note, 'testje');
    expect(back.reasons, {Reason.impuls, Reason.verveling});
    expect(back.date, t.date);
  });
}
