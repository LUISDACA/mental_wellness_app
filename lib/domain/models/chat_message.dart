class ChatMessage {
  final String id;
  final String role; // user|assistant
  final String content;
  final DateTime createdAt;

  ChatMessage({required this.id, required this.role, required this.content, required this.createdAt});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
