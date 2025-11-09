import 'package:flutter/material.dart';

class SignUpActions extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback onGoSignIn;
  final bool submitting;

  const SignUpActions({
    super.key,
    required this.onSubmit,
    required this.onGoSignIn,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: submitting ? null : onSubmit,
          child: submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear cuenta'),
        ),
        TextButton(
          onPressed: submitting ? null : onGoSignIn,
          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
        ),
      ],
    );
  }
}