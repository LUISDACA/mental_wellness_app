import 'package:flutter/material.dart';

class SignUpEmailPhoneFields extends StatelessWidget {
  final TextEditingController email;
  final TextEditingController phone;

  const SignUpEmailPhoneFields({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Obligatorio';
            }
            if (!RegExp(r'.+@.+\..+').hasMatch(v.trim())) {
              return 'Correo no válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número de celular (opcional)',
          ),
        ),
      ],
    );
  }
}