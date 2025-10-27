import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/status_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Bienestar Emocional')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const StatusBanner(),
            const SizedBox(height: 16),
            _NavCard(
              title: 'Analyze Emotion',
              subtitle: 'Escribe o dicta y analizamos tu emoción con IA',
              icon: Icons.favorite_outline,
              onTap: () => context.go('/analyze'),
            ),
            _NavCard(
              title: 'History & Charts',
              subtitle: 'Evolución de tu estado emocional',
              icon: Icons.show_chart,
              onTap: () => context.go('/history'),
            ),
            _NavCard(
              title: 'Companion Chat',
              subtitle: 'Habla con un asistente empático',
              icon: Icons.chat_bubble_outline,
              onTap: () => context.go('/chat'),
            ),
            _NavCard(
              title: 'Centros de ayuda (Mapa)',
              subtitle: 'Psicología, psiquiatría, hospitales cerca de ti',
              icon: Icons.map,
              onTap: () => context.go('/map-help'),
            ),
            _NavCard(
              title: 'SOS',
              subtitle: 'Contactos de ayuda cuando más lo necesitas',
              icon: Icons.sos,
              onTap: () => context.go('/sos'),
            ),
            _NavCard(
              title: 'Publicaciones',
              subtitle: 'Comparte y lee aportes de la comunidad',
              icon: Icons.forum_outlined,
              onTap: () => context.go('/posts'),
            ),
            _NavCard(
              title: 'Perfil',
              subtitle: 'Edita tu nombre, teléfono, foto y dirección',
              icon: Icons.person_outline,
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                // Capturamos el router antes del await para evitar el lint
                final router = GoRouter.of(context);
                await Supabase.instance.client.auth.signOut();
                router.go('/sign-in');
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: onTap,
      ),
    );
  }
}
