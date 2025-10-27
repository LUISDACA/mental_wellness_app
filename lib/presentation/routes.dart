import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/welcome/welcome_page.dart';
import 'screens/auth/sign_in_page.dart';
import 'screens/auth/sign_up_page.dart';
import 'screens/home/home_page.dart';
import 'screens/analyze/analyze_page.dart';
import 'screens/history/history_page.dart';
import 'screens/chat/chat_page.dart';
import 'screens/sos/sos_page.dart';
import 'screens/map/map_help_page.dart';
import 'screens/posts/posts_page.dart';
import 'screens/profile/profile_page.dart';

/// Notificador para refrescar GoRouter cuando cambia el estado de auth.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _auth = Supabase.instance.client.auth;

final router = GoRouter(
  // ➜ Pantalla inicial
  initialLocation: '/welcome',

  // Redirección según sesión (protege las rutas internas)
  redirect: (context, state) {
    final loggedIn = _auth.currentSession != null;
    final loc = state.matchedLocation;

    // Rutas públicas
    final isPublic =
        loc == '/welcome' || loc == '/sign-in' || loc == '/sign-up';

    // No logeado → solo puede ver públicas
    if (!loggedIn && !isPublic) return '/welcome';

    // Logeado → no tiene sentido estar en páginas públicas
    if (loggedIn && isPublic) return '/';

    return null;
  },

  // Se refresca cuando hay login/logout
  refreshListenable: GoRouterRefreshStream(_auth.onAuthStateChange),

  routes: [
    // Públicas
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
    GoRoute(path: '/sign-up', builder: (_, __) => const SignUpPage()),

    // App (protegida)
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePage(),
      routes: [
        GoRoute(path: 'analyze', builder: (_, __) => const AnalyzePage()),
        GoRoute(path: 'history', builder: (_, __) => const HistoryPage()),
        GoRoute(path: 'chat', builder: (_, __) => const ChatPage()),
        GoRoute(path: 'sos', builder: (_, __) => const SosPage()),
        GoRoute(path: 'map-help', builder: (_, __) => const MapHelpPage()),
        GoRoute(path: 'posts', builder: (_, __) => const PostsPage()),
        GoRoute(path: 'profile', builder: (_, __) => const ProfilePage()),
      ],
    ),
  ],
);
