import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_divider.dart';
import 'typing_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final bool assistantTyping;
  final ScrollController controller;
  const MessageList({
    super.key,
    required this.messages,
    required this.assistantTyping,
    required this.controller,
  });

  DateTime _parseDt(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse('$v') ?? DateTime.now();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final locale = Localizations.localeOf(context).toString();

    if (that == today) return 'Hoy';
    if (that == today.subtract(const Duration(days: 1))) return 'Ayer';
    return DateFormat.yMMMMd(locale).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: messages.length + (assistantTyping ? 1 : 0),
      itemBuilder: (context, index) {
        final isTypingRow = assistantTyping && index == messages.length;
        if (isTypingRow) return const TypingBubble();

        final m = messages[index];
        final isUser = m['role'] == 'user';
        final dt = _parseDt(m['created_at']).toLocal();

        bool showHeader = false;
        if (index == 0) {
          showHeader = true;
        } else {
          final prevDt = _parseDt(messages[index - 1]['created_at']).toLocal();
          showHeader = !_sameDay(prevDt, dt);
        }

        final bubble = Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${m['content']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        );

        if (!showHeader) return bubble;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DateDivider(label: _dayLabel(context, dt)),
            bubble,
          ],
        );
      },
    );
  }
}