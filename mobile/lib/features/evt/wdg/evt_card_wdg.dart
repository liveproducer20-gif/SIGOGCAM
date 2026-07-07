import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../mdl/evt_mdl.dart';

class EvtCardWdg extends StatelessWidget {
  final EvtMdl evt;

  const EvtCardWdg({
    super.key,
    required this.evt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evt.nom,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppThm.priClr,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event, size: 18),
                const SizedBox(width: 6),
                Text(evt.fecha),
                const SizedBox(width: 20),
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(evt.hora),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    evt.tipo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(evt.estado),
                  backgroundColor: evt.estado == 'Activo'
                      ? AppThm.okClr.withValues(alpha: 0.15)
                      : AppThm.accClr.withValues(alpha: 0.15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}