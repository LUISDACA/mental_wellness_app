class Post {
  final String id;
  final String userId;
  final String authorName;
  final String content;
  final String? mediaPath; // 'userId/uuid_filename.ext'
  final String? mediaType; // 'image' | 'pdf' | null
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.mediaPath,
    required this.mediaType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromMap(Map<String, dynamic> m) {
    return Post(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      authorName: (m['author_name'] as String?) ?? 'Usuario',
      content: (m['content'] as String?) ?? '',
      mediaPath: m['media_path'] as String?,
      mediaType: m['media_type'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  bool get hasImage => mediaType == 'image' && mediaPath != null;
  bool get hasPdf => mediaType == 'pdf' && mediaPath != null;
}
