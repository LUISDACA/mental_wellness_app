import 'package:flutter/material.dart';
import '../../../../domain/models/place.dart';
import '../models/transport_mode.dart';
import '../utils/map_utils.dart';

Future<void> showPlaceSheet({
  required BuildContext context,
  required Place place,
  required TransportMode mode,
  double? distanceMeters,
  required Future<void> Function() onRoute,
  required Future<void> Function() onOpenMaps,
  Future<void> Function()? onCall,
  Future<void> Function()? onVisitWebsite,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MapUtils.bgColorFor(place.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              MapUtils.iconFor(place.category),
              color: MapUtils.colorFor(place.category),
              size: 28,
            ),
          ),
          title: Text(
            place.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text([
            MapUtils.labelFor(place.category),
            if (distanceMeters != null) '• ${MapUtils.fmtMeters(distanceMeters)}',
          ].join(' ')),
        ),
        const Divider(),
        if (place.tags['phone'] != null)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.call_rounded, color: Colors.green.shade700),
            ),
            title: Text('${place.tags['phone']}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              if (onCall != null) {
                await onCall();
              }
            },
          ),
        if (place.tags['website'] != null)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.public_rounded, color: Colors.blue.shade700),
            ),
            title: const Text('Sitio web'),
            subtitle: Text(
              '${place.tags['website']}',
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              if (onVisitWebsite != null) {
                await onVisitWebsite();
              }
            },
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onRoute();
                },
                icon: Icon(
                  mode == TransportMode.walking
                      ? Icons.directions_walk_rounded
                      : Icons.directions_car_rounded,
                ),
                label: Text('Ruta (${mode == TransportMode.walking ? 'Caminando' : 'Conduciendo'})'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onOpenMaps();
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text('Google Maps'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
}