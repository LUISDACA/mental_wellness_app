import 'package:flutter/material.dart';

class RadiusMenu extends StatelessWidget {
  final int value;
  final ValueChanged<int> onSelected;
  const RadiusMenu({super.key, required this.value, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Radio de búsqueda',
      onSelected: onSelected,
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 1000, child: Text('1 km')),
        PopupMenuItem(value: 2000, child: Text('2 km')),
        PopupMenuItem(value: 5000, child: Text('5 km')),
        PopupMenuItem(value: 10000, child: Text('10 km')),
      ],
      icon: const Icon(Icons.radar_rounded),
    );
  }
}