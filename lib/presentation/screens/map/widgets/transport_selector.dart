import 'package:flutter/material.dart';
import '../models/transport_mode.dart';

class TransportSelector extends StatelessWidget {
  final TransportMode mode;
  final ValueChanged<TransportMode?> onChanged;
  const TransportSelector({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<TransportMode>(
        value: mode,
        items: const [
          DropdownMenuItem(
            value: TransportMode.walking,
            child: Row(children: [
              Icon(Icons.directions_walk_rounded),
              SizedBox(width: 6),
              Text('Caminando')
            ]),
          ),
          DropdownMenuItem(
            value: TransportMode.driving,
            child: Row(children: [
              Icon(Icons.directions_car_rounded),
              SizedBox(width: 6),
              Text('Conduciendo')
            ]),
          ),
        ],
        onChanged: onChanged,
        icon: const Icon(Icons.route_rounded),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}