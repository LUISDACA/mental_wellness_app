import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String? email;
  final DateTime? updatedAt;
  final VoidCallback onPickAvatar;

  const ProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.email,
    required this.updatedAt,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      children: [
        GestureDetector(
          onTap: onPickAvatar,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    (avatarUrl != null) ? NetworkImage(avatarUrl!) : null,
                child: (avatarUrl == null)
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.camera_alt,
                      size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (email != null && email!.isNotEmpty)
          Center(
            child: Text(
              email!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (updatedAt != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Actualizado: ${DateFormat.yMMMd(locale).add_Hm().format(updatedAt!.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}