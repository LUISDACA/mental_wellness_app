// lib/presentation/screens/posts/posts_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers.dart';
import 'widgets/post_composer.dart';
import 'widgets/async_posts_list.dart';

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
          PostComposer(
            controller: _textCtrl,
            picked: _picked,
            onPickFile: _pickFile,
            onClearAttachment: () => setState(() => _picked = null),
            sending: _sending,
            onPublish: _publish,
          ),

          // Lista de posts
          Expanded(
            child: AsyncPostsList(postsAsync: postsAsync, userId: user?.id),
          ),
        ],
      ),
    );
  }
}
