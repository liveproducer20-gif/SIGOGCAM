import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class EasTab extends AdmCrudTab {
  const EasTab({super.key, required super.api});

  @override
  State<AdmCrudTab> createState() => _EasState();
}

class _EasState extends State<AdmCrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getEas();
  }

  @override
  Widget build(BuildContext context) => AdmAsyncTable(
        title: 'EAS',
        subtitle: 'Estaciones de Accion Segura disponibles para servicios.',
        future: future,
        columns: const ['Código', 'Nombre', 'Distrito', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          admText(item['codigo']),
          admText(item['nombre']),
          admText(item['distrito']),
          AdmStateChip(active: admIsActive(item)),
          AdmActions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            onDelete: () => _confirmDelete(
              item,
              'EAS ${item['nombre']}',
              () => widget.api.deleteEas(admId(item)),
            ),
            active: admIsActive(item),
          ),
        ],
      );

  void _reload() {
    setState(() {
      future = widget.api.getEas();
    });
  }
  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await admLoadCatalogs(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EasDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createEas(data)
          : await widget.api.updateEas(admId(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setEasActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(
      Map<String, dynamic> item, String label, Future<void> Function() deleteFn) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar $label?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await deleteFn();
      _reload();
    });
  }
}

abstract class _BaseCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _BaseCatalogDialog({this.item, required this.catalogs});
}

class _EasDialog extends _BaseCatalogDialog {
  const _EasDialog({super.item, required super.catalogs});
  @override
  State<_EasDialog> createState() => _EasDialogState();
}

class _EasDialogState extends State<_EasDialog> {
  late final codigo = TextEditingController(text: _s('codigo'));
  late final nombre = TextEditingController(text: _s('nombre'));
  late final direccion = TextEditingController(text: _s('direccion'));
  int? distritoId;
  @override
  void initState() {
    super.initState();
    distritoId = _int('distrito_id');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nueva EAS' : 'Editar EAS',
        children: [
          admField(codigo, 'Código'),
          admField(nombre, 'Nombre'),
          admField(direccion, 'Dirección'),
          admDropdown('Distrito', widget.catalogs['DISTRITOS'], distritoId, (v) => setState(() => distritoId = v)),
        ],
        onSave: () => Navigator.pop(context, {
          'codigo': codigo.text.trim(),
          'nombre': nombre.text.trim(),
          'direccion': direccion.text.trim(),
          'distritoId': distritoId,
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}
