import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/env.dart';
import '../../../../data/services/health_service.dart';

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
            // Cargando
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.self_improvement, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Preparando todo para ti…',
                      style: style.titleMedium,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              );
            }

            // Error raro en health check -> mostramos no disponible
            if (snapshot.hasError || !snapshot.hasData) {
              return _Unavailable(onRetry: _reload);
            }

            final r = snapshot.data!;

            // Supabase es crítico: requiere env configurado + ping ok.
            final supabaseConfigured =
                Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty;
            final supabaseOk = supabaseConfigured && r.supabaseOk;

            if (!supabaseOk) {
              return _Unavailable(onRetry: _reload);
            }

            // IA opcional: si aiOk == false, mostramos "listos" pero con nota suave.
            final aiLimited = !r.aiOk;

            return _Available(aiLimited: aiLimited);
          },
        ),
      ),
    );
  }
}

class _Available extends StatelessWidget {
  final bool aiLimited;
  const _Available({this.aiLimited = false});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;

    final subtitle = aiLimited
        ? 'Estamos listos para acompañarte. Algunas funciones de IA pueden estar limitadas, pero puedes analizar tus emociones con el modo básico, chatear y revisar tu historial.'
        : 'Estamos listos para acompañarte. Puedes analizar tu emoción, hablar con el chat empático y revisar tu historial cuando lo necesites.';

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
        Text(subtitle, style: style.bodyMedium),
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
