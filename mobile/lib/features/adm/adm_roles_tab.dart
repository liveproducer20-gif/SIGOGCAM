import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
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
  int _pageSize = 10;
  String _search = '';
  String _status = 'Todos';
  String _sort = 'Nombre A-Z';
  int _permissionAssignments = 0;
  int _usersWithRole = 0;
  int _activeRoles = 0;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as RolesTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await widget.api.getRoles(
      page: _page,
      limit: _pageSize,
      search: _search,
    );
    var allRoles = result.datos;
    try {
      allRoles = await widget.api.getRolesList();
    } catch (_) {
      // La página sigue funcionando con la respuesta paginada.
    }
    final permissionAssignments = allRoles.fold<int>(
      0,
      (sum, role) => sum + (role['permisos'] as List<dynamic>? ?? []).length,
    );
    var usersWithRole = 0;
    final usersByRole = <String, int>{};
    try {
      final personal = await widget.api.getPersonalList();
      usersWithRole = personal.where((p) {
        final role = p['rol']?.toString().trim();
        if (role != null && role.isNotEmpty) {
          final key = role.toLowerCase();
          usersByRole[key] = (usersByRole[key] ?? 0) + 1;
        }
        return role != null && role.isNotEmpty;
      }).length;
    } catch (_) {
      // El resumen sigue disponible aunque el usuario no pueda consultar Personal.
    }
    if (!mounted) return;
    for (final role in result.datos) {
      final key = role['nombre']?.toString().trim().toLowerCase() ?? '';
      role['usuarios'] = usersByRole[key] ?? 0;
    }
    setState(() {
      _future = Future.value(result.datos);
      _total = result.total;
      _totalPages = result.totalPages;
      _permissionAssignments = permissionAssignments;
      _usersWithRole = usersWithRole;
      _activeRoles = allRoles.where(admIsActive).length;
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final raw = snapshot.data ?? const <Map<String, dynamic>>[];
        final roles = raw.where((role) {
          if (_status == 'Activos') return admIsActive(role);
          if (_status == 'Inactivos') return !admIsActive(role);
          return true;
        }).toList()
          ..sort((a, b) {
            final left = a['nombre']?.toString().toLowerCase() ?? '';
            final right = b['nombre']?.toString().toLowerCase() ?? '';
            return _sort == 'Nombre Z-A'
                ? right.compareTo(left)
                : left.compareTo(right);
          });
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Administración', style: TextStyle(fontSize: 13, color: AdmTokens.grey500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Roles', style: AdmTokens.h1),
              const SizedBox(height: 5),
              const Text('Gestiona los roles y permisos del sistema por rol institucional.', style: AdmTokens.subtitle),
              const SizedBox(height: 22),
              AdminSummaryRow(cards: [
                AdminSummaryCardData(icon: Icons.shield_outlined, value: '$_total', label: 'Roles registrados', color: AdmTokens.primary),
                AdminSummaryCardData(icon: Icons.check_circle_outline, value: '$_activeRoles', label: 'En uso actualmente', color: AdmTokens.success),
                AdminSummaryCardData(icon: Icons.key_outlined, value: '$_permissionAssignments', label: 'Permisos asignados', color: const Color(0xFF7C3AED)),
                AdminSummaryCardData(icon: Icons.group_outlined, value: '$_usersWithRole', label: 'Usuarios con rol', color: const Color(0xFFF59E0B)),
              ]),
              const SizedBox(height: 20),
              _RolesToolbar(
                status: _status,
                sort: _sort,
                onSearch: _onSearch,
                onStatus: (value) => setState(() => _status = value),
                onSort: (value) => setState(() => _sort = value),
                onRefresh: _reload,
                onCreate: () => _edit(null),
              ),
              const SizedBox(height: 16),
              _RolesTable(
                roles: roles,
                loading: snapshot.connectionState == ConnectionState.waiting,
                onView: _showPermissions,
                onEdit: _edit,
                onToggle: _toggle,
                onDelete: (item) => _confirmDelete(item, 'rol ${item['nombre']}', () => widget.api.deleteRol(admId(item))),
              ),
              const SizedBox(height: 14),
              _RolesFooter(
                page: _page,
                totalPages: _totalPages,
                total: _total,
                visible: roles.length,
                pageSize: _pageSize,
                onPage: _onPageChanged,
                onPageSize: (value) {
                  setState(() { _pageSize = value; _page = 1; });
                  _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPermissions(Map<String, dynamic> item) async {
    final permissions = (item['permisos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permisos de ${item['nombre'] ?? 'rol'}'),
        content: SizedBox(
          width: 520,
          child: permissions.isEmpty
              ? const Text('Este rol no tiene permisos asignados.')
              : Wrap(spacing: 8, runSpacing: 8, children: [for (final p in permissions) Chip(label: Text(p))]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
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

class _RolesToolbar extends StatelessWidget {
  final String status;
  final String sort;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onSort;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _RolesToolbar({
    required this.status,
    required this.sort,
    required this.onSearch,
    required this.onStatus,
    required this.onSort,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final controls = [
        _CompactSelect(value: status, values: const ['Todos', 'Activos', 'Inactivos'], icon: Icons.filter_alt_outlined, onChanged: onStatus),
        _CompactSelect(value: sort, values: const ['Nombre A-Z', 'Nombre Z-A'], icon: Icons.sort_rounded, onChanged: onSort),
        _IconAction(icon: Icons.refresh_rounded, tooltip: 'Refrescar', onTap: onRefresh),
        FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nuevo rol')),
      ];
      if (constraints.maxWidth < 980) {
        return Column(children: [
          AdminSearchBar(onChanged: onSearch, hintText: 'Buscar rol, descripción o permiso...'),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: Wrap(spacing: 8, runSpacing: 8, children: controls)),
        ]);
      }
      return Row(children: [
        Expanded(child: AdminSearchBar(onChanged: onSearch, hintText: 'Buscar rol, descripción o permiso...')),
        const SizedBox(width: 12),
        ...controls.expand((widget) => [widget, const SizedBox(width: 8)]).toList()..removeLast(),
      ]);
    },
  );
}

class _CompactSelect extends StatelessWidget {
  final String value;
  final List<String> values;
  final IconData icon;
  final ValueChanged<String> onChanged;
  const _CompactSelect({required this.value, required this.values, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value,
      icon: const Icon(Icons.expand_more_rounded, size: 18),
      items: [for (final item in values) DropdownMenuItem(value: item, child: Row(children: [Icon(icon, size: 16, color: AdmTokens.grey500), const SizedBox(width: 7), Text(item)]))],
      onChanged: (next) { if (next != null) onChanged(next); },
    )),
  );
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.tooltip, required this.onTap});
  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    child: MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 48,
        width: 48,
        decoration: BoxDecoration(color: hovered ? const Color(0xFFEFF6FF) : Colors.white, border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(12)),
        child: IconButton(onPressed: widget.onTap, icon: Icon(widget.icon, color: AdmTokens.primary)),
      ),
    ),
  );
}

