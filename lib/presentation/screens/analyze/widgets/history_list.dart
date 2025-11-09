import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final ScrollController controller;
  final String? avatarUrl;
  final String locale;

  const HistoryList({
    super.key,
    required this.history,
    required this.controller,
    required this.avatarUrl,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Aún no tienes análisis guardados.\nEscribe o dicta cómo te sientes.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = history[i];
        final created = DateTime.tryParse('${m['created_at'] ?? ''}')
                ?.toLocal() ??
            DateTime.now();
        final txt = '${m['text_input'] ?? ''}';
        final emo = '${m['detected_emotion'] ?? 'neutral'}';
        final sev = (m['severity'] ?? 0) as int;
        final score = (m['score'] ?? 0.0) as num;

        final dateStr = DateFormat.yMMMMEEEEd(locale).add_Hm().format(created);

        return Card(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      (avatarUrl != null) ? NetworkImage(avatarUrl!) : null,
                  child: (avatarUrl == null) ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      if (txt.isNotEmpty)
                        Text(
                          txt,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(emo),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(
                              'Sev $sev/100 • ${(score * 100).toStringAsFixed(0)}%',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}