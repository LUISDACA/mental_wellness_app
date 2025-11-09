import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../domain/models/place.dart';
import '../utils/map_utils.dart';

class MapCanvas extends StatelessWidget {
  final MapController mapController;
  final LatLng center;
  final int radiusMeters;
  final List<LatLng> routePoints;
  final List<Place> places;
  final void Function(LatLng) onTap;
  final void Function(Place) onPlaceTap;

  const MapCanvas({
    super.key,
    required this.mapController,
    required this.center,
    required this.radiusMeters,
    required this.routePoints,
    required this.places,
    required this.onTap,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: ~InteractiveFlag.rotate,
        ),
        onTap: (tapPos, latLng) => onTap(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'mental_wellness_app',
        ),
        CircleLayer(circles: [
          CircleMarker(
            point: center,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            borderColor: Theme.of(context).colorScheme.primary,
            borderStrokeWidth: 2,
            radius: (radiusMeters / 2).toDouble(),
          ),
        ]),
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Marcador del centro/mi ubicación
            Marker(
              point: center,
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Marcadores de lugares
            for (final p in places)
              Marker(
                width: 56,
                height: 56,
                point: LatLng(p.lat, p.lon),
                child: GestureDetector(
                  onTap: () => onPlaceTap(p),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MapUtils.bgColorFor(p.category),
                          border: Border.all(
                            color: MapUtils.colorFor(p.category),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          MapUtils.iconFor(p.category),
                          size: 24,
                          color: MapUtils.colorFor(p.category),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: MapUtils.colorFor(p.category),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}