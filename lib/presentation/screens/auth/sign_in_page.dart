import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/auth_repository.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SIP();
}

class _SIP extends State<SignInPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  final _repo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              try {
                await _repo.signIn(email: _email.text.trim(), password: _pass.text);
                if (mounted) context.go('/');
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
              if (mounted) setState(() => _loading = false);
            },
            child: Text(_loading ? '...' : 'Sign In'),
          ),
          TextButton(onPressed: () => context.go('/sign-up'), child: const Text('Create account')),
        ]),
      ),
    );
  }
}
