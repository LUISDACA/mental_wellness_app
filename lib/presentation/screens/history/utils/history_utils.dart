import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/history_entry.dart';

Color colorForEmotion(String emo) {
  switch (emo) {
    case 'happiness':
      return Colors.green;
    case 'sadness':
      return Colors.blueGrey;
    case 'anxiety':
      return Colors.orange;
    case 'anger':
      return Colors.redAccent;
    default:
      return Colors.teal;
  }
}

String labelForEmotion(String emo) {
  switch (emo) {
    case 'happiness':
      return 'Felicidad';
    case 'sadness':
      return 'Tristeza';
    case 'anxiety':
      return 'Ansiedad';
    case 'anger':
      return 'Enojo';
    default:
      return 'Neutral';
  }
}

String formatDateShort(BuildContext context, DateTime d) {
  return DateFormat.Md(Localizations.localeOf(context).toString())
      .format(d.toLocal());
}

double avgSeverity(List<HistoryEntry> list) => list.isEmpty
    ? 0
    : list.map((e) => e.severity).reduce((a, b) => a + b) / list.length;

String dominantEmotion(List<HistoryEntry> list) {
  if (list.isEmpty) return 'neutral';
  final m = <String, int>{};
  for (final e in list) {
    m[e.emotion] = (m[e.emotion] ?? 0) + 1;
  }
  return m.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}