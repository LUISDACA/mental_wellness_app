// lib/presentation/screens/sos/sos_page.dart
import 'dart:typed_data';
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

  // ------- CARGA -------
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

  // ------- HELPERS -------
  Uri _telUri(String raw) {
    final p = raw.trim();
    return Uri.parse(p.startsWith('tel:') ? p : 'tel:$p');
  }

  Uri _smsUri(String raw) {
    final p = raw.trim();
    return Uri.parse(p.startsWith('sms:') ? p : 'sms:$p');
  }

  Uri _waUri(String raw, {String? text}) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    final query = (text == null || text.isEmpty)
        ? ''
        : '?text=${Uri.encodeComponent(text)}';
    return Uri.parse('https://wa.me/$digits$query');
  }

  String? _publicAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    // Supabase SDK v2: getPublicUrl devuelve String directo
    return _sb.storage.from('sos_avatars').getPublicUrl(path);
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
              child: const Text('Cancelar')),
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

  // ------- AVATAR -------
  Future<void> _pickAvatarAndUpload(String contactId) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return;
    final file = res.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo.')),
      );
      return;
    }

    // subimos a bucket sos_avatars
    setState(() => _loading = true);
    try {
      final uid = _sb.auth.currentUser?.id ?? 'anon';
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final path =
          'u_$uid/$contactId-${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _sb.storage.from('sos_avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$ext',
            ),
          );

      // guardamos path en la fila del contacto
      await _sb
          .from('sos_contacts')
          .update({'avatar_path': path}).eq('id', contactId);

      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------- ADD / EDIT -------
  Future<void> _openForm({Map<String, dynamic>? contact}) async {
    final isEdit = contact != null;
    final labelCtrl = TextEditingController(text: contact?['label'] ?? '');
    final phoneCtrl = TextEditingController(text: contact?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: contact?['email'] ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, viewInsets + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Editar contacto' : 'Nuevo contacto',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre / etiqueta',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  helperText: 'Ej: +57 3001234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final label = labelCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final email = emailCtrl.text.trim();

                      if (label.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Pon un nombre/etiqueta')),
                        );
                        return;
                      }

                      try {
                        if (isEdit) {
                          await _sb.from('sos_contacts').update({
                            'label': label,
                            'phone': phone,
                            'email': email
                          }).eq('id', contact['id']);
                        } else {
                          await _repo.add(
                              label: label, phone: phone, email: email);
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo guardar: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await _load();
    }
  }

  // ------- UI -------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos de ayuda (SOS)'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                'Aún no agregas contactos.\nToca “Agregar” para crear uno.',
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
                final avatarUrl = _publicAvatarUrl(c['avatar_path']);
                final phone = (c['phone'] ?? '').toString().trim();
                final email = (c['email'] ?? '').toString().trim();

                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: (avatarUrl != null)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null)
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        Positioned(
                          bottom: -4,
                          right: -6,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _pickAvatarAndUpload(c['id']),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            tooltip: 'Cambiar foto',
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
                                title: Text('Editar'))),
                        PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Eliminar'))),
                      ],
                    ),
                    isThreeLine: phone.isNotEmpty || email.isNotEmpty,
                    // Acciones rápidas bajo el tile
                    subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                    onTap: phone.isNotEmpty
                        ? () => launchUrl(_telUri(phone))
                        : null,
                  ),
                ).buildActionRow(context, phone: phone, email: email);
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

/// Extension para añadir una fila de acciones debajo de cada Card de contacto.
extension _CardActions on Card {
  Widget buildActionRow(BuildContext context,
      {required String phone, required String email}) {
    // Limpia el número para wa.me
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final wa = Uri.parse('https://wa.me/$cleaned');

    return Column(
      children: [
        this,
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (phone.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call),
                  label: const Text('Llamar'),
                ),
              if (phone.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('sms:$phone')),
                  icon: const Icon(Icons.sms),
                  label: const Text('SMS'),
                ),
              if (phone.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(
                    wa,
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                  label: const Text('WhatsApp'),
                ),
              if (email.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:$email')),
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
