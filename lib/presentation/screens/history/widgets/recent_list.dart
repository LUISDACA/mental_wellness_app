import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../utils/history_utils.dart';
import 'ai_advice_sheet.dart';

class RecentList extends StatelessWidget {
  final List<HistoryEntry> entries;
  const RecentList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registros recientes',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final e in entries.reversed.take(10))
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorForEmotion(e.emotion).withValues(alpha: 0.15),
              child: Icon(Icons.favorite, color: colorForEmotion(e.emotion)),
            ),
            title: Text(
                '${labelForEmotion(e.emotion)}  •  severidad ${e.severity}/100  •  ${(e.score * 100).round()}%'),
            subtitle: Text(formatDateShort(context, e.createdAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAiAdviceSheet(context, e),
          ),
      ],
    );
  }
}