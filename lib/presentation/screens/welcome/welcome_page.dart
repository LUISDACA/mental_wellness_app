import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/hero_panel.dart';
import 'widgets/copy_and_ctas.dart';

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
                    cs.primaryContainer.withValues(alpha: 0.35),
                    cs.secondaryContainer.withValues(alpha: 0.25),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: _Bubble(color: cs.primary.withValues(alpha: .12), size: 220),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child:
                _Bubble(color: cs.secondary.withValues(alpha: .10), size: 260),
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
                      final right = CopyAndCtas(
                        onSignIn: () => _goSignIn(context),
                        onSignUp: () => _goSignUp(context),
                      );

                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(child: HeroPanel()),
                                const SizedBox(width: 28),
                                Expanded(child: right),
                              ],
                            )
                          : Column(
                              children: [
                                const HeroPanel(),
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
