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
          const SnackBar(content: Text('Foto de perfil actualizada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil guardado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildFullName(String a, String b) => '${a.trim()} ${b.trim()}'.trim();

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Supabase.instance.client.auth.currentUser;
    final avatarUrl = _svc.publicAvatarUrl(_profile?.avatarPath);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage:
                          (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null)
                          ? const Icon(Icons.person, size: 52)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: _pickAvatar,
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          tooltip: 'Cambiar foto',
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  u?.email ?? '',
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

              // Fecha de nacimiento + Género
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickBirthDate,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(
                        _birthDate == null
                            ? 'Fecha de nacimiento'
                            : DateFormat.yMMMd(locale).format(_birthDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'female', label: Text('Mujer')),
                        ButtonSegment(value: 'male', label: Text('Hombre')),
                        ButtonSegment(value: 'custom', label: Text('Otro')),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (s) =>
                          setState(() => _gender = s.first),
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            ],
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
