import 'package:flutter/material.dart';

class SaveBar extends StatelessWidget {
  final bool loading;
  final VoidCallback onSave;

  const SaveBar({
    super.key,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: loading ? null : onSave,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: const Text('Guardar cambios'),
      ),
    );
  }
}