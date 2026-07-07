import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'adm_api.dart';

class AdmHomeScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final bool showBack;

  const AdmHomeScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
    this.showBack = false,
  });

  @override
  State<AdmHomeScr> createState() => _AdmHomeScrState();
}

class _AdmHomeScrState extends State<AdmHomeScr> {
  final api = AdmApi();

  List<_TabDef> get _tabs => [
        if (widget.user.hasPermission('personal.ver'))
          _TabDef(
            icon: Icons.groups_outlined,
            label: 'Personal',
            child: _PersonalTab(api: api),
          ),
        if (widget.user.hasPermission('catalogos.ver'))
          _TabDef(
            icon: Icons.list_alt_outlined,
            label: 'Catalogos',
            child: _CatalogosTab(api: api),
          ),
        if (widget.user.hasPermission('roles.ver'))
          _TabDef(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Roles',
            child: _RolesTab(api: api),
          ),
        if (widget.user.hasPermission('lugares_servicio.ver'))
          _TabDef(
            icon: Icons.place_outlined,
            label: 'Lugares',
            child: _LugaresTab(api: api),
          ),
        if (widget.user.hasPermission('eas.ver'))
          _TabDef(
            icon: Icons.location_city_outlined,
            label: 'EAS',
            child: _EasTab(api: api),
          ),
        if (widget.user.hasPermission('moviles.ver'))
          _TabDef(
            icon: Icons.directions_car_outlined,
            label: 'Moviles',
            child: _MovilesTab(api: api),
          ),
        if (widget.user.hasPermission('moviles.asignar'))
          _TabDef(
            icon: Icons.compare_arrows_outlined,
            label: 'Asignaciones',
            child: _AsignacionesTab(api: api),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppThm.bgClr,
        appBar: TopBarWdg(
          ttl: 'Administracion',
          user: widget.user,
          onUserChanged: widget.onUserChanged,
          onLogout: widget.onLogout,
          onNotifications: widget.onNotifications,
          leading: widget.showBack
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Salir',
                )
              : null,
        ),
        body: tabs.isEmpty
            ? const Center(child: Text('No tienes permisos de administración'))
            : Column(
                children: [
                  const SizedBox(height: 18),
                  TabBar(
                    isScrollable: true,
                    labelColor: AppThm.priClr,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: AppThm.secClr,
                    tabs: [
                      for (final tab in tabs)
                        Tab(icon: Icon(tab.icon), text: tab.label),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final tab in tabs) tab.child,
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  final Widget child;
  const _TabDef({required this.icon, required this.label, required this.child});
}

class _PersonalTab extends StatefulWidget {
  final AdmApi api;
  const _PersonalTab({required this.api});

  @override
  State<_PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<_PersonalTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.getPersonal();
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTable(
      title: 'Personal',
      subtitle: 'Cuenta institucional, datos personales y datos operativos.',
      future: future,
      columns: const ['Cedula', 'Nombres', 'Correo', 'Rol', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      rowBuilder: (item) => [
        _txt(item['cedula']),
        _txt('${item['apellidos'] ?? ''} ${item['nombres'] ?? ''}'.trim()),
        _txt(item['correo_institucional']),
        _txt(item['rol']),
        _StateChip(active: _active(item)),
        _Actions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          onReset: () => _reset(item),
          active: _active(item),
        ),
      ],
    );
  }

  void _reload() => setState(() => future = widget.api.getPersonal());

  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await _loadCatalogs(widget.api);
    final roles = await widget.api.getRoles();
    if (!mounted) return;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PersonalDialog(
        item: item,
        catalogs: catalogs,
        roles: roles,
      ),
    );
    if (data == null) return;
    if (!mounted) return;

    await _run(() async {
      if (item == null) {
        await widget.api.createPersonal(data);
      } else {
        await widget.api.updatePersonal(_id(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _run(() async {
      await widget.api.setPersonalActivo(_id(item), !_active(item));
      _reload();
    });
  }

  Future<void> _reset(Map<String, dynamic> item) async {
    final ok = await _confirm(
      context,
      'Restablecer contrasena',
      'La contrasena volvera a ser la fecha de nacimiento en formato ddmmaaaa.',
    );
    if (ok != true) return;
    if (!mounted) return;
    await _run(() => widget.api.resetPassword(_id(item)));
  }

  Future<void> _run(Future<void> Function() action) => _safeRun(context, action);
}

class _CatalogosTab extends StatefulWidget {
  final AdmApi api;
  const _CatalogosTab({required this.api});

  @override
  State<_CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<_CatalogosTab> {
  static const codigos = [
    'GRADOS',
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
    return _AsyncTable(
      title: 'Catalogos maestros',
      subtitle: 'Grados, areas, funciones, grupos, jornadas, distritos y tipos.',
      future: future,
      columns: const ['Codigo', 'Nombre', 'Orden', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      header: DropdownButtonFormField<String>(
        initialValue: codigo,
        decoration: const InputDecoration(
          labelText: 'Catalogo',
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
        _txt(item['codigo']),
        _txt(item['nombre']),
        _txt(item['orden']),
        _StateChip(active: _active(item, key: 'estado')),
        _Actions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          active: _active(item, key: 'estado'),
        ),
      ],
    );
  }

  void _reload() => setState(() => future = widget.api.getCatalogo(codigo));

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CatalogoDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      if (item == null) {
        await widget.api.createCatalogoDetalle(codigo, data);
      } else {
        await widget.api.updateCatalogoDetalle(_id(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _safeRun(context, () async {
      await widget.api.setCatalogoDetalleActivo(
        _id(item),
        !_active(item, key: 'estado'),
      );
      _reload();
    });
  }
}

class _RolesTab extends StatefulWidget {
  final AdmApi api;
  const _RolesTab({required this.api});

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.getRoles();
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncTable(
      title: 'Roles',
      subtitle: 'Matriz de permisos del sistema por rol institucional.',
      future: future,
      columns: const ['Nombre', 'Descripcion', 'Permisos', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      rowBuilder: (item) => [
        _txt(item['nombre']),
        _txt(item['descripcion']),
        _txt((item['permisos'] as List<dynamic>? ?? []).length),
        _StateChip(active: _active(item)),
        _Actions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          active: _active(item),
        ),
      ],
    );
  }

  void _reload() => setState(() => future = widget.api.getRoles());

  Future<void> _edit(Map<String, dynamic>? item) async {
    final permisos = await widget.api.getPermisos();
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RolDialog(item: item, permisos: permisos),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      if (item == null) {
        await widget.api.createRol(data);
      } else {
        await widget.api.updateRol(_id(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _safeRun(context, () async {
      await widget.api.setRolActivo(_id(item), !_active(item));
      _reload();
    });
  }
}

class _LugaresTab extends _CrudTab {
  const _LugaresTab({required super.api});

  @override
  State<_CrudTab> createState() => _LugarState();
}

class _EasTab extends _CrudTab {
  const _EasTab({required super.api});

  @override
  State<_CrudTab> createState() => _EasState();
}

class _MovilesTab extends _CrudTab {
  const _MovilesTab({required super.api});

  @override
  State<_CrudTab> createState() => _MovilState();
}

class _AsignacionesTab extends _CrudTab {
  const _AsignacionesTab({required super.api});

  @override
  State<_CrudTab> createState() => _AsignacionState();
}

abstract class _CrudTab extends StatefulWidget {
  final AdmApi api;
  const _CrudTab({required this.api});
}

class _LugarState extends State<_CrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getLugares();
  }

  @override
  Widget build(BuildContext context) => _AsyncTable(
        title: 'Lugares de servicio',
        subtitle: 'Puntos operativos organizados por distrito.',
        future: future,
        columns: const ['Nombre', 'Distrito', 'Tipo', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          _txt(item['nombre']),
          _txt(item['distrito']),
          _txt(item['tipo_servicio']),
          _StateChip(active: _active(item)),
          _Actions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            active: _active(item),
          ),
        ],
      );

  void _reload() => setState(() => future = widget.api.getLugares());
  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await _loadCatalogs(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LugarDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      item == null
          ? await widget.api.createLugar(data)
          : await widget.api.updateLugar(_id(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _safeRun(context, () async {
      await widget.api.setLugarActivo(_id(item), !_active(item));
      _reload();
    });
  }
}

class _EasState extends State<_CrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getEas();
  }

  @override
  Widget build(BuildContext context) => _AsyncTable(
        title: 'EAS',
        subtitle: 'Estaciones de Accion Segura disponibles para servicios.',
        future: future,
        columns: const ['Codigo', 'Nombre', 'Distrito', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          _txt(item['codigo']),
          _txt(item['nombre']),
          _txt(item['distrito']),
          _StateChip(active: _active(item)),
          _Actions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            active: _active(item),
          ),
        ],
      );

  void _reload() => setState(() => future = widget.api.getEas());
  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await _loadCatalogs(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EasDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      item == null
          ? await widget.api.createEas(data)
          : await widget.api.updateEas(_id(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _safeRun(context, () async {
      await widget.api.setEasActivo(_id(item), !_active(item));
      _reload();
    });
  }
}

class _MovilState extends State<_CrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getMoviles();
  }

  @override
  Widget build(BuildContext context) => _AsyncTable(
        title: 'Moviles',
        subtitle: 'Unidades, kilometraje y mantenimiento preventivo.',
        future: future,
        columns: const ['Movil', 'Tipo', 'Km', 'Prox. mant.', 'Alerta', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          _txt('${item['numero_movil'] ?? ''} ${item['placa'] ?? ''}'.trim()),
          _txt(item['tipo']),
          _txt(item['kilometraje_actual']),
          _txt(item['proximo_mantenimiento']),
          _AlertText(text: item['alerta_mantenimiento']?.toString()),
          _Actions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            active: _active(item),
          ),
        ],
      );

  void _reload() => setState(() => future = widget.api.getMoviles());
  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await _loadCatalogs(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MovilDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      item == null
          ? await widget.api.createMovil(data)
          : await widget.api.updateMovil(_id(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _safeRun(context, () async {
      await widget.api.setMovilActivo(_id(item), !_active(item));
      _reload();
    });
  }
}

class _AsignacionState extends State<_CrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getAsignaciones();
  }

  @override
  Widget build(BuildContext context) => _AsyncTable(
        title: 'Asignacion de moviles a EAS',
        subtitle: 'Historial de asignaciones con una sola asignacion activa por movil.',
        future: future,
        columns: const ['EAS', 'Movil', 'Fecha', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          _txt('${item['eas_codigo'] ?? ''} ${item['eas'] ?? ''}'.trim()),
          _txt('${item['numero_movil'] ?? ''} ${item['placa'] ?? ''}'.trim()),
          _txt(item['fecha_asignacion']),
          _StateChip(active: _active(item), label: item['estado']?.toString()),
          _Actions(onEdit: () => _edit(item), active: _active(item)),
        ],
      );

  void _reload() => setState(() => future = widget.api.getAsignaciones());
  Future<void> _edit(Map<String, dynamic>? item) async {
    final eas = await widget.api.getEas();
    final moviles = await widget.api.getMoviles();
    final estados = await widget.api.getCatalogo('ESTADOS_ASIGNACION_MOVIL');
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AsignacionDialog(
        item: item,
        eas: eas,
        moviles: moviles,
        estados: estados,
      ),
    );
    if (data == null) return;
    if (!mounted) return;
    await _safeRun(context, () async {
      item == null
          ? await widget.api.createAsignacion(data)
          : await widget.api.updateAsignacion(_id(item), data);
      _reload();
    });
  }
}

class _AsyncTable extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<List<Map<String, dynamic>>> future;
  final List<String> columns;
  final List<Widget> Function(Map<String, dynamic> item) rowBuilder;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final Widget? header;

  const _AsyncTable({
    required this.title,
    required this.subtitle,
    required this.future,
    required this.columns,
    required this.rowBuilder,
    required this.onRefresh,
    required this.onCreate,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                Expanded(child: PageTtlWdg(ttl: title, sub: subtitle)),
                IconButton.filledTonal(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            if (header != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: header!,
              ),
              const SizedBox(height: 12),
            ],
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              SizedBox(height: 260, child: Center(child: Text('${snapshot.error}')))
            else
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      for (final column in columns) DataColumn(label: Text(column)),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(cells: [
                          for (final cell in rowBuilder(item)) DataCell(cell),
                        ]),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onReset;
  final bool active;

  const _Actions({
    this.onEdit,
    this.onToggle,
    this.onReset,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        if (onToggle != null)
          IconButton(
            onPressed: onToggle,
            icon: Icon(active ? Icons.block_outlined : Icons.check_circle_outline),
            tooltip: active ? 'Inactivar' : 'Activar',
          ),
        if (onReset != null)
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.lock_reset_outlined),
            tooltip: 'Restablecer contrasena',
          ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final bool active;
  final String? label;
  const _StateChip({required this.active, this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label ?? (active ? 'Activo' : 'Inactivo')),
      backgroundColor: active
          ? AppThm.okClr.withValues(alpha: 0.12)
          : Colors.red.withValues(alpha: 0.10),
      labelStyle: TextStyle(
        color: active ? AppThm.okClr : Colors.red.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _AlertText extends StatelessWidget {
  final String? text;
  const _AlertText({this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const Text('Sin alerta');
    final vencido = text!.toLowerCase().contains('vencido');
    return Text(
      text!,
      style: TextStyle(
        color: vencido ? Colors.red.shade700 : Colors.orange.shade800,
        fontWeight: FontWeight.bold,
      ),
    );
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
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nuevo detalle' : 'Editar detalle',
        children: [
          _field(codigo, 'Codigo'),
          _field(nombre, 'Nombre'),
          _field(descripcion, 'Descripcion'),
          _field(orden, 'Orden', number: true),
        ],
        onSave: () => Navigator.pop(context, {
          'codigo': codigo.text.trim(),
          'nombre': nombre.text.trim(),
          'descripcion': descripcion.text.trim(),
          'orden': int.tryParse(orden.text) ?? 0,
        }),
      );
}

class _PersonalDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  final List<Map<String, dynamic>> roles;
  const _PersonalDialog({this.item, required this.catalogs, required this.roles});
  @override
  State<_PersonalDialog> createState() => _PersonalDialogState();
}

class _PersonalDialogState extends State<_PersonalDialog> {
  late final cedula = TextEditingController(text: _s('cedula'));
  late final nombres = TextEditingController(text: _s('nombres'));
  late final apellidos = TextEditingController(text: _s('apellidos'));
  late final correo = TextEditingController(text: _s('correo_institucional'));
  late final telefono = TextEditingController(text: _s('telefono'));
  late final nacimiento = TextEditingController(text: _date(_s('fecha_nacimiento')));
  int? gradoId;
  int? areaId;
  int? funcionId;
  int? grupoId;
  int? rotacionId;
  int? rolId;
  int? estadoId;

  @override
  void initState() {
    super.initState();
    gradoId = _int('grado_id') ?? _int('cargo_id');
    areaId = _int('area_id');
    funcionId = _int('funcion_operativa_id');
    grupoId = _int('grupo_id');
    rotacionId = _int('tipo_rotacion_id');
    rolId = _int('rol_id');
    estadoId = _int('estado_personal_id');
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Registrar personal' : 'Editar personal',
        children: [
          _field(cedula, 'Cedula'),
          _field(nombres, 'Nombres'),
          _field(apellidos, 'Apellidos'),
          _field(correo, 'Correo institucional'),
          _field(telefono, 'Telefono'),
          _field(nacimiento, 'Fecha nacimiento (yyyy-mm-dd)'),
          _drop('Grado', widget.catalogs['GRADOS'], gradoId, (v) => setState(() => gradoId = v)),
          _drop('Area', widget.catalogs['AREAS'], areaId, (v) => setState(() => areaId = v)),
          _drop('Funcion operativa', widget.catalogs['FUNCIONES_OPERATIVAS'], funcionId, (v) => setState(() => funcionId = v), optional: true),
          _drop('Grupo', widget.catalogs['GRUPOS'], grupoId, (v) => setState(() => grupoId = v)),
          _drop('Tipo rotacion', widget.catalogs['TIPOS_ROTACION'], rotacionId, (v) => setState(() => rotacionId = v), optional: true),
          _drop('Rol', widget.roles, rolId, (v) => setState(() => rolId = v)),
          _drop('Estado', widget.catalogs['ESTADOS_PERSONAL'], estadoId, (v) => setState(() => estadoId = v)),
        ],
        onSave: () => Navigator.pop(context, {
          'cedula': cedula.text.trim(),
          'nombres': nombres.text.trim(),
          'apellidos': apellidos.text.trim(),
          'correoInstitucional': correo.text.trim(),
          'telefono': telefono.text.trim(),
          'fechaNacimiento': nacimiento.text.trim(),
          'gradoId': gradoId,
          'areaId': areaId,
          'funcionOperativaId': funcionId,
          'grupoId': grupoId,
          'tipoRotacionId': rotacionId,
          'rolId': rolId,
          'estadoPersonalId': estadoId,
        }),
      );

  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
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
  late final selected = <String>{
    ...(widget.item?['permisos'] as List<dynamic>? ?? []).map((e) => e.toString()),
  };

  @override
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nuevo rol' : 'Editar rol',
        width: 680,
        children: [
          _field(nombre, 'Nombre'),
          _field(descripcion, 'Descripcion'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final permiso in widget.permisos)
                FilterChip(
                  selected: selected.contains(permiso['codigo']),
                  label: Text(permiso['codigo'].toString()),
                  onSelected: (value) => setState(() {
                    value
                        ? selected.add(permiso['codigo'].toString())
                        : selected.remove(permiso['codigo'].toString());
                  }),
                ),
            ],
          ),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
          'descripcion': descripcion.text.trim(),
          'permisos': selected.toList(),
        }),
      );
}

class _LugarDialog extends _BaseCatalogDialog {
  const _LugarDialog({super.item, required super.catalogs});
  @override
  State<_LugarDialog> createState() => _LugarDialogState();
}

class _LugarDialogState extends State<_LugarDialog> {
  late final nombre = TextEditingController(text: _s('nombre'));
  late final direccion = TextEditingController(text: _s('direccion'));
  late final obs = TextEditingController(text: _s('observacion'));
  int? distritoId;
  int? subunidadId;
  int? tipoId;
  @override
  void initState() {
    super.initState();
    distritoId = _int('distrito_id');
    subunidadId = _int('subunidad_operativa_id');
    tipoId = _int('tipo_servicio_id');
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nuevo lugar' : 'Editar lugar',
        children: [
          _field(nombre, 'Nombre'),
          _field(direccion, 'Direccion'),
          _drop('Distrito', widget.catalogs['DISTRITOS'], distritoId, (v) => setState(() => distritoId = v)),
          _drop('Subunidad', widget.catalogs['SUBUNIDADES_OPERATIVAS'], subunidadId, (v) => setState(() => subunidadId = v), optional: true),
          _drop('Tipo servicio', widget.catalogs['TIPOS_SERVICIO_LUGAR'], tipoId, (v) => setState(() => tipoId = v)),
          _field(obs, 'Observacion'),
        ],
        onSave: () => Navigator.pop(context, {
          'nombre': nombre.text.trim(),
          'direccion': direccion.text.trim(),
          'distritoId': distritoId,
          'subunidadOperativaId': subunidadId,
          'tipoServicioId': tipoId,
          'observacion': obs.text.trim(),
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
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
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nueva EAS' : 'Editar EAS',
        children: [
          _field(codigo, 'Codigo'),
          _field(nombre, 'Nombre'),
          _field(direccion, 'Direccion'),
          _drop('Distrito', widget.catalogs['DISTRITOS'], distritoId, (v) => setState(() => distritoId = v)),
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

class _MovilDialog extends _BaseCatalogDialog {
  const _MovilDialog({super.item, required super.catalogs});
  @override
  State<_MovilDialog> createState() => _MovilDialogState();
}

class _MovilDialogState extends State<_MovilDialog> {
  late final numero = TextEditingController(text: _s('numero_movil'));
  late final placa = TextEditingController(text: _s('placa'));
  late final km = TextEditingController(text: _s('kilometraje_actual', fallback: '0'));
  late final kmMant = TextEditingController(text: _s('kilometraje_ultimo_mantenimiento', fallback: '0'));
  late final obs = TextEditingController(text: _s('observacion'));
  int? tipoId;
  int? estadoId;
  @override
  void initState() {
    super.initState();
    tipoId = _int('tipo_movil_id');
    estadoId = _int('estado_movil_id');
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nuevo movil' : 'Editar movil',
        children: [
          _field(numero, 'Numero de movil'),
          _field(placa, 'Placa'),
          _drop('Tipo', widget.catalogs['TIPOS_MOVIL'], tipoId, (v) => setState(() => tipoId = v)),
          _field(km, 'Kilometraje actual', number: true),
          _field(kmMant, 'Kilometraje ultimo mantenimiento', number: true),
          _drop('Estado', widget.catalogs['ESTADOS_MOVIL'], estadoId, (v) => setState(() => estadoId = v)),
          _field(obs, 'Observacion'),
        ],
        onSave: () => Navigator.pop(context, {
          'numeroMovil': numero.text.trim(),
          'placa': placa.text.trim(),
          'tipoMovilId': tipoId,
          'kilometrajeActual': int.tryParse(km.text) ?? 0,
          'kilometrajeUltimoMantenimiento': int.tryParse(kmMant.text) ?? 0,
          'estadoMovilId': estadoId,
          'observacion': obs.text.trim(),
        }),
      );
  String _s(String key, {String fallback = ''}) => widget.item?[key]?.toString() ?? fallback;
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}

class _AsignacionDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> eas;
  final List<Map<String, dynamic>> moviles;
  final List<Map<String, dynamic>> estados;
  const _AsignacionDialog({this.item, required this.eas, required this.moviles, required this.estados});
  @override
  State<_AsignacionDialog> createState() => _AsignacionDialogState();
}

class _AsignacionDialogState extends State<_AsignacionDialog> {
  late final fecha = TextEditingController(text: _date(widget.item?['fecha_asignacion']?.toString() ?? DateTime.now().toIso8601String()));
  late final obs = TextEditingController(text: widget.item?['observacion']?.toString() ?? '');
  int? easId;
  int? movilId;
  int? estadoId;
  @override
  void initState() {
    super.initState();
    easId = int.tryParse(widget.item?['eas_id']?.toString() ?? '');
    movilId = int.tryParse(widget.item?['movil_id']?.toString() ?? '');
    estadoId = int.tryParse(widget.item?['estado_asignacion_id']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) => _FormDialog(
        title: widget.item == null ? 'Nueva asignacion' : 'Editar asignacion',
        children: [
          _drop('EAS', widget.eas, easId, (v) => setState(() => easId = v)),
          _drop('Movil', widget.moviles, movilId, (v) => setState(() => movilId = v), labelBuilder: (m) => '${m['numero_movil']} ${m['placa'] ?? ''}'),
          _field(fecha, 'Fecha asignacion (yyyy-mm-dd)'),
          _drop('Estado', widget.estados, estadoId, (v) => setState(() => estadoId = v)),
          _field(obs, 'Observacion'),
        ],
        onSave: () => Navigator.pop(context, {
          'easId': easId,
          'movilId': movilId,
          'fechaAsignacion': fecha.text.trim(),
          'estadoAsignacionId': estadoId,
          'observacion': obs.text.trim(),
        }),
      );
}

abstract class _BaseCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _BaseCatalogDialog({this.item, required this.catalogs});
}

class _FormDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final double width;

  const _FormDialog({
    required this.title,
    required this.children,
    required this.onSave,
    this.width = 540,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}

Widget _field(TextEditingController ctl, String label, {bool number = false}) {
  return TextField(
    controller: ctl,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

Widget _drop(
  String label,
  List<Map<String, dynamic>>? items,
  int? value,
  ValueChanged<int?> onChanged, {
  bool optional = false,
  String Function(Map<String, dynamic>)? labelBuilder,
}) {
  final data = items ?? [];
  final hasValue = data.any((item) => _id(item) == value);
  return DropdownButtonFormField<int>(
    initialValue: hasValue ? value : null,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      if (optional) const DropdownMenuItem<int>(value: null, child: Text('Sin asignar')),
      for (final item in data)
        DropdownMenuItem<int>(
          value: _id(item),
          child: Text(labelBuilder?.call(item) ?? item['nombre']?.toString() ?? item['codigo']?.toString() ?? '${_id(item)}'),
        ),
    ],
    onChanged: onChanged,
  );
}

Text _txt(Object? value) => Text(
      value?.toString() ?? '',
      overflow: TextOverflow.ellipsis,
    );

int _id(Map<String, dynamic> item) => int.tryParse(item['id']?.toString() ?? '') ?? 0;

bool _active(Map<String, dynamic> item, {String key = 'activo'}) {
  final value = item[key];
  return value == true || value == 1 || value?.toString() == '1';
}

String _date(String value) {
  if (value.length >= 10) return value.substring(0, 10);
  return value;
}

Future<Map<String, List<Map<String, dynamic>>>> _loadCatalogs(AdmApi api) async {
  const codes = [
    'GRADOS',
    'AREAS',
    'FUNCIONES_OPERATIVAS',
    'GRUPOS',
    'JORNADAS',
    'TIPOS_ROTACION',
    'JORNADAS',
    'ESTADOS_PERSONAL',
    'DISTRITOS',
    'SUBUNIDADES_OPERATIVAS',
    'TIPOS_SERVICIO_LUGAR',
    'TIPOS_MOVIL',
    'ESTADOS_MOVIL',
  ];
  final result = <String, List<Map<String, dynamic>>>{};
  for (final code in codes) {
    try {
      result[code] = await api.getCatalogo(code);
    } catch (_) {
      result[code] = [];
    }
  }
  return result;
}

Future<void> _safeRun(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Operacion realizada correctamente')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

Future<bool?> _confirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
      ],
    ),
  );
}
