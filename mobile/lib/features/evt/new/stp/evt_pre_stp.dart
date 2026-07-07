import 'package:flutter/material.dart';

import '../../../../core/url/open_url.dart';
import '../../../../core/thm/app_thm.dart';
import '../ctl/evt_new_ctl.dart';

class EvtPreStp extends StatelessWidget {
  final EvtNewCtl ctl;

  const EvtPreStp({
    super.key,
    required this.ctl,
  });

  @override
  Widget build(BuildContext context) {
    final mdl = ctl.mdl;
    final hora = '${mdl.horaIni.isEmpty ? "--:--" : mdl.horaIni} - '
        '${mdl.horaFin.isEmpty ? "--:--" : mdl.horaFin}';

    return Center(
      child: SizedBox(
        width: 920,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vista Previa',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Asi se visualizara la convocatoria para el personal.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListView(
                      children: [
                        const Text(
                          'CONVOCATORIA',
                          style: TextStyle(
                            color: AppThm.accClr,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          mdl.nom.trim().isEmpty
                              ? 'Nombre del evento'
                              : mdl.nom.trim(),
                          style: const TextStyle(
                            color: AppThm.priClr,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Tipo: ${mdl.tipo}'),
                        Text(
                          'Ubicacion Google Maps: ${mdl.lugar.isEmpty ? "--" : mdl.lugar}',
                        ),
                        Text(
                          'Fecha: ${mdl.fechaTxt.isEmpty ? "--" : mdl.fechaTxt}',
                        ),
                        Text('Hora: $hora'),
                        Text('Prioridad: ${mdl.prioridad}'),
                        if (mdl.imagenNombre != null)
                          Text('Imagen: ${mdl.imagenNombre}'),
                        if (mdl.pdfNombre != null)
                          OutlinedButton.icon(
                            onPressed: () => _showPdf(context),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text('PDF: ${mdl.pdfNombre}'),
                          ),
                        if (mdl.imagenUrl != null) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ColoredBox(
                              color: Colors.black12,
                              child: Image.network(
                                mdl.imagenUrl!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                        Text('Personal convocado: ${mdl.prsItems.length}'),
                        const SizedBox(height: 22),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          mdl.desc.trim().isEmpty
                              ? 'Descripción del evento o convocatoria institucional.'
                              : mdl.desc.trim(),
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        if (mdl.prsItems.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          const Text(
                            'Agentes asignados',
                            style: TextStyle(
                              color: AppThm.priClr,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...mdl.prsItems.take(8).map(
                                (prs) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.person_outline,
                                    color: AppThm.priClr,
                                  ),
                                  title: Text(prs.nom),
                                  subtitle: Text('${prs.area} - ${prs.grupo}'),
                                ),
                              ),
                          if (mdl.prsItems.length > 8)
                            Text(
                              '+ ${mdl.prsItems.length - 8} agentes mas',
                              style: const TextStyle(color: Colors.black54),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPdf(BuildContext context) {
    final mdl = ctl.mdl;
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF adjunto'),
        content: Text(mdl.pdfNombre ?? 'Documento PDF'),
        actions: [
          if (mdl.pdfUrl != null)
            TextButton.icon(
              onPressed: () => openExternalUrl(mdl.pdfUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir vista previa'),
            ),
          if (mdl.pdfUrl != null)
            TextButton.icon(
              onPressed: () => openExternalUrl(mdl.pdfUrl!),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
