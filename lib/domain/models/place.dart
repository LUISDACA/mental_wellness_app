class Place {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final Map<String, dynamic> tags;
  final String
      category; // hospital|clinic|doctors|pharmacy|psychology|psychiatrist|counselling|mental_health|other

  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.tags,
    required this.category,
  });

  factory Place.fromOverpass(Map<String, dynamic> e) {
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (tags['name'] as String?) ??
        (tags['alt_name'] as String?) ??
        'Centro de atención';
    final amenity = (tags['amenity'] as String?) ?? '';
    final healthcare = (tags['healthcare'] as String?) ?? '';
    final cat = _inferCategory(amenity, healthcare);
    final lat = (e['lat'] as num?)?.toDouble() ??
        (e['center'] != null ? (e['center']['lat'] as num).toDouble() : 0);
    final lon = (e['lon'] as num?)?.toDouble() ??
        (e['center'] != null ? (e['center']['lon'] as num).toDouble() : 0);

    return Place(
      id: '${e['type']}:${e['id']}',
      name: name,
      lat: lat,
      lon: lon,
      tags: tags,
      category: cat,
    );
  }

  static String _inferCategory(String amenity, String healthcare) {
    if (healthcare.contains('psycholog')) return 'psychology';
    if (healthcare.contains('psychiatr')) return 'psychiatrist';
    if (healthcare.contains('counsell') || healthcare.contains('counselling')) {
      return 'counselling';
    }
    if (healthcare.contains('mental')) return 'mental_health';
    if (amenity == 'hospital') return 'hospital';
    if (amenity == 'clinic') return 'clinic';
    if (amenity == 'doctors') return 'doctors';
    if (amenity == 'pharmacy') return 'pharmacy';
    return 'other';
  }
}
