import 'package:material_ui/material_ui.dart';

import '../models/reason.dart';
import '../models/transaction.dart';
import '../services/format.dart';
import '../theme.dart';
import 'bits.dart';

/// Bottom sheet "Wat was het?": korte notitie + snelle reden-chips.
Future<void> showNoteSheet(
  BuildContext context, {
  required Transaction transaction,
  required void Function(String note, Set<Reason> reasons) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NoteSheet(transaction: transaction, onSave: onSave),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.transaction, required this.onSave});
  final Transaction transaction;
  final void Function(String note, Set<Reason> reasons) onSave;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _text =
      TextEditingController(text: widget.transaction.note);
  late final Set<Reason> _reasons = {...widget.transaction.reasons};

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_text.text, _reasons);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MerchantAvatar(name: t.merchant, category: t.category, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wat was het?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('${t.merchant} · ${euro(t.amount)} · ${shortDate(t.date)}',
                        style: const TextStyle(color: AppColors.stone, fontFeatures: tabular)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: false,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'bv. "kabel voor de laptop" of "pizza na het sporten"',
              prefixIcon: Icon(Icons.edit_note_rounded),
              counterText: '',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 4),
          const Text('Waarom?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in Reason.values)
                FilterChip(
                  avatar: Icon(r.icon, size: 16),
                  label: Text(r.label),
                  selected: _reasons.contains(r),
                  showCheckmark: false,
                  selectedColor: AppColors.brand.withValues(alpha: 0.14),
                  onSelected: (on) => setState(() => on ? _reasons.add(r) : _reasons.remove(r)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: const Text('Bewaren')),
        ],
      ),
    );
  }
}
