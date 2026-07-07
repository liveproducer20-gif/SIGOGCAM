import 'package:flutter/material.dart';

class EvtNavWdg extends StatelessWidget {
  final int idx;
  final VoidCallback onBack;
  final Future<void> Function() onNext;
  final int total;
  final bool saving;

  const EvtNavWdg({
    super.key,
    required this.idx,
    required this.onBack,
    required this.onNext,
    required this.total,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final ultimo = idx == total - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 18,
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: saving ? null : onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: saving ? null : onNext,
            icon: Icon(
              ultimo ? Icons.check_circle : Icons.arrow_forward,
            ),
            label: Text(
              saving
                  ? 'Guardando...'
                  : ultimo
                      ? 'Crear Evento'
                      : 'Siguiente',
            ),
          ),
        ],
      ),
    );
  }
}
