import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goSignIn(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/sign-in');
    }
  }

  void _goSignUp(BuildContext context) => context.go('/sign-up');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado y formas sutiles
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withOpacity(0.35),
                    cs.secondaryContainer.withOpacity(0.25),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _Bubble(color: cs.primary.withOpacity(.12), size: 220),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _Bubble(color: cs.secondary.withOpacity(.10), size: 260),
          ),

          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 800;
                      final left = _HeroPanel();
                      final right = _CopyAndCtas(
                        onSignIn: () => _goSignIn(context),
                        onSignUp: () => _goSignUp(context),
                      );

                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 28),
                                Expanded(child: right),
                              ],
                            )
                          : Column(
                              children: [
                                left,
                                const SizedBox(height: 20),
                                right,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Card(
      elevation: 0,
      color: cs.surface.withOpacity(.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: isSmall ? 1.0 : 16 / 10,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = constraints.maxWidth * 0.35;
              final chipScale = constraints.maxWidth < 300 ? 0.85 : 1.0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ícono central
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.self_improvement,
                      size: iconSize,
                      color: cs.primary.withOpacity(.85),
                    ),
                  ),
                  // Chips posicionados - MEJORADO para evitar superposición
                  Positioned(
                    left: 0,
                    top: constraints.maxHeight * 0.1,
                    child: Transform.scale(
                      scale: chipScale,
                      child: const _Chip(
                        text: 'Análisis emocional',
                        icon: Icons.favorite,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: constraints.maxHeight * 0.2,
                    child: Transform.scale(
                      scale: chipScale,
                      child: const _Chip(
                        text: 'Consejos útiles',
                        icon: Icons.tips_and_updates,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: constraints.maxHeight * 0.15,
                    child: Transform.scale(
                      scale: chipScale,
                      child: const _Chip(
                        text: 'Mapa de ayuda',
                        icon: Icons.map_outlined,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: constraints.maxHeight * 0.05,
                    child: Transform.scale(
                      scale: chipScale,
                      child: const _Chip(
                        text: 'Historial & gráficas',
                        icon: Icons.show_chart,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CopyAndCtas extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  const _CopyAndCtas({required this.onSignIn, required this.onSignUp});

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
            _Feature(
                icon: Icons.chat_bubble_outline, label: 'Chat empático con IA'),
            _Feature(
                icon: Icons.mic_none, label: 'Dictado y análisis de emociones'),
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

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(.65),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.onPrimaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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

class _Bubble extends StatelessWidget {
  final Color color;
  final double size;
  const _Bubble({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 10)],
      ),
    );
  }
}
