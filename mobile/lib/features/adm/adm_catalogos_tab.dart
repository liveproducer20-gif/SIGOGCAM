import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class CatalogosTab extends StatefulWidget {
  final AdmApi api;
  const CatalogosTab({super.key, required this.api});

  @override
  State<CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<CatalogosTab> {
  static const codigos = [
    'AREAS',
    'FUNCIONES_OPERATIVAS',
    'GRUPOS',
    'JORNADAS',
    'TIPOS_ROTACION',
    'DISTRITOS',
    'SUBUNIDADES_OPERATIVAS',
    'TIPOS_SERVICIO_LUGAR',
    'ESTADOS_PERSONAL',
    'TIPOS_MOVIL',
    'ESTADOS_MOVIL',
  ];
  String codigo = codigos.first;
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.getCatalogo(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return AdmAsyncTable(
      title: 'Catalogos maestros',
      subtitle: 'Grados, areas, funciones, grupos, jornadas, distritos y tipos.',
      future: future,
      columns: const ['Código', 'Nombre', 'Orden', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      header: DropdownButtonFormField<String>(
        initialValue: codigo,
        decoration: const InputDecoration(
          labelText: 'Catálogo',
          border: OutlineInputBorder(),
        ),
        items: codigos
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            codigo = value;
            future = widget.api.getCatalogo(codigo);
          });
        },
      ),
      rowBuilder: (item) => [
        admText(item['codigo']),
        admText(item['nombre']),
        admText(item['orden']),
        AdmStateChip(active: admIsActive(item, key: 'estado')),
        AdmActions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          onDelete: () => _confirmDelete(
            item,
            'detalle ${item['nombre']}',
            () => widget.api.deleteCatalogoDetalle(admId(item)),
          ),
          active: admIsActive(item, key: 'estado'),
        ),
      ],
    );
  }

  void _reload() => setState(() { future = widget.api.getCatalogo(codigo); });

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CatalogoDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createCatalogoDetalle(codigo, data);
      } else {
        await widget.api.updateCatalogoDetalle(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setCatalogoDetalleActivo(
        admId(item),
        !admIsActive(item, key: 'estado'),
      );
      _reload();
    });
  }

  Future<void> _confirmDelete(
      Map<String, dynamic> item, String label, Future<void> Function() deleteFn) async {
    await admSafeDelete(context, label, () async {
      await deleteFn();
      _reload();
    });
  }
}

class _CatalogoDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _CatalogoDialog({this.item});
  @override
  State<_CatalogoDialog> createState() => _CatalogoDialogState();
}

class _CatalogoDialogState extends State<_CatalogoDialog> {
  late final codigo = TextEditingController(text: widget.item?['codigo']?.toString() ?? '');
  late final nombre = TextEditingController(text: widget.item?['nombre']?.toString() ?? '');
  late final descripcion = TextEditingController(text: widget.item?['descripcion']?.toString() ?? '');
  late final orden = TextEditingController(text: widget.item?['orden']?.toString() ?? '0');

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo detalle' : 'Editar detalle',
        children: [
          admField(codigo, 'Código'),
          admField(nombre, 'Nombre'),
          admField(descripcion, 'Descripción'),
          admField(orden, 'Orden', number: true),
        ],
        onSave: () => Navigator.pop(context, {
          'codigo': codigo.text.trim(),
          'nombre': nombre.text.trim(),
          'descripcion': descripcion.text.trim(),
          'orden': int.tryParse(orden.text) ?? 0,
        }),
      );
}

