import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../utils/history_utils.dart';

class AiAdviceSheet extends StatelessWidget {
  final HistoryEntry entry;
  const AiAdviceSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology_alt_outlined, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Detalle del análisis',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(
                label: Text(labelForEmotion(entry.emotion)),
                visualDensity: VisualDensity.compact),
            Chip(
              label: Text(
                  'Severidad ${entry.severity}/100${entry.score > 0 ? " • ${(entry.score * 100).round()}%" : ""}'),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (entry.severity.clamp(0, 100)) / 100.0,
              minHeight: 8,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          if ((entry.textInput ?? '').trim().isNotEmpty) ...[
            Text('Lo que escribiste',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(entry.textInput!.trim()),
            const SizedBox(height: 14),
          ],
          Text('Lo que te sugirió la IA',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text((entry.advice ?? '').trim().isNotEmpty
              ? entry.advice!.trim()
              : 'No se guardó consejo para este registro.'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar')),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> showAiAdviceSheet(BuildContext context, HistoryEntry e) async {
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AiAdviceSheet(entry: e),
  );
}