import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class PersonalTab extends AdmCrudTab {
  final int tabIndex;
  final AppUser user;
  const PersonalTab({
    super.key,
    required super.api,
    required this.user,
    this.tabIndex = 0,
  });

  @override
  State<AdmCrudTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<AdmCrudTab>
    with AdmLazyTabMixin<AdmCrudTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _all = const [];
  bool _loading = false;
  bool _busy = false;
  Object? _error;
  String _search = '';
  String _status = 'Todos';
  String _role = 'Todos';
  String _area = 'Todos';
  String _grade = 'Todos';
  int _page = 1;
  int _pageSize = 10;

  PersonalTab get tab => widget as PersonalTab;
  bool get _canCreate => tab.user.hasPermission('personal.crear');
  bool get _canEdit => tab.user.hasPermission('personal.editar');
  bool get _canChangeState =>
      tab.user.hasAnyPermission(['personal.editar', 'personal.editar_estado']);

  @override
  void initState() {
    super.initState();
    initLazy(tab.tabIndex, _load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.getPersonalList();
      if (!mounted) return;
      setState(() => _all = data);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _search.toLowerCase().trim();
    return _all.where((item) {
      final haystack = [
        item['cedula'],
        item['nombres'],
        item['apellidos'],
        item['correo_institucional'],
        item['rol'],
        item['area'],
        item['grado'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (_status != 'Todos' && _statusOf(item) != _status) return false;
      if (_role != 'Todos' && _text(item['rol']) != _role) return false;
      if (_area != 'Todos' && _text(item['area']) != _area) return false;
      if (_grade != 'Todos' && _text(item['grado']) != _grade) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _visible {
    final filtered = _filtered;
    final start = (_page - 1) * _pageSize;
    if (start >= filtered.length) return const [];
    return filtered.skip(start).take(_pageSize).toList();
  }

  int get _pages => (_filtered.length / _pageSize).ceil().clamp(1, 999999);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 720 ? 16 : 28,
              18,
              MediaQuery.sizeOf(context).width < 720 ? 16 : 28,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                _summary(),
                const SizedBox(height: 18),
                if (_error != null && _all.isEmpty)
                  _ErrorState(error: _error!, onRetry: _load)
                else ...[
                  _filters(),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final table = _table();
                      final side = _PersonalSide(
                        items: _all,
                        filtered: _filtered,
                        status: _status,
                        role: _role,
                        area: _area,
                        grade: _grade,
                        onRole: (v) => _setFilter(role: v),
                        onArea: (v) => _setFilter(area: v),
                        onGrade: (v) => _setFilter(grade: v),
                        onClearStatus: () => _setFilter(status: 'Todos'),
                        onClearRole: () => _setFilter(role: 'Todos'),
                        onClearArea: () => _setFilter(area: 'Todos'),
                        onClearGrade: () => _setFilter(grade: 'Todos'),
                        onClearAll: _clearFilters,
                        onRecent: _clearFilters,
                      );
                      if (constraints.maxWidth < 1180) {
                        return Column(
                          children: [table, const SizedBox(height: 16), side],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 8, child: table),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: side),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_busy) const Positioned.fill(child: _BlockingLoad()),
      ],
    );
  }

  Widget _header() => LayoutBuilder(
    builder: (context, constraints) {
      final buttons = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Actualizar'),
          ),
          if (tab.user.hasPermission('personal.ver'))
            OutlinedButton.icon(
              onPressed: _filtered.isEmpty ? null : _showExportMenu,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Exportar'),
            ),
          if (_canCreate)
            FilledButton.icon(
              onPressed: _busy ? null : () => _edit(null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo personal'),
            ),
        ],
      );
      final title = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal', style: AdmTokens.h1),
          SizedBox(height: 4),
          Text(
            'Gestión institucional del personal operativo y administrativo.',
            style: AdmTokens.subtitle,
          ),
        ],
      );
      if (constraints.maxWidth < 760) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 12), buttons],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: title),
          buttons,
        ],
      );
    },
  );

  Widget _summary() {
    final total = _all.length;
    final active = _all.where(admIsActive).length;
    final administrative = _all.where(_isAdministrative).length;
    final operational = total - administrative;
    return AdminSummaryRow(
      cards: [
        AdminSummaryCardData(
          icon: Icons.groups_rounded,
          value: '$total',
          label: 'Registros en total',
          color: AdmTokens.primary,
        ),
        AdminSummaryCardData(
          icon: Icons.verified_user_rounded,
          value: '$active · ${_percent(active, total)}',
          label: 'Personal activo',
          color: AdmTokens.success,
        ),
        AdminSummaryCardData(
          icon: Icons.manage_accounts_rounded,
          value: '$administrative · ${_percent(administrative, total)}',
          label: 'Administrativos',
          color: const Color(0xFFF59E0B),
        ),
        AdminSummaryCardData(
          icon: Icons.local_police_rounded,
          value: '$operational · ${_percent(operational, total)}',
          label: 'Operativos',
          color: const Color(0xFF0284C7),
        ),
      ],
    );
  }

  Widget _filters() => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 800 ? constraints.maxWidth : 190.0;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: constraints.maxWidth < 800 ? constraints.maxWidth : 330,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar...',
                  isDense: true,
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      setState(() {
                        _search = value;
                        _page = 1;
                      });
                    }
                  });
                },
              ),
            ),
            _filter(
              width,
              'Estado',
              ['Todos', 'Activo', 'Inactivo', 'Vacaciones', 'Permiso'],
              _status,
              (v) => _setFilter(status: v),
            ),
            _filter(
              width,
              'Rol',
              ['Todos', ..._values('rol')],
              _role,
              (v) => _setFilter(role: v),
            ),
            _filter(
              width,
              'Área',
              ['Todos', ..._values('area')],
              _area,
              (v) => _setFilter(area: v),
            ),
            _filter(
              width,
              'Grado',
              ['Todos', ..._values('grado')],
              _grade,
              (v) => _setFilter(grade: v),
            ),
            OutlinedButton.icon(
              onPressed: _hasFilters ? _clearFilters : null,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(
                'Limpiar${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}',
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _filter(
    double width,
    String label,
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : 'Todos',
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );

  Widget _table() => LayoutBuilder(
    builder: (context, constraints) => Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_loading && _all.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (_loading && _all.isEmpty)
            const _TableSkeleton()
          else if (_visible.isEmpty)
            const SizedBox(height: 280, child: _EmptyState())
          else if (constraints.maxWidth < 720)
            _mobileList()
          else
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AdmTokens.primary),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  dataRowMinHeight: 66,
                  dataRowMaxHeight: 76,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('PERSONAL')),
                    DataColumn(label: Text('CÉDULA')),
                    DataColumn(label: Text('CORREO')),
                    DataColumn(label: Text('GRADO')),
                    DataColumn(label: Text('ROL')),
                    DataColumn(label: Text('ÁREA')),
                    DataColumn(label: Text('ESTADO')),
                    DataColumn(label: Text('EN INSTITUCIÓN')),
                    DataColumn(label: Text('ÚLTIMO ACCESO')),
                    DataColumn(label: Text('ACCIONES')),
                  ],
                  rows: _visible.map(_row).toList(),
                ),
              ),
            ),
          _pagination(),
        ],
      ),
    ),
  );

  Widget _mobileList() => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(12),
    itemCount: _visible.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final item = _visible[index];
      return Material(
        color: AdmTokens.grey100,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetails(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(item: item),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AdmTokens.grey800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _text(
                              item['correo_institucional'],
                              fallback: 'Sin correo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdmTokens.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: _statusOf(item)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Badge(
                      icon: Icons.shield_outlined,
                      label: _text(item['grado'], fallback: 'Sin grado'),
                      color: AdmTokens.primary,
                    ),
                    _Badge(
                      label: _text(item['rol'], fallback: 'Sin rol'),
                      color: const Color(0xFF7C3AED),
                    ),
                    _Badge(
                      label: _text(item['area'], fallback: 'Sin área'),
                      color: AdmTokens.grey600,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cédula: ${_text(item['cedula'], fallback: 'No registrada')}',
                        style: AdmTokens.bodySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showDetails(item),
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: 'Ver detalle',
                    ),
                    if (_canEdit)
                      IconButton(
                        onPressed: () => _edit(item),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  DataRow _row(Map<String, dynamic> item) {
    final warnings = <String>[
      if (_text(item['rol']).isEmpty) 'Sin rol',
      if (_text(item['area']).isEmpty) 'Sin área',
      if (_text(item['grado']).isEmpty || _text(item['grado']) == 'SIN GRADO')
        'Sin grado',
      if (!admIsActive(item)) 'Usuario inactivo',
    ];
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(item: item),
              const SizedBox(width: 10),
              SizedBox(
                width: 145,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AdmTokens.grey800,
                      ),
                    ),
                    if (warnings.isNotEmpty)
                      Tooltip(
                        message: warnings.join(' · '),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFF59E0B),
                          size: 17,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(_text(item['cedula']))),
        DataCell(
          SizedBox(
            width: 190,
            child: Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 16,
                  color: AdmTokens.grey500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _text(item['correo_institucional']),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          _Badge(
            icon: Icons.shield_outlined,
            label: _text(item['grado'], fallback: 'Sin grado'),
            color: AdmTokens.primary,
          ),
        ),
        DataCell(
          _Badge(
            label: _text(item['rol'], fallback: 'Sin rol'),
            color: const Color(0xFF7C3AED),
          ),
        ),
        DataCell(
          _Badge(
            label: _text(item['area'], fallback: 'Sin área'),
            color: AdmTokens.grey600,
          ),
        ),
        DataCell(_StatusBadge(status: _statusOf(item))),
        DataCell(Text(_tenure(item['fecha_ingreso']))),
        DataCell(Text(_lastAccess(item))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showDetails(item),
                icon: const Icon(Icons.visibility_outlined, size: 19),
                tooltip: 'Ver',
              ),
              if (_canEdit)
                IconButton(
                  onPressed: () => _edit(item),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  tooltip: 'Editar',
                ),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                itemBuilder: (_) => [
                  if (_canChangeState)
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(admIsActive(item) ? 'Desactivar' : 'Activar'),
                    ),
                  if (_canEdit)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                ],
                onSelected: (v) {
                  if (v == 'toggle') _toggle(item);
                  if (v == 'delete') _confirmDelete(item);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pagination() => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: constraints.maxWidth < 720
            ? WrapAlignment.center
            : WrapAlignment.end,
        children: [
          SizedBox(
            width: constraints.maxWidth < 720 ? constraints.maxWidth : 330,
            child: Text(
              'Mostrando ${_visible.isEmpty ? 0 : ((_page - 1) * _pageSize) + 1} a ${((_page - 1) * _pageSize + _visible.length)} de ${_filtered.length} registros',
              textAlign: constraints.maxWidth < 720
                  ? TextAlign.center
                  : TextAlign.start,
              style: AdmTokens.bodySmall,
            ),
          ),
          IconButton(
            onPressed: _page > 1 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AdmTokens.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$_page / $_pages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _page < _pages ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _pageSize,
            underline: const SizedBox.shrink(),
            items: const [10, 25, 50]
                .map(
                  (e) =>
                      DropdownMenuItem(value: e, child: Text('$e por página')),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _pageSize = v;
                  _page = 1;
                });
              }
            },
          ),
        ],
      ),
    ),
  );

  void _setFilter({
    String? status,
    String? role,
    String? area,
    String? grade,
  }) => setState(() {
    if (status != null) _status = status;
    if (role != null) _role = role;
    if (area != null) _area = area;
    if (grade != null) _grade = grade;
    _page = 1;
  });

  void _clearFilters() {
    _searchController.clear();
    _search = '';
    _status = _role = _area = _grade = 'Todos';
    _page = 1;
    if (mounted) setState(() {});
  }

  bool get _hasFilters => _search.isNotEmpty || _activeFilterCount > 0;
  int get _activeFilterCount =>
      [_status, _role, _area, _grade].where((v) => v != 'Todos').length;
  List<String> _values(String key) =>
      _all.map((e) => _text(e[key])).where((e) => e.isNotEmpty).toSet().toList()
        ..sort();

  Future<void> _showExportMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Exportar personal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_view_outlined),
              title: const Text('Excel'),
              subtitle: const Text('Archivo compatible con Excel'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              subtitle: const Text('Abrir impresión / guardar como PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'pdf') {
      final ok = await printAdminPage();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La impresión PDF está disponible en la versión web.',
            ),
          ),
        );
      }
      return;
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
    final rows = _visible;
    final csv = <String>[
      'Cédula,Nombres,Correo,Grado,Rol,Área,Estado,Fecha ingreso',
      ...rows.map(
        (i) => [
          i['cedula'],
          _fullName(i),
          i['correo_institucional'],
          i['grado'],
          i['rol'],
          i['area'],
          _statusOf(i),
          i['fecha_ingreso'],
        ].map(_csv).join(','),
      ),
    ].join('\r\n');
    final path = await exportAdminCsv(
      csv,
      'PERSONAL_SIGOGCAM_$stamp.${choice == 'excel' ? 'xls' : 'csv'}',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Archivo generado: $path')));
    }
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    setState(() => _busy = true);
    try {
      final results = await Future.wait([
        CatalogCache.instance.getOrLoad(widget.api),
        widget.api.getRolesList(),
        widget.api.getGrados(),
      ]);
      if (!mounted) return;
      setState(() => _busy = false);
      final data = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _PersonalDialog(
          item: item,
          catalogs: results[0] as Map<String, List<Map<String, dynamic>>>,
          roles: results[1] as List<Map<String, dynamic>>,
          grados: results[2] as List<Map<String, dynamic>>,
        ),
      );
      if (data == null || !mounted) return;
      await admSafeRun(context, () async {
        if (item == null) {
          await widget.api.createPersonal(data);
        } else {
          await widget.api.updatePersonal(admId(item), data);
        }
        await _load();
      });
      if (item == null && mounted) {
        await _showInitialCredentials(
          correo: data['correoInstitucional']?.toString() ?? '',
          cedula: data['cedula']?.toString() ?? '',
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) =>
      admSafeRun(context, () async {
        await widget.api.setPersonalActivo(admId(item), !admIsActive(item));
        await _load();
      });
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await admConfirm(
      context,
      'Eliminar personal',
      '¿Eliminar a ${_fullName(item)}?',
    );
    if (ok == true && mounted) {
      await admSafeRun(context, () async {
        await widget.api.deletePersonal(admId(item));
        await _load();
      });
    }
  }

  Future<void> _showDetails(Map<String, dynamic> item) => showDialog<void>(
    context: context,
    builder: (_) => _PersonalDetail(item: item),
  );
  Future<void> _showInitialCredentials({
    required String correo,
    required String cedula,
  }) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.verified_user_rounded, color: AdmTokens.success),
      title: const Text('Usuario registrado correctamente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('El nuevo personal ya puede iniciar sesión con:'),
          const SizedBox(height: 16),
          SelectableText('Usuario: $correo'),
          const SizedBox(height: 10),
          SelectableText('Contraseña inicial: $cedula'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _PersonalSide extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> filtered;
  final String status, role, area, grade;
  final ValueChanged<String> onRole, onArea, onGrade;
  final VoidCallback onClearStatus,
      onClearRole,
      onClearArea,
      onClearGrade,
      onClearAll,
      onRecent;
  const _PersonalSide({
    required this.items,
    required this.filtered,
    required this.status,
    required this.role,
    required this.area,
    required this.grade,
    required this.onRole,
    required this.onArea,
    required this.onGrade,
    required this.onClearStatus,
    required this.onClearRole,
    required this.onClearArea,
    required this.onClearGrade,
    required this.onClearAll,
    required this.onRecent,
  });

  @override
  Widget build(BuildContext context) {
    final roles = _counts(items, 'rol');
    final areas = _counts(items, 'area');
    final grades = _counts(items, 'grado');
    final recent = [...items]
      ..sort(
        (a, b) =>
            _date(b['fecha_ingreso']).compareTo(_date(a['fecha_ingreso'])),
      );
    return Column(
      children: [
        _SideCard(
          title: 'Personal por rol',
          child: Column(
            children: [
              SizedBox(
                height: 104,
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: items.isEmpty
                                ? 0
                                : filtered.length / items.length,
                            strokeWidth: 12,
                            backgroundColor: AdmTokens.grey100,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${items.length}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text('Total', style: AdmTokens.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: roles.entries
                            .take(4)
                            .map(
                              (e) => _metric(
                                e.key,
                                e.value,
                                items.length,
                                () => onRole(e.key),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onRole('Todos'),
                child: const Text('Ver detalle completo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SideCard(
          title: 'Personal por área',
          child: Column(
            children: [
              ...areas.entries
                  .take(5)
                  .map(
                    (e) =>
                        _bar(e.key, e.value, items.length, () => onArea(e.key)),
                  ),
              TextButton(
                onPressed: () => onArea('Todos'),
                child: const Text('Ver todas las áreas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SideCard(
          title: 'Personal reciente',
          child: Column(
            children: [
              ...recent
                  .take(4)
                  .map(
                    (i) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: _Avatar(item: i, small: true),
                      title: Text(
                        _fullName(i),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_text(i['grado'], fallback: 'Sin grado')),
                      trailing: Text(
                        _shortDate(i['fecha_ingreso']),
                        style: AdmTokens.bodySmall,
                      ),
                    ),
                  ),
              TextButton(
                onPressed: onRecent,
                child: const Text('Ver todo el personal reciente'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SideCard(
          title: 'Distribución por grado',
          child: Column(
            children: [
              ...grades.entries
                  .take(7)
                  .map(
                    (e) => _metric(
                      e.key,
                      e.value,
                      items.length,
                      () => onGrade(e.key),
                    ),
                  ),
              TextButton(
                onPressed: () => onGrade('Todos'),
                child: const Text('Ver jerarquía completa'),
              ),
            ],
          ),
        ),
        if ([status, role, area, grade].any((v) => v != 'Todos')) ...[
          const SizedBox(height: 12),
          _SideCard(
            title: 'Filtros activos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status != 'Todos')
                  InputChip(
                    label: Text('Estado: $status'),
                    onDeleted: onClearStatus,
                  ),
                if (role != 'Todos')
                  InputChip(label: Text('Rol: $role'), onDeleted: onClearRole),
                if (area != 'Todos')
                  InputChip(label: Text('Área: $area'), onDeleted: onClearArea),
                if (grade != 'Todos')
                  InputChip(
                    label: Text('Grado: $grade'),
                    onDeleted: onClearGrade,
                  ),
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonalDetail extends StatelessWidget {
  final Map<String, dynamic> item;
  const _PersonalDetail({required this.item});
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(12),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 760,
        maxHeight: MediaQuery.sizeOf(context).height - 24,
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  _Avatar(item: item, large: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName(item), style: AdmTokens.h2),
                        const SizedBox(height: 5),
                        _StatusBadge(status: _statusOf(item)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Información'),
                Tab(text: 'Datos operativos'),
                Tab(text: 'Historial'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DetailGrid(
                    values: {
                      'Cédula': item['cedula'],
                      'Correo institucional': item['correo_institucional'],
                      'Teléfono': item['telefono'],
                      'Fecha de nacimiento': _shortDate(
                        item['fecha_nacimiento'],
                      ),
                      'Fecha de ingreso': _shortDate(item['fecha_ingreso']),
                      'Tiempo en institución': _tenure(item['fecha_ingreso']),
                    },
                  ),
                  _DetailGrid(
                    values: {
                      'Área': item['area'],
                      'Rol': item['rol'],
                      'Grado': item['grado'],
                      'Estado': _statusOf(item),
                      'Grupo': item['grupo'],
                      'Jornada': item['jornada'],
                      'Tipo de rotación': item['tipo_rotacion'],
                    },
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Los historiales de asignaciones, servicios, cartillas y eventos no están incluidos en la respuesta actual del endpoint de Personal.',
                        textAlign: TextAlign.center,
                        style: AdmTokens.subtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailGrid extends StatelessWidget {
  final Map<String, Object?> values;
  const _DetailGrid({required this.values});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 14 : 24),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: values.entries
            .map(
              (e) => Container(
                width: constraints.maxWidth < 500
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 14) / 2,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdmTokens.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: AdmTokens.bodySmall),
                    const SizedBox(height: 5),
                    Text(
                      _text(e.value, fallback: 'No registrado'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _PersonalDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  final List<Map<String, dynamic>> roles, grados;
  const _PersonalDialog({
    this.item,
    required this.catalogs,
    required this.roles,
    required this.grados,
  });
  @override
  State<_PersonalDialog> createState() => _PersonalDialogState();
}

class _PersonalDialogState extends State<_PersonalDialog> {
  final formKey = GlobalKey<FormState>();
  late final cedula = TextEditingController(text: _s('cedula'));
  late final nombres = TextEditingController(text: _s('nombres'));
  late final apellidos = TextEditingController(text: _s('apellidos'));
  late final correo = TextEditingController(text: _s('correo_institucional'));
  late final telefono = TextEditingController(text: _s('telefono'));
  late final nacimiento = TextEditingController(
    text: admFormatDate(_s('fecha_nacimiento')),
  );
  int? gradoId, areaId, funcionId, grupoId, rotacionId, rolId, estadoId;
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
  void dispose() {
    for (final c in [
      cedula,
      nombres,
      apellidos,
      correo,
      telefono,
      nacimiento,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: AdmFormDialog(
      title: widget.item == null ? 'Registrar personal' : 'Editar personal',
      children: [
        admField(cedula, 'Cédula *'),
        admField(nombres, 'Nombres *'),
        admField(apellidos, 'Apellidos *'),
        admField(correo, 'Correo institucional *'),
        admField(telefono, 'Teléfono'),
        admField(nacimiento, 'Fecha de nacimiento (yyyy-mm-dd)'),
        admDropdown(
          'Grado *',
          widget.grados,
          gradoId,
          (v) => setState(() => gradoId = v),
        ),
        admDropdown(
          'Área',
          widget.catalogs['AREAS'],
          areaId,
          (v) => setState(() => areaId = v),
          optional: true,
        ),
        admDropdown(
          'Función operativa',
          widget.catalogs['FUNCIONES_OPERATIVAS'],
          funcionId,
          (v) => setState(() => funcionId = v),
          optional: true,
        ),
        admDropdown(
          'Grupo',
          widget.catalogs['GRUPOS'],
          grupoId,
          (v) => setState(() => grupoId = v),
          optional: true,
        ),
        admDropdown(
          'Tipo rotación',
          widget.catalogs['TIPOS_ROTACION'],
          rotacionId,
          (v) => setState(() => rotacionId = v),
          optional: true,
        ),
        admDropdown(
          'Rol',
          widget.roles,
          rolId,
          (v) => setState(() => rolId = v),
          optional: true,
        ),
        admDropdown(
          'Estado',
          widget.catalogs['ESTADOS_PERSONAL'],
          estadoId,
          (v) => setState(() => estadoId = v),
          optional: true,
        ),
      ],
      onSave: () {
        if (cedula.text.trim().length != 10 ||
            nombres.text.trim().isEmpty ||
            apellidos.text.trim().isEmpty ||
            !correo.text.contains('@') ||
            gradoId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Complete cédula, nombres, apellidos, correo y grado con datos válidos.',
              ),
            ),
          );
          return;
        }
        Navigator.pop(context, {
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
        });
      },
    ),
  );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}

class _Avatar extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool small, large;
  const _Avatar({required this.item, this.small = false, this.large = false});
  @override
  Widget build(BuildContext context) {
    final size = large
        ? 64.0
        : small
        ? 34.0
        : 42.0;
    final url = _text(item['foto_perfil_url']).isNotEmpty
        ? _text(item['foto_perfil_url'])
        : _text(item['fotoPerfilUrl']);
    final initials =
        '${_text(item['nombres']).isEmpty ? '' : _text(item['nombres'])[0]}${_text(item['apellidos']).isEmpty ? '' : _text(item['apellidos'])[0]}'
            .toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _avatarColor(_fullName(item)),
      foregroundImage: url.isEmpty ? null : NetworkImage(url),
      onForegroundImageError: url.isEmpty ? null : (_, _) {},
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: large ? 20 : 13,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  const _Badge({required this.label, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 125),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Activo' => AdmTokens.success,
      'Vacaciones' => const Color(0xFF0284C7),
      'Permiso' => const Color(0xFFF59E0B),
      _ => AdmTokens.grey500,
    };
    return _Badge(label: status, color: color);
  }
}

class _SideCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SideCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AdmTokens.grey800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _BlockingLoad extends StatelessWidget {
  const _BlockingLoad();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white70,
    child: const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Cargando datos...'),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 360,
    child: Column(
      children: List.generate(
        5,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: AdmTokens.grey100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_search_outlined, size: 48, color: AdmTokens.grey400),
        SizedBox(height: 12),
        Text('No se encontraron registros', style: AdmTokens.h2),
        SizedBox(height: 4),
        Text(
          'Prueba con otros criterios de búsqueda.',
          style: AdmTokens.subtitle,
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text('No pudimos cargar el personal', style: AdmTokens.h2),
          const SizedBox(height: 6),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: AdmTokens.subtitle,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

Map<String, int> _counts(List<Map<String, dynamic>> items, String key) {
  final result = <String, int>{};
  for (final i in items) {
    final v = _text(i[key], fallback: 'Sin asignar');
    result[v] = (result[v] ?? 0) + 1;
  }
  final entries = result.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

Widget _metric(String label, int value, int total, VoidCallback tap) => InkWell(
  onTap: tap,
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          '$value (${_percent(value, total)})',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  ),
);
Widget _bar(String label, int value, int total, VoidCallback tap) => InkWell(
  onTap: tap,
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total == 0 ? 0 : value / total,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    ),
  ),
);
BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AdmTokens.grey200),
  boxShadow: AdmTokens.cardShadow,
);
String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
}

String _fullName(Map<String, dynamic> i) =>
    _text(i['nombre_completo']).isNotEmpty
    ? _text(i['nombre_completo'])
    : '${_text(i['apellidos'])} ${_text(i['nombres'])}'.trim();
bool _isAdministrative(Map<String, dynamic> i) {
  final r = _text(i['rol']).toLowerCase();
  final a = _text(i['area']).toLowerCase();
  return r.contains('admin') || r.contains('auditor') || a.contains('admin');
}

String _statusOf(Map<String, dynamic> i) {
  final value = _text(i['estado_personal']).toLowerCase();
  if (value.contains('vacacion')) return 'Vacaciones';
  if (value.contains('permiso')) return 'Permiso';
  return admIsActive(i) ? 'Activo' : 'Inactivo';
}

String _percent(int part, int total) =>
    total == 0 ? '0%' : '${(part * 100 / total).toStringAsFixed(1)}%';
DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime(1900);
String _shortDate(Object? value) {
  final d = DateTime.tryParse(value?.toString() ?? '');
  return d == null
      ? 'No disponible'
      : '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

String _tenure(Object? value) {
  final d = DateTime.tryParse(value?.toString() ?? '');
  if (d == null) return 'No disponible';
  final days = DateTime.now().difference(d).inDays;
  if (days >= 365) return '${days ~/ 365} año${days ~/ 365 == 1 ? '' : 's'}';
  if (days >= 30) return '${days ~/ 30} mes${days ~/ 30 == 1 ? '' : 'es'}';
  return '$days día${days == 1 ? '' : 's'}';
}

String _lastAccess(Map<String, dynamic> i) {
  final value = i['ultimo_acceso'] ?? i['ultimoAcceso'];
  return value == null ? 'No disponible' : _shortDate(value);
}

String _csv(Object? value) =>
    '"${(value?.toString() ?? '').replaceAll('"', '""')}"';
String _two(int n) => n.toString().padLeft(2, '0');
Color _avatarColor(String seed) {
  const colors = [
    Color(0xFF1D4ED8),
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFFB45309),
    Color(0xFF0369A1),
  ];
  return colors[seed.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length];
}
