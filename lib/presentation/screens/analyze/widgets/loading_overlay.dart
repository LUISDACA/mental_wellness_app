import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  const LoadingOverlay({super.key, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (!loading) return const SizedBox.shrink();
    return const Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}