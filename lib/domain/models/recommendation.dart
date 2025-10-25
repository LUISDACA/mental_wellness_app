class Recommendation {
  final String id;
  final String emotion;
  final String title;
  final String kind; // breath|meditation|music|journal
  final Map<String, dynamic>? payload;
  final bool active;

  Recommendation({required this.id, required this.emotion, required this.title, required this.kind, this.payload, required this.active});

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'] as String,
        emotion: json['emotion'] as String,
        title: json['title'] as String,
        kind: json['kind'] as String,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'emotion': emotion,
        'title': title,
        'kind': kind,
        'payload': payload,
        'active': active,
      };
}
