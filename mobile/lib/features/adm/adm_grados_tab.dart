import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class GradosTab extends StatefulWidget {
  final AdmApi api;
  const GradosTab({super.key, required this.api});

  @override
  State<GradosTab> createState() => _GradosTabState();
}

class _GradosTabState extends State<GradosTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.getGrados();
  }

  @override
  Widget build(BuildContext context) {
    return AdmAsyncTable(
      title: 'Grados',
      subtitle: 'Grados académicos o jerárquicos del personal.',
      future: future,
      columns: const ['Nombre', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      rowBuilder: (item) => [
        admText(item['nombre']),
        AdmStateChip(active: admIsActive(item)),
        AdmActions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          onDelete: () => _confirmDelete(item),
          active: admIsActive(item),
        ),
      ],
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      future = widget.api.getGrados();
    });
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GradoDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createGrado(data);
      } else {
        await widget.api.updateGrado(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setGradoActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar grado ${item['nombre']}?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.deleteGrado(admId(item));
      _reload();
    });
  }
}

class _GradoDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _GradoDialog({this.item});
  @override
  State<_GradoDialog> createState() => _GradoDialogState();
}

class _GradoDialogState extends State<_GradoDialog> {
  late final nombre = TextEditingController(text: _s('nombre'));
  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo Grado' : 'Editar Grado',
        children: [
          admField(nombre, 'Nombre'),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
}
