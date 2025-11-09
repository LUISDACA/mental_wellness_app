import 'package:flutter/material.dart';

class NameFields extends StatelessWidget {
  final TextEditingController firstController;
  final TextEditingController lastController;

  const NameFields({
    super.key,
    required this.firstController,
    required this.lastController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: firstController,
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
            controller: lastController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Apellido',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
        ),
      ],
    );
  }
}