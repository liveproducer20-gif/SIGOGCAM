import 'package:flutter/material.dart';

import '../../core/file/file_pick.dart';
import '../../core/file/file_pick_result.dart';
import 'sup_api.dart';

const supportModules = [
  'Eventos',
  'Cartillas',
  'Personal',
  'Roles',
  'Lugares',
  'Rutas',
  'Grados',
  'EAS',
  'Móviles',
  'Asignaciones',
  'Insignias',
  'Reportes',
  'Configuración',
  'General',
];

class SupportReportForm extends StatefulWidget {
  final SupportApi api;
  final VoidCallback onSubmitted;
  const SupportReportForm({
    super.key,
    required this.api,
    required this.onSubmitted,
  });
  @override
  State<SupportReportForm> createState() => _SupportReportFormState();
}

class _SupportReportFormState extends State<SupportReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _detail = TextEditingController();
  String? _module;
  FilePickResult? _image;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 16 : 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 700 ? 18 : 28,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_alert_rounded, color: Color(0xFF0D5BD7)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nuevo reporte de problema',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF082F6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cuéntanos qué ocurrió. El equipo de soporte recibirá el reporte en tiempo real.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _title,
                    maxLength: 200,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título del problema *',
                      hintText: 'Ej. No puedo guardar una cartilla',
                      prefixIcon: Icon(Icons.title_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final x = v?.trim() ?? '';
                      if (x.isEmpty) return 'Ingresa un título';
                      if (x.length < 5) {
                        return 'Describe el problema con al menos 5 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _module,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Módulo relacionado *',
                      prefixIcon: Icon(Icons.widgets_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: supportModules
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _module = v),
                    validator: (v) =>
                        v == null ? 'Selecciona el módulo donde ocurrió' : null,
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, c) {
                      final detail = TextFormField(
                        controller: _detail,
                        minLines: 7,
                        maxLines: 12,
                        maxLength: 3000,
                        decoration: const InputDecoration(
                          labelText: 'Detalle del problema *',
                          hintText:
                              'Describe los pasos realizados, el resultado esperado y el mensaje mostrado...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final x = v?.trim() ?? '';
                          if (x.isEmpty) return 'Describe el problema';
                          if (x.length < 20) {
                            return 'Incluye al menos 20 caracteres';
                          }
                          return null;
                        },
                      );
                      final upload = _UploadBox(
                        image: _image,
                        onPick: _pickImage,
                        onRemove: () => setState(() => _image = null),
                      );
                      if (c.maxWidth < 760) {
                        return Column(
                          children: [
                            detail,
                            const SizedBox(height: 16),
                            upload,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: detail),
                          const SizedBox(width: 18),
                          Expanded(flex: 2, child: upload),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _saving ? _none : _clear,
                        child: const Text('Limpiar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _saving ? _none : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('Enviar reporte'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  VoidCallback? get _none => null;
  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file == null) return;
    final type = (file.mimeType ?? '').toLowerCase();
    final valid = ['image/png', 'image/jpeg', 'image/webp'].contains(type);
    if (!valid || ((file.size ?? 0) > 5 * 1024 * 1024)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usa una imagen PNG, JPG, JPEG o WEBP de máximo 5 MB.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _image = file);
  }

  void _clear() {
    _formKey.currentState?.reset();
    _title.clear();
    _detail.clear();
    setState(() {
      _module = null;
      _image = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.api.create(
        title: _title.text.trim(),
        module: _module!,
        description: _detail.text.trim(),
        image: _image,
      );
      if (!mounted) return;
      _clear();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Soporte ya fue notificado.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _UploadBox extends StatelessWidget {
  final FilePickResult? image;
  final VoidCallback onPick, onRemove;
  const _UploadBox({
    required this.image,
    required this.onPick,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 245,
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: image == null
        ? InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Color(0xFF0D5BD7),
                ),
                SizedBox(height: 10),
                Text(
                  'Subir imagen',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'PNG, JPG o WEBP · Máx. 5 MB',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                SizedBox(height: 14),
                Chip(label: Text('Seleccionar archivo')),
              ],
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image!.dataUrl ?? image!.previewUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: onRemove,
                  tooltip: 'Eliminar imagen',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
  );
}
