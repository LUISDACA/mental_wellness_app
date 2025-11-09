import 'package:flutter/material.dart';

class SignUpPasswordFields extends StatefulWidget {
  final TextEditingController password;
  final TextEditingController confirmPassword;

  const SignUpPasswordFields({
    super.key,
    required this.password,
    required this.confirmPassword,
  });

  @override
  State<SignUpPasswordFields> createState() => _SignUpPasswordFieldsState();
}

class _SignUpPasswordFieldsState extends State<SignUpPasswordFields> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.password,
          obscureText: _obscure1,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            suffixIcon: IconButton(
              icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.confirmPassword,
          obscureText: _obscure2,
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            suffixIcon: IconButton(
              icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),
          validator: (v) {
            if (v != widget.password.text) {
              return 'No coincide';
            }
            return null;
          },
        ),
      ],
    );
  }
}