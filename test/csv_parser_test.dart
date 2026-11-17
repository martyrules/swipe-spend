import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_spend/models/category.dart';
import 'package:swipe_spend/models/transaction.dart';
import 'package:swipe_spend/services/csv_parser.dart';
import 'package:swipe_spend/services/insights.dart';

void main() {
  const parser = CsvParser();

  test('voorbeelddata: 38 uitgaven, loon overgeslagen', () {
    final raw = File('assets/voorbeelddata_oktober_2026.csv').readAsStringSync();
    final r = parser.parse(raw);
    expect(r.expenses.length, 38);
    expect(r.skippedIncome, 1);
    expect(r.skippedInvalid, 0);
    final ue = r.expenses.firstWhere((t) => t.counterparty == 'Uber Eats');
    expect(ue.category, SpendCategory.uitEten);
    expect(ue.amount, 27.45);
    expect(ue.date, DateTime(2026, 10, 3));
    expect(r.expenses.firstWhere((t) => t.counterparty == 'NMBS').category,
        SpendCategory.vervoer);
    expect(r.expenses.firstWhere((t) => t.counterparty == 'Netflix').category,
        SpendCategory.abonnementen);
    expect(r.expenses.firstWhere((t) => t.counterparty == 'Zalando').category,
        SpendCategory.shopping);
    expect(r.expenses.firstWhere((t) => t.counterparty == 'Kinepolis').category,
        SpendCategory.ontspanning);
    expect(r.expenses.firstWhere((t) => t.counterparty == 'Colruyt').category,
        SpendCategory.boodschappen);
  });

  test('komma als scheidingsteken met quotes en duizendtallen', () {
    const raw = 'datum,omschrijving,tegenpartij,bedrag\n'
        '05/11/2026,"Aankoop, online",Bol.com,"-1.234,56"\n'
        '2026-11-06,Tankbeurt,Q8,-45.10\n';
    final r = parser.parse(raw);
    expect(r.expenses.length, 2);
    expect(r.expenses[0].amount, closeTo(1234.56, 1e-9));
    expect(r.expenses[0].description, 'Aankoop, online');
    expect(r.expenses[1].amount, closeTo(45.10, 1e-9));
  });

  test('bedrag-parsing', () {
    expect(CsvParser.parseAmount('-12,50'), -12.5);
    expect(CsvParser.parseAmount('€ -1.000,00'), -1000);
    expect(CsvParser.parseAmount('-1,000.25'), -1000.25);
    expect(CsvParser.parseAmount('abc'), isNull);
  });

  test('spijt-inzichten', () {
    final raw = File('assets/voorbeelddata_oktober_2026.csv').readAsStringSync();
    final tx = parser.parse(raw).expenses;
    for (final t in tx) {
      t.verdict = t.category == SpendCategory.uitEten
          ? Verdict.regret
          : Verdict.keep;
    }
    final i = SpendInsights(tx);
    final expected = tx
        .where((t) => t.category == SpendCategory.uitEten)
        .fold<double>(0, (s, t) => s + t.amount);
    expect(i.totalRegret, closeTo(expected, 1e-9));
    expect(i.monthlySavings, closeTo(expected, 1e-9));
    expect(i.byCategory.first.category, SpendCategory.uitEten);
  });
}
