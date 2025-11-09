import 'package:flutter/material.dart';

class SignInHeader extends StatelessWidget {
  const SignInHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Bienestar Emocional', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Inicia sesión para continuar', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}