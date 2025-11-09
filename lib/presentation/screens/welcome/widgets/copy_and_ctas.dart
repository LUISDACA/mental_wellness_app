import 'package:flutter/material.dart';

class CopyAndCtas extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  const CopyAndCtas({super.key, required this.onSignIn, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienestar Emocional',
          style: text.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isSmall ? 28 : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Una app para acompañarte día a día: analiza cómo te sientes, '
          'recibe recomendaciones breves, guarda tu progreso y encuentra ayuda cercana cuando la necesites.',
          style: text.titleMedium,
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Feature(icon: Icons.chat_bubble_outline, label: 'Chat empático con IA'),
            _Feature(icon: Icons.mic_none, label: 'Dictado y análisis de emociones'),
            _Feature(icon: Icons.health_and_safety_outlined, label: 'Modo SOS'),
            _Feature(icon: Icons.public, label: 'Centros de ayuda en mapa'),
            _Feature(icon: Icons.person_outline, label: 'Perfil y privacidad'),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión'),
            ),
            OutlinedButton.icon(
              onPressed: onSignUp,
              icon: const Icon(Icons.app_registration),
              label: const Text('Crear cuenta'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Al continuar aceptas nuestras buenas prácticas de cuidado y respeto.',
          style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: cs.primary),
      label: Text(label),
      side: BorderSide(color: cs.outlineVariant),
      backgroundColor: cs.surface,
    );
  }
}