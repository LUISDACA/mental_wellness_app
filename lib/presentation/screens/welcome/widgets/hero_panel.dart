import 'package:flutter/material.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Card(
      elevation: 0,
      color: cs.surface.withValues(alpha: .7),
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
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.self_improvement,
                      size: iconSize,
                      color: cs.primary.withValues(alpha: .85),
                    ),
                  ),
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

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: .65),
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