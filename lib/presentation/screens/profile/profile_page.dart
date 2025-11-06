import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/profile_service.dart';
import '../../../domain/models/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _svc = ProfileService();
  Profile? _profile;
  bool _loading = false;

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  String _gender = 'female';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _svc.getOrCreateMyProfile();
      _profile = p;
      _firstCtrl.text = p.firstName ?? '';
      _lastCtrl.text = p.lastName ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _addrCtrl.text = p.address ?? '';
      _gender = p.gender ?? _gender;
      _birthDate = p.birthDate;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return;
    final file = res.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo')));
      return;
    }
    await _uploadAvatar(bytes, file.name);
  }

  Future<void> _uploadAvatar(Uint8List bytes, String name) async {
    setState(() => _loading = true);
    try {
      final path =
          await _svc.uploadAvatarBytes(bytes: bytes, originalName: name);
      final full = _buildFullName(_firstCtrl.text, _lastCtrl.text);
      final updated = await _svc.upsert(
        avatarPath: path,
        firstName:
            _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
        fullName: full.isEmpty ? null : full,
        gender: _gender,
        birthDate: _birthDate,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
      );
      setState(() => _profile = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada con éxito')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildFullName(String f, String l) {
    final ff = f.trim();
    final ll = l.trim();
    return [if (ff.isNotEmpty) ff, if (ll.isNotEmpty) ll].join(' ');
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final full = _buildFullName(_firstCtrl.text, _lastCtrl.text);
      final updated = await _svc.upsert(
        firstName:
            _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
        fullName: full.isEmpty ? null : full,
        gender: _gender,
        birthDate: _birthDate,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
      );
      setState(() => _profile = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _publicAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final avatarUrl = _publicAvatarUrl(_profile?.avatarPath);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: (avatarUrl != null)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null)
                            ? Icon(Icons.person,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _profile?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (_profile != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Actualizado: ${DateFormat.yMMMd(locale).add_Hm().format(_profile!.updatedAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Nombre / Apellido
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fecha de nacimiento
                OutlinedButton.icon(
                  onPressed: _pickBirthDate,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(
                    _birthDate == null
                        ? 'Fecha de nacimiento'
                        : DateFormat.yMMMd(locale).format(_birthDate!),
                  ),
                ),
                const SizedBox(height: 12),

                // Género - CORREGIDO: Ahora con mejor diseño
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'Género',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'female',
                          label: Text('Mujer'),
                          icon: Icon(Icons.female, size: 18),
                        ),
                        ButtonSegment(
                          value: 'male',
                          label: Text('Hombre'),
                          icon: Icon(Icons.male, size: 18),
                        ),
                        ButtonSegment(
                          value: 'custom',
                          label: Text('Otro'),
                          icon: Icon(Icons.person, size: 18),
                        ),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (s) =>
                          setState(() => _gender = s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Teléfono / Dirección
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
              ],
            ),
          ),
          // Botón de guardar flotante
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            ),
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
