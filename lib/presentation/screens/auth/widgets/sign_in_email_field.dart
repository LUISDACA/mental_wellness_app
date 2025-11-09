import 'package:flutter/material.dart';

class SignInEmailField extends StatelessWidget {
  final TextEditingController controller;

  const SignInEmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        if (!v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }
}