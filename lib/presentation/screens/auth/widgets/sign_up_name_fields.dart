import 'package:flutter/material.dart';

class SignUpNameFields extends StatelessWidget {
  final TextEditingController firstName;
  final TextEditingController lastName;

  const SignUpNameFields({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: firstName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Obligatorio'
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: lastName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Apellido'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Obligatorio'
                : null,
          ),
        ),
      ],
    );
  }
}