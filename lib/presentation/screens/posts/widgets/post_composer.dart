import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PostComposer extends StatelessWidget {
  final TextEditingController controller;
  final PlatformFile? picked;
  final VoidCallback onPickFile;
  final VoidCallback onClearAttachment;
  final bool sending;
  final VoidCallback onPublish;

  const PostComposer({
    super.key,
    required this.controller,
    required this.picked,
    required this.onPickFile,
    required this.onClearAttachment,
    required this.sending,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
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
                  onPressed: onPickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar (opcional)'),
                ),
                const SizedBox(width: 8),
                if (picked != null)
                  Expanded(
                    child: Chip(
                      label: Text(
                        picked!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: onClearAttachment,
                    ),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: sending ? null : onPublish,
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}