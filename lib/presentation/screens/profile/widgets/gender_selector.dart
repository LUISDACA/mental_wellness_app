import 'package:flutter/material.dart';

class GenderSelector extends StatelessWidget {
  final String gender;
  final ValueChanged<String> onChanged;

  const GenderSelector({
    super.key,
    required this.gender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Género'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'female',
              label: Text('Mujer'),
              icon: Icon(Icons.female, size: 18),
            ),
            ButtonSegment(
              value: 'male',
              label: Text('Hombre'),
              icon: Icon(Icons.male, size: 18),
            ),
            ButtonSegment(
              value: 'custom',
              label: Text('Otro'),
              icon: Icon(Icons.person, size: 18),
            ),
          ],
          selected: {gender},
          onSelectionChanged: (s) => onChanged(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}