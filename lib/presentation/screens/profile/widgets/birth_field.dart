import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BirthField extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onPick;

  const BirthField({
    super.key,
    required this.birthDate,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.cake_outlined),
      label: Text(
        birthDate == null
            ? 'Fecha de nacimiento'
            : DateFormat.yMMMd(locale).format(birthDate!),
      ),
    );
  }
}