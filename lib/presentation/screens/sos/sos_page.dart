// lib/presentation/screens/sos/sos_page.dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/sos_repository.dart';

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

    setState(() => _uploadingAvatars.add(id)); // Marcar como cargando
    try {
      final ext = file.extension ?? 'jpg';
      final fileName = '${id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Buscar el contacto actual
      final contactIndex = _contacts.indexWhere((c) => c['id'] == id);
      if (contactIndex == -1) return;

      final contact = _contacts[contactIndex];
      final oldAvatarPath = contact['avatar_path'];

      // Limpiar caché de la imagen anterior si existe
      if (oldAvatarPath != null) {
        final oldUrl = _publicAvatarUrl(oldAvatarPath, id);
        if (oldUrl != null) {
          PaintingBinding.instance.imageCache.evict(NetworkImage(oldUrl));
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
        // Intentar eliminar el archivo anterior en Supabase
        try {
          String cleanOldPath = oldAvatarPath;
          if (oldAvatarPath.startsWith('sos_avatars/')) {
            cleanOldPath = oldAvatarPath.substring('sos_avatars/'.length);
          }
          await _sb.storage.from('sos_avatars').remove([cleanOldPath]);
        } catch (e) {
          // ignore
        }
      }

      // Subir la nueva imagen
      final uploadPath = await _sb.storage.from('sos_avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      // El path devuelto puede incluir el bucket; guardamos solo el filename
      final pathToSave =
          uploadPath.contains('/') ? uploadPath.split('/').last : uploadPath;

      // Actualizar en la base de datos
      await _repo.upsert(id: id, data: {'avatar_path': pathToSave});

      // Actualizar solo este contacto en la lista local
      setState(() {
        _contacts[contactIndex] = {
          ..._contacts[contactIndex],
          'avatar_path': pathToSave,
        };
        // Establecer timestamp para forzar recarga solo de esta imagen
        _imageTimestamps[id] = DateTime.now().millisecondsSinceEpoch;
      });

      // Pre-cargar la nueva imagen
      final newUrl = _publicAvatarUrl(pathToSave, id);
      if (newUrl != null) {
        await precacheImage(NetworkImage(newUrl), context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
      builder: (_) => _ContactForm(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
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
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = _contacts[i];
                final avatarUrl = _publicAvatarUrl(c['avatar_path'], c['id']);
                final phone = (c['phone'] ?? '').toString().trim();
                final email = (c['email'] ?? '').toString().trim();
                final isUploadingAvatar = _uploadingAvatars.contains(c['id']);

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Avatar con indicador de carga
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  backgroundImage: (avatarUrl != null)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  onBackgroundImageError: (avatarUrl != null)
                                      ? (exception, stackTrace) {
                                          // ignore
                                        }
                                      : null,
                                  child: (avatarUrl == null)
                                      ? Icon(
                                          Icons.person,
                                          size: 28,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        )
                                      : null,
                                ),
                                // Indicador de carga sobre la foto
                                if (isUploadingAvatar)
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Botón de cámara posicionado (compacto)
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: isUploadingAvatar
                                        ? null
                                        : () => _pickAvatarAndUpload(c['id']),
                                    icon: const Icon(Icons.camera_alt),
                                    iconSize: 12,
                                    style: IconButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(24, 24),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    tooltip: 'Cambiar foto',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(c['label'] ?? 'Contacto'),
                        subtitle: Wrap(
                          spacing: 8,
                          runSpacing: -6,
                          children: [
                            if (phone.isNotEmpty)
                              Chip(
                                label: Text(phone),
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.phone, size: 16),
                              ),
                            if (email.isNotEmpty)
                              Chip(
                                label: Text(email),
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.email, size: 16),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'edit':
                                _openForm(contact: c);
                                break;
                              case 'delete':
                                _delete(c['id']);
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Editar')),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete),
                                  title: Text('Eliminar')),
                            ),
                          ],
                        ),
                        isThreeLine: phone.isNotEmpty || email.isNotEmpty,
                        subtitleTextStyle:
                            Theme.of(context).textTheme.bodySmall,
                        onTap: phone.isNotEmpty
                            ? () => launchUrl(Uri.parse('tel:$phone'))
                            : null,
                      ),
                      // Acciones rápidas
                      if (phone.isNotEmpty || email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              if (phone.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () =>
                                      launchUrl(Uri.parse('tel:$phone')),
                                  icon: const Icon(Icons.call, size: 18),
                                  label: const Text('Llamar'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              if (phone.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () =>
                                      launchUrl(Uri.parse('sms:$phone')),
                                  icon: const Icon(Icons.sms, size: 18),
                                  label: const Text('SMS'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              if (phone.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    final digits =
                                        phone.replaceAll(RegExp(r'[^\d+]'), '');
                                    final wa =
                                        Uri.parse('https://wa.me/$digits');
                                    launchUrl(wa,
                                        mode: LaunchMode.externalApplication);
                                  },
                                  icon: const FaIcon(FontAwesomeIcons.whatsapp,
                                      size: 18),
                                  label: const Text('WhatsApp'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              if (email.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () =>
                                      launchUrl(Uri.parse('mailto:$email')),
                                  icon: const Icon(Icons.email, size: 18),
                                  label: const Text('Email'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
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

class _ContactForm extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final Future<void> Function(Map<String, String>) onSave;
  const _ContactForm({this.contact, required this.onSave});

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _labelCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _labelCtrl.text = widget.contact!['label'] ?? '';
      _phoneCtrl.text = widget.contact!['phone'] ?? '';
      _emailCtrl.text = widget.contact!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _labelCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave({'label': label, 'phone': phone, 'email': email});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.contact == null ? 'Nuevo contacto' : 'Editar contacto',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
