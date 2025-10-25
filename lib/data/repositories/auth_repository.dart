import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _sb = Supabase.instance.client;

  Future<AuthResponse> signUp({required String email, required String password, required String fullName}) async {
    return _sb.auth.signUp(email: email, password: password, data: {'full_name': fullName});
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return _sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async => _sb.auth.signOut();
}
