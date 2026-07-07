import 'package:flutter/material.dart';

import '../../../../core/file/file_pick.dart';
import '../../../../core/thm/app_thm.dart';
import '../ctl/evt_new_ctl.dart';

class EvtPubStp extends StatefulWidget {
  final EvtNewCtl ctl;

  const EvtPubStp({
    super.key,
    required this.ctl,
  });

  @override
  State<EvtPubStp> createState() => _EvtPubStpState();
}

class _EvtPubStpState extends State<EvtPubStp> {
  final fecExpCtl = TextEditingController();

  EvtNewCtl get ctl => widget.ctl;

  @override
  void initState() {
    super.initState();
    fecExpCtl.text = ctl.mdl.fecExpTxt;
  }

  @override
  void dispose() {
    fecExpCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 920,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ListView(
              children: [
                const Text(
                  'Publicación',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configure como sera publicada la convocatoria.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                SwitchListTile(
                  value: ctl.mdl.pubAhora,
                  onChanged: (v) {
                    ctl.setPubAhora(v);
                    setState(() {});
                  },
                  title: const Text('Publicar inmediatamente'),
                ),
                SwitchListTile(
                  value: ctl.mdl.enviarNot,
                  onChanged: (v) {
                    ctl.setEnviarNot(v);
                    setState(() {});
                  },
                  title: const Text('Enviar notificación al personal'),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: ctl.mdl.prioridad,
                  decoration: InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Normal',
                      child: Text('Normal'),
                    ),
                    DropdownMenuItem(
                      value: 'Importante',
                      child: Text('Importante'),
                    ),
                    DropdownMenuItem(
                      value: 'Urgente',
                      child: Text('Urgente'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ctl.setPrioridad(v);
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          ctl.mdl.imagenNombre ?? 'Agregar imágenes',
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(
                          ctl.mdl.pdfNombre ?? 'Adjuntar PDF',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: fecExpCtl,
                  readOnly: true,
                  onTap: _pickExpDate,
                  decoration: InputDecoration(
                    labelText: 'Fecha de expiración',
                    suffixIcon: IconButton(
                      onPressed: _pickExpDate,
                      icon: const Icon(Icons.calendar_month),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _pickExpDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: ctl.mdl.fecExp ?? ctl.mdl.fecha ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (selected == null) return;

    ctl.setFecExp(selected);
    fecExpCtl.text = ctl.formatDate(selected);
    setState(() {});
  }

  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file == null) return;

    ctl.setImagen(file.name, file.dataUrl ?? file.previewUrl);
    setState(() {});
  }

  Future<void> _pickPdf() async {
    final file = await pickPdf();
    if (file == null) return;

    ctl.setPdf(file.name, file.dataUrl ?? file.previewUrl);
    setState(() {});
  }
}
