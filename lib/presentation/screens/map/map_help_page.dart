import 'dart:convert';
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
  final Set<String> _filters = {..._allCats};

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

  // ---------- UI helpers MEJORADOS ----------

  // Iconos más modernos y distintivos
  IconData _iconFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'clinic':
        return Icons.medical_services_rounded;
      case 'doctors':
        return Icons.healing_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'psychiatrist':
        return Icons.self_improvement_rounded;
      case 'counselling':
        return Icons.forum_rounded;
      case 'mental_health':
        return Icons.favorite_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  // Colores personalizados para cada categoría
  Color _colorFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Colors.red.shade700;
      case 'clinic':
        return Colors.orange.shade700;
      case 'doctors':
        return Colors.blue.shade700;
      case 'pharmacy':
        return Colors.green.shade700;
      case 'psychology':
        return Colors.purple.shade700;
      case 'psychiatrist':
        return Colors.indigo.shade700;
      case 'counselling':
        return Colors.teal.shade700;
      case 'mental_health':
        return Colors.pink.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Color de fondo más claro para contraste
  Color _bgColorFor(String cat) {
    switch (cat) {
      case 'hospital':
        return Colors.red.shade50;
      case 'clinic':
        return Colors.orange.shade50;
      case 'doctors':
        return Colors.blue.shade50;
      case 'pharmacy':
        return Colors.green.shade50;
      case 'psychology':
        return Colors.purple.shade50;
      case 'psychiatrist':
        return Colors.indigo.shade50;
      case 'counselling':
        return Colors.teal.shade50;
      case 'mental_health':
        return Colors.pink.shade50;
      default:
        return Colors.grey.shade50;
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
                    Icon(Icons.directions_walk_rounded),
                    SizedBox(width: 6),
                    Text('Caminando')
                  ]),
                ),
                DropdownMenuItem(
                  value: TransportMode.driving,
                  child: Row(children: [
                    Icon(Icons.directions_car_rounded),
                    SizedBox(width: 6),
                    Text('Conduciendo')
                  ]),
                ),
              ],
              onChanged: (m) =>
                  setState(() => _mode = m ?? TransportMode.walking),
              icon: const Icon(Icons.route_rounded),
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
            icon: const Icon(Icons.radar_rounded),
          ),
          IconButton(
            tooltip: 'Rebuscar',
            onPressed: _search,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros con chips coloreados
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: _allCats.map((cat) {
                final selected = _filters.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      _iconFor(cat),
                      size: 18,
                      color: selected ? Colors.white : _colorFor(cat),
                    ),
                    label: Text(_labelFor(cat)),
                    selected: selected,
                    selectedColor: _colorFor(cat),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
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
                    // Marcadores MEJORADOS
                    MarkerLayer(
                      markers: [
                        // Marcador de mi ubicación mejorado
                        if (_center != null)
                          Marker(
                            point: _center!,
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Efecto de pulso
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(0.4),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
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
                        // Marcadores de lugares con diseño mejorado
                        for (final p in visiblePlaces)
                          Marker(
                            width: 56,
                            height: 56,
                            point: LatLng(p.lat, p.lon),
                            child: GestureDetector(
                              onTap: () => _showPlace(p),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pin con sombra
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _bgColorFor(p.category),
                                      border: Border.all(
                                        color: _colorFor(p.category),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _iconFor(p.category),
                                      size: 24,
                                      color: _colorFor(p.category),
                                    ),
                                  ),
                                  // Punta del pin
                                  Positioned(
                                    bottom: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _colorFor(p.category),
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
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _mode == TransportMode.walking
                                    ? Icons.directions_walk_rounded
                                    : Icons.directions_car_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(_routeMeters! / 1000).toStringAsFixed(2)} km',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    '${_formatDuration(_routeSeconds!)} (${_modeLabel(_mode)})',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Limpiar ruta',
                              onPressed: () {
                                setState(() {
                                  _routePoints = const [];
                                  _routeMeters = null;
                                  _routeSeconds = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
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
        icon: const Icon(Icons.my_location_rounded),
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
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bgColorFor(p.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(p.category),
                color: _colorFor(p.category),
                size: 28,
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              [
                _labelFor(p.category),
                if (distanceMeters != null) '• ${_fmtMeters(distanceMeters)}',
              ].join(' '),
            ),
          ),
          const Divider(),
          if (p.tags['phone'] != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.call_rounded, color: Colors.green.shade700),
              ),
              title: Text('${p.tags['phone']}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _launchUri(Uri(scheme: 'tel', path: '${p.tags['phone']}')),
            ),
          if (p.tags['website'] != null)
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
                '${p.tags['website']}',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _launchUri(Uri.parse('${p.tags['website']}')),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _fetchRouteTo(p);
                  },
                  icon: Icon(
                    _mode == TransportMode.walking
                        ? Icons.directions_walk_rounded
                        : Icons.directions_car_rounded,
                  ),
                  label: Text('Ruta (${_modeLabel(_mode)})'),
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
