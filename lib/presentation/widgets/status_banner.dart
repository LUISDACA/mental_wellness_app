import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/env.dart';
import '../../data/services/health_service.dart';

class StatusBanner extends StatefulWidget {
  const StatusBanner({super.key});
  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  Future<HealthCheckResult>? _future;

  @override
  void initState() {
    super.initState();
    _future = HealthService().run();
  }

  void _reload() {
    setState(() => _future = HealthService().run());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<HealthCheckResult>(
          future: _future,
          builder: (context, snapshot) {
            // Estado: cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.self_improvement, size: 28),
                    const SizedBox(width: 12),
                    Text('Preparando todo para ti…', style: style.titleMedium),
                  ]),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              );
            }

            // Si hubo error al chequear, tratamos como "no disponible"
            if (snapshot.hasError || !snapshot.hasData) {
              return _Unavailable(onRetry: _reload);
            }

            // Resultado del health check (sin mostrar detalles técnicos)
            final r = snapshot.data!;
            final hasEnvSupabase = Env.supabaseUrl.isNotEmpty;
            final hasEnvGemini = Env.geminiApiKey.isNotEmpty;
            final allOk =
                hasEnvSupabase && hasEnvGemini && r.supabaseOk && r.geminiOk;

            return allOk ? const _Available() : _Unavailable(onRetry: _reload);
          },
        ),
      ),
    );
  }
}

class _Available extends StatelessWidget {
  const _Available();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.self_improvement, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estamos listos para ti 💜',
              style: style.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Cuando lo necesites, te acompañamos. Puedes analizar tu emoción, hablar con el chat o revisar tu historial. ¿Por dónde empezamos?',
          style: style.bodyMedium,
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  final VoidCallback onRetry;
  const _Unavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.health_and_safety_outlined, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ahora mismo no estamos disponibles como quisiéramos',
              style: style.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Si te sientes muy mal, llama a emergencias (123 o 911) o habla con tus contactos de confianza.',
          style: style.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.go('/sos'),
              icon: const Icon(Icons.sos),
              label: const Text('Abrir SOS'),
            ),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ],
    );
  }
}
