import 'package:flutter/material.dart';

class SignInActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onGoSignUp;

  const SignInActions({
    super.key,
    required this.loading,
    required this.onSubmit,
    required this.onGoSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 44,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Iniciar sesión'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿No tienes cuenta?'),
            TextButton(
              onPressed: onGoSignUp,
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ],
    );
  }
}