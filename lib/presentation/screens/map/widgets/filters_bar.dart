import 'package:flutter/material.dart';
import '../utils/map_utils.dart';

class FiltersBar extends StatelessWidget {
  final Set<String> allCategories;
  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const FiltersBar({
    super.key,
    required this.allCategories,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: allCategories.map((cat) {
          final isSelected = selected.contains(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                MapUtils.iconFor(cat),
                size: 18,
                color: isSelected ? Colors.white : MapUtils.colorFor(cat),
              ),
              label: Text(MapUtils.labelFor(cat)),
              selected: isSelected,
              selectedColor: MapUtils.colorFor(cat),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              onSelected: (v) {
                if (v) {
                  onAdd(cat);
                } else {
                  onRemove(cat);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}