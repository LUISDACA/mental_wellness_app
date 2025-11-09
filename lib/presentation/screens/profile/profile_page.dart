import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/profile_service.dart';
import '../../../domain/models/profile.dart';
import 'widgets/profile_header.dart';
import 'widgets/name_fields.dart';
import 'widgets/birth_field.dart';
import 'widgets/contact_fields.dart';
import 'widgets/save_bar.dart';
import 'widgets/loading_overlay.dart';
import 'widgets/gender_selector.dart';

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
      if (!mounted) return;
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
    final avatarUrl = _publicAvatarUrl(_profile?.avatarPath);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                ProfileHeader(
                  avatarUrl: avatarUrl,
                  email: _profile?.email,
                  updatedAt: _profile?.updatedAt,
                  onPickAvatar: _pickAvatar,
                ),
                const SizedBox(height: 16),
                NameFields(
                  firstController: _firstCtrl,
                  lastController: _lastCtrl,
                ),
                const SizedBox(height: 12),
                BirthField(
                  birthDate: _birthDate,
                  onPick: _pickBirthDate,
                ),
                const SizedBox(height: 12),
                GenderSelector(
                  gender: _gender,
                  onChanged: (g) => setState(() => _gender = g),
                ),
                const SizedBox(height: 12),
                ContactFields(
                  phoneController: _phoneCtrl,
                  addressController: _addrCtrl,
                ),
              ],
            ),
          ),
          // Botón de guardar flotante
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SaveBar(
              loading: _loading,
              onSave: _save,
            ),
          ),
          LoadingOverlay(visible: _loading),
        ],
      ),
    );
  }
}
