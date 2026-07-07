import 'package:flutter/material.dart';

import '../../../../core/thm/app_thm.dart';
import '../ctl/evt_new_ctl.dart';

class EvtValStp extends StatelessWidget {
  final EvtNewCtl ctl;

  const EvtValStp({
    super.key,
    required this.ctl,
  });

  @override
  Widget build(BuildContext context) {
    final mdl = ctl.mdl;

    return Center(
      child: SizedBox(
        width: 920,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ListView(
              children: [
                const Text(
                  'Resumen y Validacion',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Revise la información antes de crear el evento.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                _ValItem(
                  ok: mdl.nom.trim().isNotEmpty,
                  txt: 'Nombre del evento registrado',
                ),
                _ValItem(
                  ok: mdl.tipoId != null,
                  txt: 'Tipo de evento seleccionado',
                ),
                _ValItem(
                  ok: mdl.lugar.trim().isNotEmpty,
                  txt: 'Dirección GPS Google Maps registrada',
                ),
                _ValItem(
                  ok: mdl.fechaTxt.trim().isNotEmpty,
                  txt: 'Fecha registrada',
                ),
                _ValItem(
                  ok: mdl.horaIni.trim().isNotEmpty &&
                      mdl.horaFin.trim().isNotEmpty,
                  txt: 'Hora de inicio y fin registrada',
                ),
                _ValItem(
                  ok: mdl.desc.trim().isNotEmpty,
                  txt: 'Descripción registrada',
                ),
                _ValItem(
                  ok: mdl.prsItems.isNotEmpty,
                  txt: 'Personal convocado seleccionado',
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 14),
                Text(
                  'Prioridad: ${mdl.prioridad}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Publicar ahora: ${mdl.pubAhora ? "Sí" : "No"}'),
                Text('Enviar notificación: ${mdl.enviarNot ? "Sí" : "No"}'),
                if (mdl.fecExpTxt.isNotEmpty)
                  Text('Expira: ${mdl.fecExpTxt}'),
                if (mdl.imagenNombre != null)
                  Text('Imagen: ${mdl.imagenNombre}'),
                if (mdl.pdfNombre != null) Text('PDF: ${mdl.pdfNombre}'),
                const SizedBox(height: 18),
                Text(
                  'Agentes asignados: ${mdl.prsItems.length}',
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (mdl.prsItems.isEmpty)
                  const Text(
                    'Aun no se ha seleccionado personal.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ...mdl.prsItems.map(
                    (prs) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: AppThm.okClr,
                      ),
                      title: Text(prs.nom),
                      subtitle: Text('${prs.area} - ${prs.grupo}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValItem extends StatelessWidget {
  final bool ok;
  final String txt;

  const _ValItem({
    required this.ok,
    required this.txt,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? AppThm.okClr : AppThm.errClr,
      ),
      title: Text(txt),
    );
  }
}
