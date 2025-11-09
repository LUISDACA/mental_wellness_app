import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/post.dart';
import '../../../providers.dart';

class PostCard extends ConsumerWidget {
  final Post post;
  final bool isOwner;

  const PostCard({super.key, required this.post, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(postServiceProvider);
    final mediaUrl = svc.publicUrlFor(post);
    final avatarUrl = svc.authorAvatarUrlFor(post);
    final locale = Localizations.localeOf(context).toString();
    final localDate = post.createdAt.toLocal();
    final dateStr = DateFormat.yMMMd(locale).add_Hm().format(localDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null) ? Text(post.authorInitial) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final newText = await _askEdit(context, post.content);
                        if (newText != null && newText.trim().isNotEmpty) {
                          await ref.read(postServiceProvider).updatePost(
                                postId: post.id,
                                newText: newText.trim(),
                              );
                        }
                      } else if (v == 'delete') {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await ref.read(postServiceProvider).deletePost(post);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Text(post.content),

            if (post.isImage && mediaUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Text('No se pudo cargar la imagen'),
                ),
              ),
            ],
            if (post.isPdf && mediaUrl != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () =>
                    launchUrl(Uri.parse(mediaUrl), webOnlyWindowName: '_blank'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Abrir PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _askEdit(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar publicación'),
        content: TextField(
          controller: ctrl,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Escribe el texto…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Guardar')),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    return r == true;
  }
}