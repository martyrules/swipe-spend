import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../models/import_result.dart';
import '../services/format.dart';
import '../services/pdf_text/pdf_text.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/app_menu.dart';
import '../widgets/bits.dart';
import '../widgets/brand.dart';
import '../widgets/sample_badge.dart';
import 'summary_screen.dart';
import 'swipe_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  static const route = '/import';

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
    } on ImportFormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Kon het bestand niet lezen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadSample() => _run(() => AppScope.read(context).loadSample());

  Future<void> _pickCsv() => _run(() async {
        final state = AppScope.read(context);
        final file = await FilePicker.pickFile(
          dialogTitle: 'Kies je CSV-export',
          type: FileType.custom,
          allowedExtensions: const ['csv', 'txt'],
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        String raw;
        try {
          raw = utf8.decode(bytes);
        } on FormatException {
          raw = latin1.decode(bytes); // sommige banken exporteren in Latin-1
        }
        state.loadCsv(raw, name: file.name);
      });

  Future<void> _pickPdf() => _run(() async {
        final state = AppScope.read(context);
        final file = await FilePicker.pickFile(
          dialogTitle: 'Kies je Argenta kredietkaart-afschrift',
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        final text = await extractPdfText(bytes); // lokaal, via pdf.js
        state.loadArgentaText(text, name: file.name);
      });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(hasData: state.hasData)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(children: [
              if (state.hasData) ...[
                _LoadedSummary(state: state),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text('Of laad iets anders in',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
              _OptionCard(
                icon: Icons.science_rounded,
                color: AppColors.sample,
                title: 'Probeer met voorbeelddata',
                subtitle: 'Een verzonnen maand (oktober 2026), met ook ruwe Argenta-omschrijvingen.',
                trailing: const SampleBadge(compact: true),
                buttonLabel: 'Laad voorbeelddata',
                primary: true,
                onPressed: _busy ? null : _loadSample,
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.regret,
                title: 'Argenta kredietkaart (pdf)',
                subtitle: pdfImportSupported
                    ? 'Je maandafschrift als pdf. Wordt in je browser gelezen: het bestand verlaat je toestel niet.'
                    : 'Pdf-import werkt voorlopig enkel in de web-versie.',
                buttonLabel: 'Kies pdf-afschrift',
                onPressed: _busy || !pdfImportSupported ? null : _pickPdf,
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: Icons.table_chart_rounded,
                color: AppColors.keep,
                title: 'Eigen CSV',
                subtitle: 'Kolommen date;description;counterparty;amount. ; of , en komma-decimalen gaan ook.',
                buttonLabel: 'Kies CSV-bestand',
                onPressed: _busy ? null : _pickCsv,
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.regret.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.regret),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB23A27)))),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: AppColors.stone),
                  SizedBox(width: 6),
                  Text('Alles blijft lokaal. Geen account, geen server.',
                      style: TextStyle(color: AppColors.stone, fontSize: 12.5)),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.hasData});
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 6, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [AppLogo(onDark: true), Spacer(), AppMenu(onDark: true)]),
              const SizedBox(height: 22),
              Text(
                hasData ? 'Klaar om te\nswipen?' : 'Welke maand gaan\nwe bekijken?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Laad je uitgaven in en beslis per uitgave: opnieuw of spijt.',
                style: TextStyle(color: Colors.white70, fontSize: 14.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.trailing,
    this.primary = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Color.lerp(color, Colors.black, 0.15)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF5C6170), height: 1.35)),
            const SizedBox(height: 12),
            primary
                ? FilledButton(onPressed: onPressed, child: Text(buttonLabel))
                : OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _LoadedSummary extends StatelessWidget {
  const _LoadedSummary({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.transactions.fold<double>(0, (s, t) => s + t.amount);
    final dates = state.transactions.map((t) => t.date).toList()..sort();
    final check = state.check;
    final started = state.reviewedCount > 0 && !state.isDone;
    final preview = state.transactions.take(3).toList();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.keep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${state.transactions.length} uitgaven ingeladen',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                if (state.isSample) const SampleBadge(compact: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${state.sourceName} · ${dayMonth(dates.first)} – ${dayMonth(dates.last)}'
              '${state.skippedIncome > 0 ? ' · ${state.skippedIncome} inkomst/terugbetaling overgeslagen' : ''}',
              style: const TextStyle(color: AppColors.stone),
            ),
            const SizedBox(height: 12),
            Text(euro(total), style: moneyStyle(36)),
            const Text('totaal uitgegeven', style: TextStyle(color: AppColors.stone)),
            if (check != null && check.statementNewBalance != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (check.matches ? AppColors.keep : AppColors.regret).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(check.matches ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      size: 16, color: check.matches ? AppColors.keep : AppColors.regret),
                  const SizedBox(width: 6),
                  Text(
                    check.matches
                        ? 'Klopt met "Nieuw Saldo" (${euro(check.statementNewBalance!)})'
                        : 'Wijkt af van "Nieuw Saldo" (${euro(check.statementNewBalance!)})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            for (final t in preview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    MerchantAvatar(name: t.merchant, category: t.category, size: 30),
                    const SizedBox(width: 6),
                    Expanded(child: Text(t.merchant, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(euro(t.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: tabular)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                if (!started) state.restartReview();
                Navigator.of(context).pushNamed(state.isDone ? SummaryScreen.route : SwipeScreen.route);
              },
              icon: Icon(state.isDone ? Icons.insights_rounded : Icons.swipe_rounded),
              label: Text(state.isDone
                  ? 'Bekijk je spijt-overzicht'
                  : started
                      ? 'Verder swipen (${state.reviewedCount}/${state.transactions.length})'
                      : 'Start met swipen'),
            ),
            if (state.isDone) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  state.restartReview();
                  Navigator.of(context).pushNamed(SwipeScreen.route);
                },
                child: const Text('Opnieuw swipen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
