import 'package:flutter/material.dart';

class SignUpBirthFields extends StatelessWidget {
  final int? day;
  final int? month;
  final int? year;
  final ValueChanged<int?> onDayChanged;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const SignUpBirthFields({
    super.key,
    required this.day,
    required this.month,
    required this.year,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  String _monthName(int m) {
    const names = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Fecha de nacimiento', style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: day,
                items: List.generate(
                  31,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}'),
                  ),
                ),
                onChanged: onDayChanged,
                decoration: const InputDecoration(labelText: 'Día'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: month,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(_monthName(i + 1)),
                  ),
                ),
                onChanged: onMonthChanged,
                decoration: const InputDecoration(labelText: 'Mes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: year,
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
                onChanged: onYearChanged,
                decoration: const InputDecoration(labelText: 'Año'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}