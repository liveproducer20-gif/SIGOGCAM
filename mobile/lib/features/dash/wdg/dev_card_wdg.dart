import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';

class DevCardWdg extends StatelessWidget {
  final String ttl;

  const DevCardWdg({
    super.key,
    required this.ttl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 76,
                color: Colors.black38,
              ),
              const SizedBox(height: 20),
              Text(
                ttl,
                style: const TextStyle(
                  color: AppThm.priClr,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Módulo en desarrollo',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esta funcionalidad estará disponible en una próxima actualización.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}