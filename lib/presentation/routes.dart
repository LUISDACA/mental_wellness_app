import 'package:go_router/go_router.dart';
import 'screens/auth/sign_in_page.dart';
import 'screens/auth/sign_up_page.dart';
import 'screens/home/home_page.dart';
import 'screens/analyze/analyze_page.dart';
import 'screens/history/history_page.dart';
import 'screens/chat/chat_page.dart';
import 'screens/sos/sos_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
    GoRoute(path: '/sign-up', builder: (_, __) => const SignUpPage()),
    GoRoute(path: '/analyze', builder: (_, __) => const AnalyzePage()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
    GoRoute(path: '/sos', builder: (_, __) => const SosPage()),
  ],
);
