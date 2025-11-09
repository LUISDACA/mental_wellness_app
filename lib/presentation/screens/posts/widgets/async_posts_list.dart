import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/post.dart';
import 'post_card.dart';

class AsyncPostsList extends StatelessWidget {
  final AsyncValue<List<Post>> postsAsync;
  final String? userId;

  const AsyncPostsList({
    super.key,
    required this.postsAsync,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('Aún no hay publicaciones'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: posts.length,
          itemBuilder: (_, i) => PostCard(
            post: posts[i],
            isOwner: userId == posts[i].userId,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}