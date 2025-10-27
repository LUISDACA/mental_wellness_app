import 'dart:convert'; // 👈 necesario para jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../providers.dart';
import '../../../domain/models/place.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

enum TransportMode { walking, driving }

class MapHelpPage extends ConsumerStatefulWidget {
  const MapHelpPage({super.key});

  @override
  ConsumerState<MapHelpPage> createState() => _MapHelpPageState();
}

class _MapHelpPageState extends ConsumerState<MapHelpPage> {
  LatLng? _center;
  int _radius = 2000; // metros
  bool _loading = false;
  List<Place> _places = const [];

  final _mapController = MapController();
  final _haversine = const Distance();

  // Filtros
  static const Set<String> _allCats = {
    'psychology',
    'psychiatrist',
    'counselling',
    'mental_health',
    'hospital',
    'clinic',
    'doctors',
    'pharmacy',
    'other',
  };
  Set<String> _filters = {..._allCats};

  // Ruta
  TransportMode _mode = TransportMode.walking;
  List<LatLng> _routePoints = const [];
  double? _routeMeters;
  double? _routeSeconds;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ---------- Ubicación & búsqueda ----------
  Future<void> _initLocation() async {
    final ctx = context;
    setState(() => _loading = true);
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) {
        // Fallback: centro de Madrid
        _center = const LatLng(40.4168, -3.7038);
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _center = LatLng(pos.latitude, pos.longitude);
      }
      if (!ctx.mounted) return;
      await _search();
      if (_center != null) {
        _mapController.move(_center!, 14);
      }
    } catch (_) {
      if (!ctx.mounted) return;
      _center ??= const LatLng(40.4168, -3.7038);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu ubicación')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _search() async {
    if (_center == null) return;
    setState(() => _loading = true);
    try {
      // limpiar ruta al re-buscar
      _routePoints = const [];
      _routeMeters = null;
      _routeSeconds = null;

      final svc = ref.read(placesServiceProvider);
      final places = await svc.searchNearby(
        lat: _center!.latitude,
        lon: _center!.longitude,
        radiusMeters: _radius,
      );
      if (!mounted) return;
      setState(() => _places = places);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error buscando centros: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ---------- UI helpers ----------
  IconData _iconFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Icons.local_hospital;
      case 'clinic':
        return Icons.local_hospital_outlined;
      case 'doctors':
        return Icons.medical_services_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'psychology':
        return Icons.psychology_alt_outlined;
      case 'psychiatrist':
        return Icons.psychology;
      case 'counselling':
      case 'mental_health':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.place;
    }
  }

  String _labelFor(String cat) {
    switch (cat) {
      case 'psychology':
        return 'Psicología';
      case 'psychiatrist':
        return 'Psiquiatría';
      case 'counselling':
        return 'Consejería';
      case 'mental_health':
        return 'Salud mental';
      case 'hospital':
        return 'Hospital';
      case 'clinic':
        return 'Clínica';
      case 'doctors':
        return 'Consultorios';
      case 'pharmacy':
        return 'Farmacia';
      default:
        return 'Otros';
    }
  }

  String _modeLabel(TransportMode m) =>
      m == TransportMode.walking ? 'Caminando' : 'Conduciendo';

  // ---------- Rutas ----------
  Future<void> _fetchRouteTo(Place p) async {
    if (_center == null) return;
    final from = _center!;
    final to = LatLng(p.lat, p.lon);

    setState(() {
      _loading = true;
      _routePoints = const [];
      _routeMeters = null;
      _routeSeconds = null;
    });

    try {
      final profile = _mode == TransportMode.walking ? 'walking' : 'driving';
      // OSRM demo server (sin API key). Devuelve GeoJSON.
      final url =
          'https://router.project-osrm.org/route/v1/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson';
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw Exception('OSRM ${res.statusCode}');
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = map['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('Sin rutas');
      }

      final r0 = routes.first as Map<String, dynamic>;
      _routeMeters = (r0['distance'] as num?)?.toDouble();
      _routeSeconds = (r0['duration'] as num?)?.toDouble();

      final geom = r0['geometry'] as Map<String, dynamic>;
      final coords = (geom['coordinates'] as List)
          .cast<List>()
          .map((ll) =>
              LatLng((ll[1] as num).toDouble(), (ll[0] as num).toDouble()))
          .toList();

      setState(() => _routePoints = coords);

      // centra el mapa en la ruta
      if (coords.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(coords);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible calcular la ruta: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ---------- Google Maps ----------
  Future<void> _openInGoogleMaps({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
    required String label,
  }) async {
    final mode = _mode == TransportMode.walking ? 'walking' : 'driving';

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$originLat,$originLon'
      '&destination=$destLat,$destLon'
      '&travelmode=$mode'
      '&destination_place_id='
      '&dir_action=navigate',
    );

    if (kIsWeb) {
      await launchUrl(url, webOnlyWindowName: '_blank');
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final geo =
          Uri.parse('geo:$destLat,$destLon?q=${Uri.encodeComponent(label)}');
      if (await canLaunchUrl(geo)) {
        final ok = await launchUrl(geo, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final gm = Uri.parse(
        'comgooglemaps://?saddr=$originLat,$originLon&daddr=$destLat,$destLon&directionsmode=$mode',
      );
      if (await canLaunchUrl(gm)) {
        final ok = await launchUrl(gm, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    await launchUrl(url, mode: LaunchMode.platformDefault);
  }

  // ---------- UI principal ----------
  @override
  Widget build(BuildContext context) {
    final center = _center ?? const LatLng(40.4168, -3.7038);

    // Lista filtrada
    final visiblePlaces =
        _places.where((p) => _filters.contains(p.category)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centros de ayuda cercanos'),
        actions: [
          // modo
          DropdownButtonHideUnderline(
            child: DropdownButton<TransportMode>(
              value: _mode,
              items: const [
                DropdownMenuItem(
                  value: TransportMode.walking,
                  child: Row(children: [
                    Icon(Icons.directions_walk),
                    SizedBox(width: 6),
                    Text('Caminando')
                  ]),
                ),
                DropdownMenuItem(
                  value: TransportMode.driving,
                  child: Row(children: [
                    Icon(Icons.directions_car),
                    SizedBox(width: 6),
                    Text('Conduciendo')
                  ]),
                ),
              ],
              onChanged: (m) =>
                  setState(() => _mode = m ?? TransportMode.walking),
              icon: const Icon(Icons.directions),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Radio de búsqueda',
            onSelected: (v) async {
              setState(() => _radius = v);
              await _search();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 1000, child: Text('1 km')),
              PopupMenuItem(value: 2000, child: Text('2 km')),
              PopupMenuItem(value: 5000, child: Text('5 km')),
              PopupMenuItem(value: 10000, child: Text('10 km')),
            ],
            icon: const Icon(Icons.radar),
          ),
          IconButton(
            tooltip: 'Rebuscar',
            onPressed: _search,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: _allCats.map((cat) {
                final selected = _filters.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_labelFor(cat)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _filters.add(cat);
                        } else {
                          _filters.remove(cat);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
                    ),
                    onTap: (tapPos, latLng) async {
                      setState(() {
                        _center = latLng;
                        // limpiar ruta si el usuario cambia el centro
                        _routePoints = const [];
                        _routeMeters = null;
                        _routeSeconds = null;
                      });
                      _mapController.move(latLng, 14);
                      await _search();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'mental_wellness_app',
                    ),
                    if (_center != null)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: _center!,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          borderColor: Theme.of(context).colorScheme.primary,
                          borderStrokeWidth: 2,
                          radius: (_radius / 2).toDouble(),
                        ),
                      ]),
                    // Polyline de la ruta
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    // Marcadores
                    MarkerLayer(
                      markers: [
                        if (_center != null)
                          Marker(
                            point: _center!,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.my_location, size: 28),
                          ),
                        for (final p in visiblePlaces)
                          Marker(
                            width: 44,
                            height: 44,
                            point: LatLng(p.lat, p.lon),
                            child: GestureDetector(
                              onTap: () => _showPlace(p),
                              child: Icon(_iconFor(p.category), size: 34),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_loading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Banner con distancia/tiempo de la ruta
                if (_routeMeters != null && _routeSeconds != null)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              _mode == TransportMode.walking
                                  ? Icons.directions_walk
                                  : Icons.directions_car,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_routeMeters! / 1000).toStringAsFixed(2)} km • '
                              '${_formatDuration(_routeSeconds!)} (${_modeLabel(_mode)})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Limpiar ruta',
                              onPressed: () {
                                setState(() {
                                  _routePoints = const [];
                                  _routeMeters = null;
                                  _routeSeconds = null;
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.my_location),
        label: const Text('Mi ubicación'),
        onPressed: _initLocation,
      ),
    );
  }

  Future<void> _showPlace(Place p) async {
    if (!mounted) return;
    final center = _center;
    final distanceMeters =
        (center == null) ? null : _haversine(center, LatLng(p.lat, p.lon));
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(_iconFor(p.category)),
            title: Text(p.name),
            subtitle: Text(
              [
                _labelFor(p.category),
                if (distanceMeters != null) '• ${_fmtMeters(distanceMeters)}',
              ].join(' '),
            ),
          ),
          if (p.tags['phone'] != null)
            ListTile(
              leading: const Icon(Icons.call),
              title: Text('${p.tags['phone']}'),
              onTap: () =>
                  _launchUri(Uri(scheme: 'tel', path: '${p.tags['phone']}')),
            ),
          if (p.tags['website'] != null)
            ListTile(
              leading: const Icon(Icons.public),
              title: Text('${p.tags['website']}'),
              onTap: () => _launchUri(Uri.parse('${p.tags['website']}')),
            ),
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: Text('Ruta (${_modeLabel(_mode)})'),
            onTap: () async {
              Navigator.of(context).pop();
              await _fetchRouteTo(p);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Abrir en Google Maps'),
            onTap: () async {
              Navigator.of(context).pop();
              final c = _center;
              if (c != null) {
                await _openInGoogleMaps(
                  originLat: c.latitude,
                  originLon: c.longitude,
                  destLat: p.lat,
                  destLon: p.lon,
                  label: p.name,
                );
              } else {
                final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lon}(${Uri.encodeComponent(p.name)})');
                await _launchUri(url);
              }
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // --- util ---
  String _fmtMeters(double m) {
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(2)} km';
  }

  String _formatDuration(double secs) {
    final m = (secs / 60).round();
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final mm = m % 60;
    if (mm == 0) return '$h h';
    return '$h h $mm min';
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      if (kIsWeb) {
        await launchUrl(uri, webOnlyWindowName: '_blank');
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // ignore
    }
  }
}
