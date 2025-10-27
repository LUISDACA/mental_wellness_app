import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/place.dart';

class PlacesService {
  // Varias instancias públicas de Overpass con CORS. Usamos fallback.
  static const _endpoints = <String>[
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
  ];

  /// Busca lugares de ayuda cerca de [lat],[lon] en [radiusMeters].
  Future<List<Place>> searchNearby({
    required double lat,
    required double lon,
    int radiusMeters = 2000,
    int limit = 80,
  }) async {
    // Nodos y centros de vías/relaciones. Filtramos por amenities y etiquetas healthcare relevantes.
    final query = '''
[out:json][timeout:25];
(
  node(around:$radiusMeters,$lat,$lon)[amenity~"^(hospital|clinic|doctors|pharmacy)\$"];
  node(around:$radiusMeters,$lat,$lon)[healthcare~"(psycholog|psychiatr|counsell|mental)"];
  way(around:$radiusMeters,$lat,$lon)[amenity~"^(hospital|clinic|doctors|pharmacy)\$"];
  way(around:$radiusMeters,$lat,$lon)[healthcare~"(psycholog|psychiatr|counsell|mental)"];
  relation(around:$radiusMeters,$lat,$lon)[amenity~"^(hospital|clinic|doctors|pharmacy)\$"];
  relation(around:$radiusMeters,$lat,$lon)[healthcare~"(psycholog|psychiatr|counsell|mental)"];
);
out center $limit;
''';

    dynamic lastErr;
    for (final url in _endpoints) {
      try {
        final res = await http.post(Uri.parse(url),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query}).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final elements = (json['elements'] as List?) ?? const [];
          final places = elements
              .whereType<Map<String, dynamic>>()
              .map((e) => Place.fromOverpass(e))
              .where((p) => p.lat != 0 && p.lon != 0)
              .toList();
          return places;
        } else {
          lastErr = 'HTTP ${res.statusCode}';
        }
      } catch (e) {
        lastErr = e;
      }
    }
    throw StateError('Overpass error: $lastErr');
  }
}
