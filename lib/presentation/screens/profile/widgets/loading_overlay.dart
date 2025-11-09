import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool visible;

  const LoadingOverlay({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}