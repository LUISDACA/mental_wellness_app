import 'package:flutter/material.dart';

class SignInPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const SignInPasswordField({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<SignInPasswordField> createState() => _SignInPasswordFieldState();
}

class _SignInPasswordFieldState extends State<SignInPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscure ? 'Mostrar' : 'Ocultar',
        ),
      ),
      onFieldSubmitted: (_) => widget.onSubmit(),
      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
    );
  }
}