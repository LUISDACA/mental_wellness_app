import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactCard extends StatelessWidget {
  final String id;
  final String label;
  final String phone;
  final String email;
  final String? avatarUrl;
  final bool isUploadingAvatar;
  final VoidCallback onChangeAvatar;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.id,
    required this.label,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.isUploadingAvatar,
    required this.onChangeAvatar,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          (avatarUrl != null) ? NetworkImage(avatarUrl!) : null,
                      onBackgroundImageError:
                          (avatarUrl != null) ? (_, __) {} : null,
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
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        onPressed: isUploadingAvatar ? null : onChangeAvatar,
                        icon: const Icon(Icons.camera_alt),
                        iconSize: 12,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        tooltip: 'Cambiar foto',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(label.isNotEmpty ? label : 'Contacto'),
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
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child:
                      ListTile(leading: Icon(Icons.edit), title: Text('Editar')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete), title: Text('Eliminar')),
                ),
              ],
            ),
            isThreeLine: phone.isNotEmpty || email.isNotEmpty,
            subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
            onTap: phone.isNotEmpty
                ? () => launchUrl(Uri.parse('tel:$phone'))
                : null,
          ),
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
                      onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Llamar'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (phone.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse('sms:$phone')),
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
                        final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
                        final wa = Uri.parse('https://wa.me/$digits');
                        launchUrl(wa, mode: LaunchMode.externalApplication);
                      },
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      label: const Text('WhatsApp'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (email.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse('mailto:$email')),
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
  }
}