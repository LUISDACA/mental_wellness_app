import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _ob1 = true;
  bool _ob2 = true;
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

  String? _yyyyMMdd(DateTime? d) =>
      d == null ? null : d.toIso8601String().substring(0, 10);

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
    final theme = Theme.of(context);

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
                      Text('Crea una cuenta',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Es rápido y fácil.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 20),

                      // Nombre y Apellido
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstName,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Obligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastName,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Obligatorio'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fecha de nacimiento
                      Text('Fecha de nacimiento',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _day,
                              items: List.generate(
                                31,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                              onChanged: (v) => setState(() => _day = v),
                              decoration:
                                  const InputDecoration(labelText: 'Día'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _month,
                              items: List.generate(
                                12,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(_monthName(i + 1)),
                                ),
                              ),
                              onChanged: (v) => setState(() => _month = v),
                              decoration:
                                  const InputDecoration(labelText: 'Mes'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _year,
                              items: List.generate(
                                100,
                                (i) {
                                  final y = DateTime.now().year - i;
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  );
                                },
                              ),
                              onChanged: (v) => setState(() => _year = v),
                              decoration:
                                  const InputDecoration(labelText: 'Año'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Género
                      Text('Género', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'female', label: Text('Mujer')),
                          ButtonSegment(value: 'male', label: Text('Hombre')),
                          ButtonSegment(
                              value: 'custom', label: Text('Personalizado')),
                        ],
                        selected: {_gender},
                        onSelectionChanged: (s) =>
                            setState(() => _gender = s.first),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Correo electrónico'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          if (!RegExp(r'.+@.+\..+').hasMatch(v.trim())) {
                            return 'Correo no válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Teléfono (opcional)
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Número de celular (opcional)',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _pass1,
                        obscureText: _ob1,
                        decoration: InputDecoration(
                          labelText: 'Contraseña nueva',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _ob1 = !_ob1),
                            icon: Icon(
                                _ob1 ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Confirmación
                      TextFormField(
                        controller: _pass2,
                        obscureText: _ob2,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _ob2 = !_ob2),
                            icon: Icon(
                                _ob2 ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                        validator: (v) =>
                            v != _pass1.text ? 'No coincide' : null,
                      ),
                      const SizedBox(height: 16),

                      // Botón
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Registrarte'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Ir a Sign In
                      TextButton(
                        onPressed: () => context.go('/sign-in'),
                        child: const Text('¿Ya tienes una cuenta?'),
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

  String _monthName(int m) {
    const names = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return names[m - 1];
  }
}
