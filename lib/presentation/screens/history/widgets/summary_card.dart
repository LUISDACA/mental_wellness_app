import 'package:flutter/material.dart';
import '../models/history_entry.dart';

class SummaryCard extends StatelessWidget {
  final List<HistoryEntry> view;
  final String Function(String) labelFor;
  const SummaryCard({super.key, required this.view, required this.labelFor});

  @override
  Widget build(BuildContext context) {
    if (view.isEmpty) return const SizedBox.shrink();
    final avg =
        view.map((e) => e.severity).reduce((a, b) => a + b) / view.length;
    final counts = <String, int>{};
    for (final e in view) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    final domKey =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights),
        title: Text('Promedio de severidad: ${avg.toStringAsFixed(0)}/100'),
        subtitle: Text('Emoción dominante: ${labelFor(domKey)}'),
      ),
    );
  }
}