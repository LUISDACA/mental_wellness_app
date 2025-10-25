
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/emotion_repository.dart';
import '../../../core/env.dart';
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
              title: 'SOS',
              subtitle: 'Contactos de ayuda cuando más lo necesitas',
              icon: Icons.sos,
              onTap: () => context.go('/sos'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/sign-in');
              },
              child: const Text('Sign out'),
            )
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
  const _NavCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
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
