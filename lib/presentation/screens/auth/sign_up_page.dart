import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/sign_up_header.dart';
import 'widgets/sign_up_name_fields.dart';
import 'widgets/sign_up_birth_fields.dart';
import 'widgets/sign_up_email_phone_fields.dart';
import 'widgets/sign_up_password_fields.dart';
import 'widgets/sign_up_actions.dart';
import '../profile/widgets/gender_selector.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  int? _day;
  int? _month;
  int? _year;
  String _gender = 'female';
  bool _loading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  bool _isValidDate(int y, int m, int d) {
    if (y < 1900 || m < 1 || m > 12 || d < 1 || d > 31) return false;
    final dt = DateTime(y, m, d);
    return dt.year == y && dt.month == m && dt.day == d;
  }

  String? _yyyyMMdd(DateTime? d) => (d?.toIso8601String())?.substring(0, 10);

  Future<void> _tryUpsertProfile(String? uid) async {
    if (uid == null) return; // si el registro requiere verificación por email

    DateTime? birth;
    if (_year != null &&
        _month != null &&
        _day != null &&
        _isValidDate(_year!, _month!, _day!)) {
      birth = DateTime(_year!, _month!, _day!);
    }

    final sb = Supabase.instance.client;
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final full = '$first $last'.trim();
    final phone = _phone.text.trim();

    try {
      await sb.from('profiles').upsert({
        'id': uid,
        'email': _email.text.trim(),
        'first_name': first.isEmpty ? null : first,
        'last_name': last.isEmpty ? null : last,
        'full_name': full.isEmpty ? null : full,
        'birth_date': _yyyyMMdd(birth), // columna DATE en profiles
        'gender': _gender, // 'female' | 'male' | 'custom'
        'phone': phone.isEmpty ? null : phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Puede fallar si no hay sesión aún por verificación. No es crítico:
      // el usuario puede completar/editar luego en ProfilePage.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final supa = Supabase.instance.client;

      final birthIso = (_year != null &&
              _month != null &&
              _day != null &&
              _isValidDate(_year!, _month!, _day!))
          ? DateTime(_year!, _month!, _day!).toIso8601String()
          : null;

      final res = await supa.auth.signUp(
        email: _email.text.trim(),
        password: _pass1.text,
        data: {
          'full_name':
              '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
          'phone': _phone.text.trim(),
          'gender': _gender,
          'birthdate': birthIso, // metadato en auth.users
        },
      );

      await _tryUpsertProfile(res.user?.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.session == null
                ? 'Cuenta creada. Revisa tu correo para verificarla.'
                : 'Cuenta creada correctamente.',
          ),
        ),
      );
      context.go('/sign-in');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + insets),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SignUpHeader(),
                      const SizedBox(height: 20),
                      SignUpNameFields(
                        firstName: _firstName,
                        lastName: _lastName,
                      ),
                      const SizedBox(height: 16),
                      SignUpBirthFields(
                        day: _day,
                        month: _month,
                        year: _year,
                        onDayChanged: (v) => setState(() => _day = v),
                        onMonthChanged: (v) => setState(() => _month = v),
                        onYearChanged: (v) => setState(() => _year = v),
                      ),
                      const SizedBox(height: 16),
                      GenderSelector(
                        gender: _gender,
                        onChanged: (g) => setState(() => _gender = g),
                      ),
                      const SizedBox(height: 16),
                      SignUpEmailPhoneFields(
                        email: _email,
                        phone: _phone,
                      ),
                      const SizedBox(height: 12),
                      SignUpPasswordFields(
                        password: _pass1,
                        confirmPassword: _pass2,
                      ),
                      const SizedBox(height: 16),
                      SignUpActions(
                        submitting: _loading,
                        onSubmit: _submit,
                        onGoSignIn: () => context.go('/sign-in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
