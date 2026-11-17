import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../services/csv_parser.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sample_badge.dart';
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

  Future<void> _loadSample() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await AppScope.of(context).loadSample();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickCsv() async {
    setState(() => _error = null);
    final state = AppScope.of(context);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Kies je CSV-export',
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
      );
      if (file == null) return;
      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      String raw;
      try {
        raw = utf8.decode(bytes);
      } on FormatException {
        raw = latin1.decode(bytes); // sommige banken exporteren in Latin-1
      }
      state.loadCsv(raw, name: file.name);
    } on CsvFormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Kon het bestand niet lezen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Uitgaven inladen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              'Haal een CSV uit je bank-app (Argenta, KBC, VDK, …) of probeer het eerst met voorbeelddata.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _OptionCard(
              icon: Icons.science_rounded,
              color: AppColors.sample,
              title: 'Probeer met voorbeelddata',
              subtitle:
                  '38 verzonnen uitgaven uit oktober 2026. Geen echte bankgegevens.',
              trailing: const SampleBadge(compact: true),
              child: FilledButton.icon(
                onPressed: _busy ? null : _loadSample,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Laad voorbeelddata'),
              ),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              icon: Icons.upload_file_rounded,
              color: AppColors.accent,
              title: 'Eigen CSV kiezen',
              subtitle:
                  'Kolommen: date;description;counterparty;amount. Scheiding met ; of , en komma-decimalen gaan ook. Alles blijft op je toestel.',
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickCsv,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Kies CSV-bestand'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.regret.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.regret)),
              ),
            ],
            if (state.hasData) ...[
              const SizedBox(height: 24),
              _LoadedSummary(state: state),
            ],
          ],
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
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            child,
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
    final first = state.transactions.first.date;
    final preview = state.transactions.take(4).toList();
    return Card(
      color: AppColors.accent.withValues(alpha: 0.08),
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
                  child: Text(
                    '${state.transactions.length} uitgaven ingeladen',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (state.isSample) const SampleBadge(compact: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${state.sourceName} · ${monthLabel(first)} · totaal ${euro(total)}'
              '${state.skippedIncome > 0 ? ' · ${state.skippedIncome} inkomst(en) overgeslagen' : ''}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            for (final t in preview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(t.category.icon, size: 18, color: t.category.color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.merchant)),
                    Text(euro(t.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Text('…', style: TextStyle(color: Colors.black38)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                state.restartReview();
                Navigator.of(context).pushNamed(SwipeScreen.route);
              },
              icon: const Icon(Icons.swipe_rounded),
              label: const Text('Start met swipen'),
            ),
          ],
        ),
      ),
    );
  }
}
