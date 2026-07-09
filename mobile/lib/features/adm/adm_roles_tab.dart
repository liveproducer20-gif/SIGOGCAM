import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class RolesTab extends AdmCrudTab {
  final int tabIndex;
  const RolesTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _search = '';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as RolesTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await widget.api.getRoles(page: _page, search: _search);
    if (!mounted) return;
    setState(() {
      _future = Future.value(result.datos);
      _total = result.total;
      _totalPages = result.totalPages;
    });
  }

  void _reload() {
    setState(() { _page = 1; });
    _load();
  }

  void _onPageChanged(int page) {
    setState(() { _page = page; });
    _load();
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _page = 1;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdmAsyncTable(
      title: 'Roles',
      subtitle: 'Matriz de permisos del sistema por rol institucional.',
      future: _future,
      columns: const ['Nombre', 'Descripción', 'Permisos', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      total: _total,
      currentPage: _page,
      totalPages: _totalPages,
      onPageChanged: _onPageChanged,
      onSearch: _onSearch,
      searchHint: 'Buscar rol...',
      rowBuilder: (item) => [
        admText(item['nombre']),
        admText(item['descripcion']),
        admText((item['permisos'] as List<dynamic>? ?? []).length),
        AdmStateChip(active: admIsActive(item)),
        AdmActions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          onDelete: () => _confirmDelete(item, 'rol ${item['nombre']}', () => widget.api.deleteRol(admId(item))),
          active: admIsActive(item),
        ),
      ],
    );
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final permisos = await widget.api.getPermisos();
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RolDialog(item: item, permisos: permisos),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createRol(data);
      } else {
        await widget.api.updateRol(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setRolActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> item, String label, Future<void> Function() deleteFn) async {
    final ok = await admConfirm(context, 'Confirmar', '¿Eliminar $label?');
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await deleteFn();
      _reload();
    });
  }
}

class _RolDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> permisos;
  const _RolDialog({this.item, required this.permisos});

  @override
  State<_RolDialog> createState() => _RolDialogState();
}

class _RolDialogState extends State<_RolDialog> {
  late final nombre = TextEditingController(text: widget.item?['nombre']?.toString() ?? '');
  late final descripcion = TextEditingController(text: widget.item?['descripcion']?.toString() ?? '');
  final selected = <String>{};

  @override
  void initState() {
    super.initState();
    final itemPermisos = widget.item?['permisos'];
    if (itemPermisos is List) {
      for (final p in itemPermisos) {
        if (p is Map) {
          selected.add(p['codigo'].toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo rol' : 'Editar rol',
        children: [
          admField(nombre, 'Nombre'),
          admField(descripcion, 'Descripcion'),
          const Text('Permisos:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...widget.permisos.map((permiso) => CheckboxListTile(
                title: Text(permiso['descripcion']?.toString() ?? permiso['codigo'].toString()),
                value: selected.contains(permiso['codigo'].toString()),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.add(permiso['codigo'].toString());
                  } else {
                    selected.remove(permiso['codigo'].toString());
                  }
                }),
              )),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
          'descripcion': descripcion.text.trim(),
          'permisos': selected.toList(),
        }),
      );
}
