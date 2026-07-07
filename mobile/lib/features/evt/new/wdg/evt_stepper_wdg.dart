import 'package:flutter/material.dart';

import '../../../../core/thm/app_thm.dart';

class EvtStepperWdg extends StatelessWidget {
  final int idx;

  const EvtStepperWdg({
    super.key,
    required this.idx,
  });

  @override
  Widget build(BuildContext context) {
   final steps = ['Información', 'Convocados', 'Publicación', 'Vista previa', 'Validación'];
   

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i == idx;
          final done = i < idx;

          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      done || active ? AppThm.priClr : Colors.black26,
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  steps[i],
                  style: TextStyle(
                    color: done || active ? AppThm.priClr : Colors.black45,
                    fontWeight: done || active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      height: 2,
                      color: done ? AppThm.secClr : Colors.black12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}