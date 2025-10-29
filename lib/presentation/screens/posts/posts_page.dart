// lib/presentation/screens/posts/posts_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/post.dart';
import '../../providers.dart';

class PostsPage extends ConsumerStatefulWidget {
  const PostsPage({super.key});

  @override
  ConsumerState<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<PostsPage> {
  final _textCtrl = TextEditingController();
  PlatformFile? _picked;
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true, // 👈 importante para web/móvil
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _picked = res.files.first);
    }
  }

  Future<void> _publish() async {
    final text = _textCtrl.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El texto es obligatorio')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(postServiceProvider).createPost(
            text: text,
            file: _picked,
          );
      ref.invalidate(postsStreamProvider);

      setState(() {
        _textCtrl.clear();
        _picked = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsStreamProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicaciones')),
      body: Column(
        children: [
          // Composer
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _textCtrl,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText:
                          'Comparte algo que pueda ayudar (texto obligatorio)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Adjuntar (opcional)'),
                      ),
                      const SizedBox(width: 8),
                      if (_picked != null)
                        Expanded(
                          child: Chip(
                            label: Text(_picked!.name,
                                overflow: TextOverflow.ellipsis),
                            onDeleted: () => setState(() => _picked = null),
                          ),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _sending ? null : _publish,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('Publicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lista de posts
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(child: Text('Aún no hay publicaciones'));
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: posts.length,
                  itemBuilder: (_, i) => _PostCard(
                    post: posts[i],
                    isOwner: user?.id == posts[i].userId,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Post post;
  final bool isOwner;
  const _PostCard({required this.post, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(postServiceProvider);
    final mediaUrl = svc.publicUrlFor(post);
    final avatarUrl = svc.authorAvatarUrlFor(post); // <- URL avatar autor
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
            // encabezado
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
                      Text(post.authorName,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(dateStr,
                          style: Theme.of(context).textTheme.bodySmall),
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

            // contenido
            Text(post.content),

            // media
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
