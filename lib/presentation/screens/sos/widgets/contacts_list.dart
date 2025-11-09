import 'package:flutter/material.dart';
import 'contact_card.dart';

typedef AvatarUrlFor = String? Function(String? path, String id);
typedef IsUploadingFor = bool Function(String id);

class ContactsList extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final AvatarUrlFor avatarUrlFor;
  final IsUploadingFor isUploadingFor;
  final void Function(String id) onChangeAvatar;
  final void Function(Map<String, dynamic> contact) onEdit;
  final void Function(String id) onDelete;

  const ContactsList({
    super.key,
    required this.contacts,
    required this.avatarUrlFor,
    required this.isUploadingFor,
    required this.onChangeAvatar,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = contacts[i];
        final id = c['id'] as String;
        final label = (c['label'] ?? '').toString();
        final phone = (c['phone'] ?? '').toString().trim();
        final email = (c['email'] ?? '').toString().trim();
        final avatarUrl = avatarUrlFor(c['avatar_path'] as String?, id);
        final uploading = isUploadingFor(id);

        return ContactCard(
          id: id,
          label: label,
          phone: phone,
          email: email,
          avatarUrl: avatarUrl,
          isUploadingAvatar: uploading,
          onChangeAvatar: () => onChangeAvatar(id),
          onEdit: () => onEdit(c),
          onDelete: () => onDelete(id),
        );
      },
    );
  }
}