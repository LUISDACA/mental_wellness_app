import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

import '../../providers.dart';
import '../../../domain/models/place.dart';
import 'models/transport_mode.dart';
import 'widgets/transport_selector.dart';
import 'widgets/radius_menu.dart';
import 'widgets/filters_bar.dart';
import 'widgets/map_canvas.dart';
import 'widgets/route_info_banner.dart';
import 'widgets/place_sheet.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// TransportMode movido a models/transport_mode.dart

class MapHelpPage extends ConsumerStatefulWidget {
  const MapHelpPage({super.key});

  @override
  ConsumerState<MapHelpPage> createState() => _MapHelpPageState();
}

class _MapHelpPageState extends ConsumerState<MapHelpPage> {
  LatLng? _center;
  int _radius = AppConstants.defaultSearchRadiusMetersInt; // metros
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
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ---------- UI helpers ----------

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
          '${AppConstants.osrmRouteBase}/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson';
      final res =
          await http.get(Uri.parse(url)).timeout(AppConstants.networkTimeout);
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
      if (!mounted) {
        setState(() => _loading = false);
      }
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
          TransportSelector(
            mode: _mode,
            onChanged: (m) =>
                setState(() => _mode = m ?? TransportMode.walking),
          ),
          RadiusMenu(
            value: _radius,
            onSelected: (v) async {
              setState(() => _radius = v);
              await _search();
            },
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
          FiltersBar(
            allCategories: _allCats,
            selected: _filters,
            onAdd: (cat) => setState(() => _filters.add(cat)),
            onRemove: (cat) => setState(() => _filters.remove(cat)),
          ),
          Expanded(
            child: Stack(
              children: [
                MapCanvas(
                  mapController: _mapController,
                  center: center,
                  radiusMeters: _radius,
                  routePoints: _routePoints,
                  places: visiblePlaces,
                  onTap: (latLng) async {
                    setState(() {
                      _center = latLng;
                      _routePoints = const [];
                      _routeMeters = null;
                      _routeSeconds = null;
                    });
                    _mapController.move(latLng, 14);
                    await _search();
                  },
                  onPlaceTap: (p) async {
                    final c = _center;
                    final distanceMeters = (c == null)
                        ? null
                        : _haversine(c, LatLng(p.lat, p.lon));
                    await showPlaceSheet(
                      context: context,
                      place: p,
                      mode: _mode,
                      distanceMeters: distanceMeters,
                      onRoute: () async {
                        await _fetchRouteTo(p);
                      },
                      onOpenMaps: () async {
                        final cc = _center;
                        if (cc != null) {
                          await _openInGoogleMaps(
                            originLat: cc.latitude,
                            originLon: cc.longitude,
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
                      onCall: p.tags['phone'] != null
                          ? () async {
                              await _launchUri(
                                  Uri(scheme: 'tel', path: '${p.tags['phone']}'));
                            }
                          : null,
                      onVisitWebsite: p.tags['website'] != null
                          ? () async {
                              await _launchUri(Uri.parse('${p.tags['website']}'));
                            }
                          : null,
                    );
                  },
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
                    child: RouteInfoBanner(
                      meters: _routeMeters!,
                      seconds: _routeSeconds!,
                      mode: _mode,
                      onClear: () {
                        setState(() {
                          _routePoints = const [];
                          _routeMeters = null;
                          _routeSeconds = null;
                        });
                      },
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
  // --- util ---
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
