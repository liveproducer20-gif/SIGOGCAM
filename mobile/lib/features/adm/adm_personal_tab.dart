import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class PersonalTab extends AdmCrudTab {
  final int tabIndex;
  const PersonalTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _search = '';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as PersonalTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await widget.api.getPersonal(page: _page, search: _search);
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
      title: 'Personal',
      subtitle: 'Cuenta institucional, datos personales y datos operativos.',
      future: _future,
      columns: const ['Cédula', 'Nombres', 'Correo', 'Grado', 'Rol', 'Estado', 'Acciones'],
      onRefresh: _reload,
      onCreate: () => _edit(null),
      total: _total,
      currentPage: _page,
      totalPages: _totalPages,
      onPageChanged: _onPageChanged,
      onSearch: _onSearch,
      searchHint: 'Buscar personal...',
      rowBuilder: (item) => [
        admText(item['cedula']),
        admText('${item['apellidos'] ?? ''} ${item['nombres'] ?? ''}'.trim()),
        admText(item['correo_institucional']),
        admText(item['grado']),
        admText(item['rol']),
        AdmStateChip(active: admIsActive(item)),
        AdmActions(
          onEdit: () => _edit(item),
          onToggle: () => _toggle(item),
          onReset: () => _reset(item),
          onDelete: () => _confirmDelete(
            item,
            'personal ${item['nombres']} ${item['apellidos']}'.trim(),
            () => widget.api.deletePersonal(admId(item)),
          ),
          active: admIsActive(item),
        ),
      ],
    );
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final results = await Future.wait([
      CatalogCache.instance.getOrLoad(widget.api),
      widget.api.getRolesList(),
      widget.api.getGrados(),
    ]);
    final catalogs = results[0] as Map<String, List<Map<String, dynamic>>>;
    final roles = results[1] as List<Map<String, dynamic>>;
    final grados = results[2] as List<Map<String, dynamic>>;
    if (!mounted) return;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PersonalDialog(
        item: item,
        catalogs: catalogs,
        roles: roles,
        grados: grados,
      ),
    );
    if (data == null) return;
    if (!mounted) return;

    await _run(() async {
      if (item == null) {
        await widget.api.createPersonal(data);
      } else {
        await widget.api.updatePersonal(admId(item), data);
      }
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await _run(() async {
      await widget.api.setPersonalActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _reset(Map<String, dynamic> item) async {
    final ok = await admConfirm(
      context,
      'Restablecer contraseña',
      'La contraseña volverá a ser la fecha de nacimiento en formato ddmmaaaa.',
    );
    if (ok != true) return;
    if (!mounted) return;
    await _run(() => widget.api.resetPassword(admId(item)));
  }

  Future<void> _run(Future<void> Function() action) => admSafeRun(context, action);

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

class _PersonalDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> grados;
  const _PersonalDialog({this.item, required this.catalogs, required this.roles, required this.grados});
  @override
  State<_PersonalDialog> createState() => _PersonalDialogState();
}

class _PersonalDialogState extends State<_PersonalDialog> {
  late final cedula = TextEditingController(text: _s('cedula'));
  late final nombres = TextEditingController(text: _s('nombres'));
  late final apellidos = TextEditingController(text: _s('apellidos'));
  late final correo = TextEditingController(text: _s('correo_institucional'));
  late final telefono = TextEditingController(text: _s('telefono'));
  late final nacimiento = TextEditingController(text: admFormatDate(_s('fecha_nacimiento')));
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
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Registrar personal' : 'Editar personal',
        children: [
          admField(cedula, 'Cédula *'),
          admField(nombres, 'Nombres *'),
          admField(apellidos, 'Apellidos *'),
          admField(correo, 'Correo institucional *'),
          admField(telefono, 'Teléfono'),
          admField(nacimiento, 'Fecha de nacimiento (yyyy-mm-dd)'),
          admDropdown('Grado *', widget.grados, gradoId, (v) => setState(() => gradoId = v)),
          admDropdown('Area', widget.catalogs['AREAS'], areaId, (v) => setState(() => areaId = v), optional: true),
          admDropdown('Funcion operativa', widget.catalogs['FUNCIONES_OPERATIVAS'], funcionId, (v) => setState(() => funcionId = v), optional: true),
          admDropdown('Grupo', widget.catalogs['GRUPOS'], grupoId, (v) => setState(() => grupoId = v), optional: true),
          admDropdown('Tipo rotacion', widget.catalogs['TIPOS_ROTACION'], rotacionId, (v) => setState(() => rotacionId = v), optional: true),
          admDropdown('Rol', widget.roles, rolId, (v) => setState(() => rolId = v), optional: true),
          admDropdown('Estado', widget.catalogs['ESTADOS_PERSONAL'], estadoId, (v) => setState(() => estadoId = v), optional: true),
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
