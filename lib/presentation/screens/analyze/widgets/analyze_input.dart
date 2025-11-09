import 'package:flutter/material.dart';

class AnalyzeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool listening;
  final VoidCallback onDictate;
  final VoidCallback onAnalyze;

  const AnalyzeInput({
    super.key,
    required this.controller,
    required this.listening,
    required this.onDictate,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '¿Cómo te sientes? Escríbelo aquí…',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDictate,
                    icon: Icon(
                      listening ? Icons.stop_circle_outlined : Icons.mic,
                    ),
                    label: Text(listening ? 'Detener' : 'Dictar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAnalyze,
                    icon: const Icon(Icons.auto_graph),
                    label: const Text('Analizar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}