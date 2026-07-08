import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class RutasTab extends StatefulWidget {
  final AdmApi api;
  const RutasTab({super.key, required this.api});

  @override
  State<RutasTab> createState() => _RutasTabState();
}

class _RutasTabState extends State<RutasTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.getRutas();
  }

  @override
  Widget build(BuildContext context) {
    return AdmAsyncTable(
      title: 'Rutas',
      subtitle: 'Rutas organizativas para lugares de servicio.',
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
    setState(() => future = widget.api.getRutas());
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RutaDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createRuta(data);
      } else {
        await widget.api.updateRuta(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setRutaActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar ruta ${item['nombre']}?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.deleteRuta(admId(item));
      _reload();
    });
  }
}

class _RutaDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _RutaDialog({this.item});
  @override
  State<_RutaDialog> createState() => _RutaDialogState();
}

class _RutaDialogState extends State<_RutaDialog> {
  late final nombre = TextEditingController(text: _s('nombre'));
  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nueva Ruta' : 'Editar Ruta',
        children: [
          admField(nombre, 'Nombre'),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
}
