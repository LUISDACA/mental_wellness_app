import 'package:flutter/material.dart';
import '../utils/history_utils.dart';

class DangerBanner extends StatelessWidget {
  final Future<void> Function(String) onCall;
  final VoidCallback onOpenSos;
  final double avg;
  const DangerBanner({
    super.key,
    required this.onCall,
    required this.onOpenSos,
    required this.avg,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Señal de alerta 😟',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red)),
          const SizedBox(height: 6),
          Text(
              'Tu promedio de severidad es alto (${avg.toStringAsFixed(0)}/100). '
              'Si te sientes en riesgo, busca ayuda inmediata.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton.icon(
              onPressed: onOpenSos,
              icon: const Icon(Icons.health_and_safety),
              label: const Text('Abrir SOS'),
            ),
            OutlinedButton.icon(
              onPressed: () => onCall('911'),
              icon: const Icon(Icons.call),
              label: const Text('Llamar 911'),
            ),
            OutlinedButton.icon(
              onPressed: () => onCall('123'),
              icon: const Icon(Icons.call),
              label: const Text('Llamar 123'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class CongratsBanner extends StatelessWidget {
  final double avg;
  const CongratsBanner({super.key, required this.avg});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.07),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.green),
        title: const Text('¡Buen trabajo!'),
        subtitle: Text(
          'Tu promedio de severidad es bajo (${avg.toStringAsFixed(0)}/100). '
          'Sigue con tus hábitos: respiración, diario y contacto positivo.',
        ),
      ),
    );
  }
}

class DominantBanner extends StatelessWidget {
  final String dom; // happiness | sadness | anxiety | anger | neutral
  const DominantBanner({super.key, required this.dom});

  @override
  Widget build(BuildContext context) {
    const msgs = {
      'happiness':
          'Predomina la felicidad. Mantén tus hábitos que te hacen bien y compártelos con tu red cercana.',
      'sadness':
          'La tristeza ha sido frecuente. Escríbela o compártela con alguien de confianza; una caminata suave ayuda.',
      'anxiety':
          'La ansiedad aparece seguido. Prueba respiración 4-7-8 o la técnica 5-4-3-2-1 para anclarte al presente.',
      'anger':
          'El enojo ha sido recurrente. Pausa, respira profundo y toma algo de movimiento antes de responder.',
      'neutral':
          'Tu estado general es estable. Es normal sentirse neutral; si necesitas hablar, aquí estamos.',
    };

    final colors = {
      'happiness': Colors.green.withValues(alpha: 0.07),
      'sadness': Colors.blueGrey.withValues(alpha: 0.08),
      'anxiety': Colors.orange.withValues(alpha: 0.08),
      'anger': Colors.redAccent.withValues(alpha: 0.08),
      'neutral': Colors.blueGrey.withValues(alpha: 0.06),
    };

    final icons = {
      'happiness': Icons.emoji_emotions,
      'sadness': Icons.water_drop,
      'anxiety': Icons.self_improvement,
      'anger': Icons.flare,
      'neutral': Icons.self_improvement,
    };

    final key = msgs.containsKey(dom) ? dom : 'neutral';
    return Card(
      color: colors[key],
      child: ListTile(
        leading: Icon(icons[key]),
        title: Text('Emoción dominante: ${labelForEmotion(key)}'),
        subtitle: Text(msgs[key]!),
      ),
    );
  }
}