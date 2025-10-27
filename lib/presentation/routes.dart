import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/auth/sign_in_page.dart';
import 'screens/auth/sign_up_page.dart';
import 'screens/home/home_page.dart';
import 'screens/analyze/analyze_page.dart';
import 'screens/history/history_page.dart';
import 'screens/chat/chat_page.dart';
import 'screens/sos/sos_page.dart';
import 'screens/map/map_help_page.dart';
import 'screens/posts/posts_page.dart';

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
  // Arranca en Sign In
  initialLocation: '/sign-in',

  // Redirección según sesión
  redirect: (context, state) {
    final loggedIn = _auth.currentSession != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/sign-in' || loc == '/sign-up';

    // No logeado → solo puede ver /sign-in o /sign-up
    if (!loggedIn && !isAuthRoute) return '/sign-in';

    // Logeado → no tiene sentido estar en /sign-in /sign-up
    if (loggedIn && isAuthRoute) return '/';

    return null;
  },

  // Se refresca cuando hay login/logout
  refreshListenable: GoRouterRefreshStream(_auth.onAuthStateChange),

  routes: [
    // Rutas de auth
    GoRoute(
      path: '/sign-in',
      builder: (_, __) => const SignInPage(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (_, __) => const SignUpPage(),
    ),

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
      ],
    ),
  ],
);
