import 'package:flutter/material.dart';

class ResultOverlay extends StatelessWidget {
  final bool visible;
  final String? emotion;
  final int? severity;
  final num? score;
  final String? advice;
  final VoidCallback onClose;
  final VoidCallback? onOpenSos;

  const ResultOverlay({
    super.key,
    required this.visible,
    required this.emotion,
    required this.severity,
    required this.score,
    required this.advice,
    required this.onClose,
    this.onOpenSos,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final sev = severity ?? 0;
    final showSos = sev >= 75;
    final scorePct = (score != null) ? ((score! * 100).toStringAsFixed(0)) : null;

    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_graph, size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Análisis de tu emoción',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (emotion != null && emotion!.isNotEmpty)
                            Chip(
                              label: Text(emotion!),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (severity != null)
                            Chip(
                              label: Text(
                                'Severidad $severity/100'
                                '${scorePct != null ? " • $scorePct%" : ""}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (severity != null && severity! > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ((severity!.clamp(0, 100)) / 100.0),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (advice != null && advice!.isNotEmpty)
                        Text(
                          advice!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (showSos) ...[
                            FilledButton.icon(
                              onPressed: () {
                                onClose();
                                if (onOpenSos != null) onOpenSos!();
                              },
                              icon: const Icon(Icons.sos),
                              label: const Text('Ver SOS'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          OutlinedButton(
                            onPressed: onClose,
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}