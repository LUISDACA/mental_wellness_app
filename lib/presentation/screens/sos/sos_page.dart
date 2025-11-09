// lib/presentation/screens/sos/sos_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/sos_repository.dart';
import 'widgets/contacts_list.dart';
import 'widgets/contact_form.dart';
import 'utils/avatar_uploader.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});
  @override
  State<SosPage> createState() => _Sos();
}

class _Sos extends State<SosPage> {
  final _repo = SosRepository();
  final _sb = Supabase.instance.client;

  bool _loading = false;
  List<Map<String, dynamic>> _contacts = [];
  final Set<String> _uploadingAvatars =
      {}; // Para rastrear qué avatares están cargando
  final Map<String, int> _imageTimestamps =
      {}; // Timestamps específicos por contacto

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.list();
      _contacts = List<Map<String, dynamic>>.from(list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando contactos: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _publicAvatarUrl(String? path, String contactId) {
    if (path == null || path.isEmpty) return null;

    // Limpiar el path si viene con el nombre del bucket
    String cleanPath = path;
    if (path.startsWith('sos_avatars/')) {
      cleanPath = path.substring('sos_avatars/'.length);
    }

    final baseUrl = _sb.storage.from('sos_avatars').getPublicUrl(cleanPath);

    // Solo agregar timestamp si existe uno específico para este contacto
    final timestamp = _imageTimestamps[contactId];
    if (timestamp != null) {
      return '$baseUrl?t=$timestamp';
    }
    return baseUrl;
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _repo.remove(id);
      _imageTimestamps.remove(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatarAndUpload(String id) async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (res == null) return;
    final file = res.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _uploadingAvatars.add(id));
    try {
      final contactIndex = _contacts.indexWhere((c) => c['id'] == id);
      if (contactIndex == -1) return;
      final contact = _contacts[contactIndex];
      final oldAvatarPath = contact['avatar_path'] as String?;
      final ext = file.extension ?? 'jpg';

      final pathToSave = await AvatarUploader.upload(
        sb: _sb,
        repo: _repo,
        contactId: id,
        oldAvatarPath: oldAvatarPath,
        bytes: bytes,
        extension: ext,
      );

      setState(() {
        _contacts[contactIndex] = {
          ..._contacts[contactIndex],
          'avatar_path': pathToSave,
        };
        _imageTimestamps[id] = DateTime.now().millisecondsSinceEpoch;
      });

      final newUrl = _publicAvatarUrl(pathToSave, id);
      if (newUrl != null && mounted) {
        await precacheImage(NetworkImage(newUrl), context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatars.remove(id));
    }
  }

  void _openForm({Map<String, dynamic>? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContactForm(
        contact: contact,
        onSave: (data) async {
          setState(() => _loading = true);
          try {
            if (contact == null) {
              await _repo.add(data);
            } else {
              await _repo.upsert(id: contact['id'], data: data);
            }
            await _load();
            if (!mounted) return;
            Navigator.pop(context);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de ayuda (SOS)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Stack(
        children: [
          if (_contacts.isEmpty && !_loading)
            Center(
              child: Text(
                'Aún no agregas contactos.\nToca "Agregar" para crear uno.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (_contacts.isNotEmpty)
            ContactsList(
              contacts: _contacts,
              avatarUrlFor: (path, id) => _publicAvatarUrl(path, id),
              isUploadingFor: (id) => _uploadingAvatars.contains(id),
              onChangeAvatar: _pickAvatarAndUpload,
              onEdit: (c) => _openForm(contact: c),
              onDelete: _delete,
            ),
          if (_loading)
            const Positioned.fill(
              child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator())),
            ),
        ],
      ),
    );
  }
}