class _RolesTable extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final bool loading;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _RolesTable({required this.roles, required this.loading, required this.onView, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 22, offset: Offset(0, 6))]),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 58,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 82,
          horizontalMargin: 20,
          columnSpacing: 28,
          headingRowColor: WidgetStateProperty.all(const Color(0xFF0D3F8A)),
          dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? const Color(0xFFF5F8FC) : Colors.white),
          columns: const [
            DataColumn(label: Text('Rol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Descripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Permisos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Usuarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Estado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Acciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ],
          rows: roles.isEmpty
              ? [DataRow(cells: [const DataCell(SizedBox(width: 180, child: Text('Sin roles para mostrar'))), for (var i = 1; i < 6; i++) const DataCell(SizedBox.shrink())])]
              : [for (final role in roles) DataRow(cells: _cells(role))],
        ),
      ),
    );
  }

  List<DataCell> _cells(Map<String, dynamic> role) {
    final name = role['nombre']?.toString() ?? 'Sin nombre';
    final permissions = (role['permisos'] as List<dynamic>? ?? []).length;
    final users = int.tryParse(role['usuarios']?.toString() ?? '') ?? 0;
    final active = admIsActive(role);
    final visual = _roleVisual(name);
    return [
      DataCell(SizedBox(width: 190, child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: visual.$2.withValues(alpha: .11), shape: BoxShape.circle), child: Icon(visual.$1, color: visual.$2, size: 20)), const SizedBox(width: 11), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: AdmTokens.grey800)))]))),
      DataCell(SizedBox(width: 260, child: Text(role['descripcion']?.toString() ?? 'Sin descripción', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.35, color: AdmTokens.grey600)))),
      DataCell(SizedBox(width: 100, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$permissions', style: const TextStyle(fontWeight: FontWeight.w700)), InkWell(onTap: () => onView(role), child: const Text('Ver permisos', style: TextStyle(fontSize: 12, color: AdmTokens.primary, fontWeight: FontWeight.w600)))]))),
      DataCell(Row(children: [const Icon(Icons.group_outlined, size: 18, color: AdmTokens.grey500), const SizedBox(width: 6), Text('$users', style: const TextStyle(fontWeight: FontWeight.w600))])),
      DataCell(AdmStateChip(active: active)),
      DataCell(Row(children: [
        _SmallAction(icon: Icons.visibility_outlined, tooltip: 'Ver', onTap: () => onView(role)),
        const SizedBox(width: 6),
        _SmallAction(icon: Icons.edit_outlined, tooltip: 'Editar', onTap: () => onEdit(role)),
        const SizedBox(width: 6),
        PopupMenuButton<String>(tooltip: 'Más opciones', icon: const Icon(Icons.more_horiz_rounded, color: AdmTokens.grey600), onSelected: (value) { if (value == 'toggle') onToggle(role); if (value == 'delete') onDelete(role); }, itemBuilder: (_) => [PopupMenuItem(value: 'toggle', child: Text(active ? 'Desactivar' : 'Activar')), const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AdmTokens.error)))]),
      ])),
    ];
  }

  (IconData, Color) _roleVisual(String name) {
    final key = name.toLowerCase();
    if (key.contains('admin')) return (Icons.shield_outlined, const Color(0xFF7C3AED));
    if (key.contains('audit')) return (Icons.manage_search_outlined, const Color(0xFFF97316));
    if (key.contains('oper')) return (Icons.settings_suggest_outlined, const Color(0xFF2563EB));
    if (key.contains('comun')) return (Icons.campaign_outlined, const Color(0xFF0284C7));
    if (key.contains('inspect')) return (Icons.star_outline_rounded, const Color(0xFFEAB308));
    if (key.contains('encarg')) return (Icons.assignment_outlined, const Color(0xFF0F766E));
    return (Icons.person_outline_rounded, const Color(0xFF16A34A));
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SmallAction({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(borderRadius: BorderRadius.circular(9), onTap: onTap, child: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: AdmTokens.primary))));
}

class _RolesFooter extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final int visible;
  final int pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  const _RolesFooter({required this.page, required this.totalPages, required this.total, required this.visible, required this.pageSize, required this.onPage, required this.onPageSize});
  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (start + visible - 1).clamp(0, total);
    return Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 10, children: [
      Text('Mostrando $start a $end de $total roles', style: const TextStyle(color: AdmTokens.grey500, fontSize: 13)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: 'Página anterior', onPressed: page > 1 ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left_rounded)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AdmTokens.primary, borderRadius: BorderRadius.circular(9)), child: Text('$page', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        IconButton(tooltip: 'Página siguiente', onPressed: page < totalPages ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right_rounded)),
        const SizedBox(width: 10),
        DropdownButton<int>(value: pageSize, underline: const SizedBox.shrink(), items: const [DropdownMenuItem(value: 10, child: Text('10 por página')), DropdownMenuItem(value: 25, child: Text('25 por página')), DropdownMenuItem(value: 50, child: Text('50 por página'))], onChanged: (value) { if (value != null) onPageSize(value); }),
      ]),
    ]);
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
