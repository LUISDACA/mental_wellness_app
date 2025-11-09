import 'package:flutter/material.dart';
import '../models/transport_mode.dart';
import '../utils/map_utils.dart';

class RouteInfoBanner extends StatelessWidget {
  final double meters;
  final double seconds;
  final TransportMode mode;
  final VoidCallback onClear;

  const RouteInfoBanner({
    super.key,
    required this.meters,
    required this.seconds,
    required this.mode,
    required this.onClear,
  });

  String _modeLabel(TransportMode m) =>
      m == TransportMode.walking ? 'Caminando' : 'Conduciendo';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mode == TransportMode.walking
                    ? Icons.directions_walk_rounded
                    : Icons.directions_car_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MapUtils.fmtMeters(meters),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${MapUtils.formatDuration(seconds)} (${_modeLabel(mode)})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Limpiar ruta',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}