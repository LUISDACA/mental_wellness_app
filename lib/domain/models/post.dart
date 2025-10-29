class Post {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarPath; // <- NUEVO
  final String content;
  final String? mediaPath;
  final String? mediaType; // 'image' | 'pdf' | null
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorAvatarPath,
    required this.content,
    required this.mediaPath,
    required this.mediaType,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> m) => Post(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        authorName: (m['author_name'] as String?) ?? 'Usuario',
        authorAvatarPath: m['author_avatar_path'] as String?, // <- NUEVO
        content: m['content'] as String,
        mediaPath: m['media_path'] as String?,
        mediaType: m['media_type'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  bool get isImage => mediaType == 'image';
  bool get isPdf => mediaType == 'pdf';

  String get authorInitial =>
      authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U';
}
