import 'dart:async';

import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class CatalogosTab extends AdmCrudTab {
  final int tabIndex;
  const CatalogosTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<AdmCrudTab>
    with AdmLazyTabMixin<AdmCrudTab> {
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

  final _searchController = TextEditingController();
  final _selectedIds = <int>{};
  Timer? _searchDebounce;
  String codigo = codigos.first;
  String _search = '';
  String _statusFilter = 'TODOS';
  bool _ascending = true;
  int _page = 1;
  int _pageSize = 10;
  int _total = 0;
  int _totalPages = 1;
  List<Map<String, dynamic>> _catalogos = [];
  List<Map<String, dynamic>> _allDetails = [];
  Map<String, dynamic>? _selected;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as CatalogosTab).tabIndex, _load);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = _fetch();
    if (mounted) setState(() => _future = request);
    await request;
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final results = await Future.wait([
      widget.api.getCatalogo(
        codigo,
        page: _page,
        limit: _pageSize,
        search: _search,
      ),
      widget.api.getCatalogos(),
      widget.api.getCatalogo(codigo, page: 1, limit: 500),
    ]);
    final page = results[0];
    final catalogs = results[1];
    final all = results[2];
    if (mounted) {
      setState(() {
        _total = page.total;
        _totalPages = page.totalPages;
        _catalogos = catalogs.datos;
        _allDetails = all.datos;
        final selectedId = _selected == null ? null : admId(_selected!);
        _selected = page.datos.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item != null && admId(item) == selectedId,
          orElse: () => page.datos.isEmpty ? null : page.datos.first,
        );
      });
    }
    return page.datos;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final items = _visibleItems(snapshot.data ?? []);
        final selected = _selected ?? (items.isEmpty ? null : items.first);

        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1180;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(),
                  const SizedBox(height: 12),
                  const Text('Catálogos Maestros', style: AdmTokens.h1),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestione los catálogos utilizados por todo el sistema.',
                    style: AdmTokens.subtitle,
                  ),
                  const SizedBox(height: 24),
                  if (loading)
                    const _CatalogSkeleton(height: 116)
                  else
                    _buildKpis(),
                  const SizedBox(height: 20),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  _buildSelectedCatalog(),
                  const SizedBox(height: 12),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTableArea(
                            items,
                            loading: loading,
                            mobile: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 300,
                          child: _CatalogDetailPanel(
                            item: selected,
                            onEdit: selected == null
                                ? null
                                : () => _edit(selected),
                            onDuplicate: selected == null
                                ? null
                                : () => _duplicate(selected),
                            onToggle: selected == null
                                ? null
                                : () => _toggle(selected),
                            onDelete: selected == null
                                ? null
                                : () => _deleteSelected(selected),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildTableArea(
                      items,
                      loading: loading,
                      mobile: constraints.maxWidth < 700,
                    ),
                    if (constraints.maxWidth >= 700) ...[
                      const SizedBox(height: 20),
                      _CatalogDetailPanel(
                        item: selected,
                        onEdit: selected == null ? null : () => _edit(selected),
                        onDuplicate: selected == null
                            ? null
                            : () => _duplicate(selected),
                        onToggle: selected == null
                            ? null
                            : () => _toggle(selected),
                        onDelete: selected == null
                            ? null
                            : () => _deleteSelected(selected),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBreadcrumb() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: const [
        Icon(Icons.home_outlined, size: 16, color: AdmTokens.primary),
        Text('Inicio', style: AdmTokens.bodySmall),
        Icon(Icons.chevron_right_rounded, size: 16, color: AdmTokens.grey400),
        Text('Administración', style: AdmTokens.bodySmall),
        Icon(Icons.chevron_right_rounded, size: 16, color: AdmTokens.grey400),
        Text(
          'Catálogos',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AdmTokens.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildKpis() {
    final totalRecords = _catalogos.fold<int>(
      0,
      (sum, item) =>
          sum + (int.tryParse('${item['total_detalles'] ?? 0}') ?? 0),
    );
    final active = _allDetails
        .where((item) => admIsActive(item, key: 'estado'))
        .length;
    final inactive = (_allDetails.length - active).clamp(0, _allDetails.length);
    final activePct = _allDetails.isEmpty
        ? 0.0
        : active * 100 / _allDetails.length;
    final inactivePct = _allDetails.isEmpty
        ? 0.0
        : inactive * 100 / _allDetails.length;
    final cards = [
      _KpiData(
        Icons.layers_outlined,
        '${_catalogos.length}',
        'Total Catálogos',
        'Catálogos registrados',
        const Color(0xFF2563EB),
      ),
      _KpiData(
        Icons.description_outlined,
        '$totalRecords',
        'Total Registros',
        'Registros del sistema',
        const Color(0xFF3B82F6),
      ),
      _KpiData(
        Icons.check_circle_outline_rounded,
        '$active',
        'Activos',
        '${activePct.toStringAsFixed(1)}% del catálogo',
        AdmTokens.success,
      ),
      _KpiData(
        Icons.cancel_outlined,
        '$inactive',
        'Inactivos',
        '${inactivePct.toStringAsFixed(1)}% del catálogo',
        AdmTokens.error,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _CatalogKpiCard(data: card),
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = SizedBox(
          width: constraints.maxWidth >= 900 ? 360 : constraints.maxWidth,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Buscar por código, nombre o estado...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AdmTokens.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdmTokens.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdmTokens.grey200),
              ),
            ),
          ),
        );
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PopupMenuButton<String>(
              tooltip: 'Filtrar',
              onSelected: (value) => setState(() => _statusFilter = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'TODOS', child: Text('Todos')),
                PopupMenuItem(value: 'ACTIVOS', child: Text('Activos')),
                PopupMenuItem(value: 'INACTIVOS', child: Text('Inactivos')),
              ],
              child: const _ToolButton(
                icon: Icons.filter_alt_outlined,
                label: 'Filtrar',
              ),
            ),
            _ToolButton(
              icon: Icons.swap_vert_rounded,
              label: 'Ordenar',
              onTap: () => setState(() => _ascending = !_ascending),
            ),
            _ToolButton(
              icon: Icons.download_outlined,
              label: 'Exportar',
              onTap: _exportCsv,
            ),
            _ToolButton(
              icon: Icons.print_outlined,
              label: 'Imprimir',
              onTap: _print,
            ),
            _ToolButton(
              icon: Icons.refresh_rounded,
              label: 'Actualizar',
              onTap: _reload,
            ),
            _ToolButton(
              icon: Icons.add_rounded,
              label: 'Nuevo',
              primary: true,
              onTap: () => _edit(null),
            ),
          ],
        );
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              search,
              const SizedBox(width: 12),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: actions),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [search, const SizedBox(height: 12), actions],
        );
      },
    );
  }

  Widget _buildSelectedCatalog() {
    final catalog = _catalogos.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['codigo']?.toString() == codigo,
      orElse: () => null,
    );
    final name = catalog?['nombre']?.toString() ?? _catalogName(codigo);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdmTokens.grey200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = Row(
            children: [
              const _RoundIcon(icon: Icons.menu_book_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catálogo seleccionado',
                      style: AdmTokens.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(name.toUpperCase(), style: AdmTokens.h2),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        _MetaInfo(
                          Icons.people_alt_outlined,
                          '$_total registros',
                        ),
                        const _MetaInfo(
                          Icons.schedule_outlined,
                          'Actualizado recientemente',
                        ),
                        _MetaInfo(
                          Icons.hub_outlined,
                          'Utilizado por: ${_usedBy(codigo).join(', ')}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final dropdown = SizedBox(
            width: constraints.maxWidth < 560 ? constraints.maxWidth : 210,
            child: DropdownButtonFormField<String>(
              initialValue: codigo,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Cambiar catálogo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: codigos
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        _catalogName(value),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) _changeCatalog(value);
              },
            ),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 14), dropdown],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 20),
              dropdown,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableArea(
    List<Map<String, dynamic>> items, {
    required bool loading,
    required bool mobile,
  }) {
    if (loading) return const _CatalogSkeleton(height: 420);
    return Container(
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdmTokens.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 52,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 64,
              horizontalMargin: 14,
              columnSpacing: 28,
              showCheckboxColumn: true,
              headingRowColor: WidgetStateProperty.all(AdmTokens.primary),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AdmTokens.primarySoft;
                }
                if (states.contains(WidgetState.hovered)) {
                  return AdmTokens.primarySoft;
                }
                return null;
              }),
              columns: const [
                DataColumn(label: Text('Código')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Orden')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Fecha creación')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    selected:
                        _selectedIds.contains(admId(item)) ||
                        (_selected != null && admId(_selected!) == admId(item)),
                    onSelectChanged: (selected) {
                      setState(() {
                        _selected = item;
                        if (selected == true) {
                          _selectedIds.add(admId(item));
                        } else {
                          _selectedIds.remove(admId(item));
                        }
                      });
                      if (mobile) _showMobileDetails(item);
                    },
                    cells: [
                      DataCell(_CodeCell(item: item)),
                      DataCell(
                        SizedBox(width: 170, child: admText(item['nombre'])),
                      ),
                      DataCell(Center(child: admText(item['orden']))),
                      DataCell(
                        AdmStateChip(active: admIsActive(item, key: 'estado')),
                      ),
                      const DataCell(Text('—', style: AdmTokens.bodySmall)),
                      DataCell(
                        Row(
                          children: [
                            _IconAction(
                              Icons.edit_outlined,
                              'Editar',
                              () => _edit(item),
                            ),
                            _IconAction(
                              Icons.copy_outlined,
                              'Duplicar',
                              () => _duplicate(item),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Más opciones',
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              onSelected: (value) {
                                if (value == 'toggle') _toggle(item);
                                if (value == 'delete') _deleteSelected(item);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text('Cambiar estado'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _buildPagination(items.length),
        ],
      ),
    );
  }

  Widget _buildPagination(int visibleCount) {
    final start = _total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;
    final end = (_page * _pageSize).clamp(0, _total);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controls = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Anterior'),
              ),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdmTokens.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_page',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _page < _totalPages
                    ? () => _goToPage(_page + 1)
                    : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Siguiente'),
              ),
              DropdownButton<int>(
                value: _pageSize,
                underline: const SizedBox.shrink(),
                items: const [10, 25, 50, 100]
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text('$size por página'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _pageSize = value;
                    _page = 1;
                  });
                  _load();
                },
              ),
            ],
          );
          final summary = Text(
            'Mostrando $start-$end de $_total registros',
            style: AdmTokens.bodySmall,
          );
          if (constraints.maxWidth < 640) {
            return Column(
              children: [summary, const SizedBox(height: 12), controls],
            );
          }
          return Row(children: [summary, const Spacer(), controls]);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _visibleItems(List<Map<String, dynamic>> items) {
    final filtered = items.where((item) {
      final active = admIsActive(item, key: 'estado');
      if (_statusFilter == 'ACTIVOS') return active;
      if (_statusFilter == 'INACTIVOS') return !active;
      return true;
    }).toList();
    filtered.sort((a, b) {
      final orderA = int.tryParse('${a['orden'] ?? 0}') ?? 0;
      final orderB = int.tryParse('${b['orden'] ?? 0}') ?? 0;
      return _ascending ? orderA.compareTo(orderB) : orderB.compareTo(orderA);
    });
    return filtered;
  }

  void _onSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _search = value.trim();
      _page = 1;
      _load();
    });
  }

  void _reload() {
    _page = 1;
    _load();
  }

  void _goToPage(int page) {
    _page = page;
    _load();
  }

  void _changeCatalog(String value) {
    setState(() {
      codigo = value;
      _page = 1;
      _search = '';
      _selected = null;
      _selectedIds.clear();
      _searchController.clear();
    });
    _load();
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CatalogoDialog(item: item),
    );
    if (data == null || !mounted) return;
    await admSafeRun(context, () async {
      if (item == null) {
        await widget.api.createCatalogoDetalle(codigo, data);
      } else {
        await widget.api.updateCatalogoDetalle(admId(item), data);
      }
      await _load();
    });
  }

  Future<void> _duplicate(Map<String, dynamic> item) async {
    final data = Map<String, dynamic>.from(item)
      ..['codigo'] = '${item['codigo']}_COPIA'
      ..['nombre'] = '${item['nombre']} (copia)'
      ..remove('id');
    await admSafeRun(context, () async {
      await widget.api.createCatalogoDetalle(codigo, data);
      await _load();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setCatalogoDetalleActivo(
        admId(item),
        !admIsActive(item, key: 'estado'),
      );
      await _load();
    });
  }

  Future<void> _deleteSelected(Map<String, dynamic> item) async {
    final ok = await admConfirm(
      context,
      'Eliminar registro',
      '¿Eliminar el detalle ${item['nombre']}?',
    );
    if (ok != true || !mounted) return;
    await admSafeRun(context, () async {
      await widget.api.deleteCatalogoDetalle(admId(item));
      await _load();
    });
  }

  Future<void> _exportCsv() async {
    final csv = <String>['Código,Nombre,Orden,Estado'];
    for (final item in _allDetails) {
      csv.add(
        [
          item['codigo'],
          item['nombre'],
          item['orden'],
          admIsActive(item, key: 'estado') ? 'Activo' : 'Inactivo',
        ].map((value) => '"${value ?? ''}"').join(','),
      );
    }
    final path = await exportAdminCsv(
      csv.join('\n'),
      'catalogo_${codigo.toLowerCase()}.csv',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Catálogo exportado en $path')));
  }

  Future<void> _print() async {
    final printed = await printAdminPage();
    if (!printed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La impresión directa está disponible en Flutter Web.'),
        ),
      );
    }
  }

  void _showMobileDetails(Map<String, dynamic> item) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar detalles',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.centerRight,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 360,
              margin: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: _CatalogDetailPanel(
                  item: item,
                  onEdit: () => _edit(item),
                  onDuplicate: () => _duplicate(item),
                  onToggle: () => _toggle(item),
                  onDelete: () => _deleteSelected(item),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  String _catalogName(String code) => code
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0]}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  List<String> _usedBy(String code) {
    const map = {
      'ESTADOS_PERSONAL': ['Personal', 'Servicios', 'Asignaciones'],
      'AREAS': ['Personal', 'Operaciones'],
      'TIPOS_MOVIL': ['Móviles', 'Asignaciones'],
      'ESTADOS_MOVIL': ['Móviles', 'Mantenimientos'],
    };
    return map[code] ?? ['Administración', 'Operaciones'];
  }
}

class _CatalogoDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _CatalogoDialog({this.item});
  @override
  State<_CatalogoDialog> createState() => _CatalogoDialogState();
}

class _CatalogoDialogState extends State<_CatalogoDialog> {
  late final codigo = TextEditingController(
    text: '${widget.item?['codigo'] ?? ''}',
  );
  late final nombre = TextEditingController(
    text: '${widget.item?['nombre'] ?? ''}',
  );
  late final descripcion = TextEditingController(
    text: '${widget.item?['descripcion'] ?? ''}',
  );
  late final orden = TextEditingController(
    text: '${widget.item?['orden'] ?? 0}',
  );

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

class _KpiData {
  final IconData icon;
  final String value;
  final String title;
  final String caption;
  final Color color;
  const _KpiData(this.icon, this.value, this.title, this.caption, this.color);
}

class _CatalogKpiCard extends StatefulWidget {
  final _KpiData data;
  const _CatalogKpiCard({required this.data});
  @override
  State<_CatalogKpiCard> createState() => _CatalogKpiCardState();
}

class _CatalogKpiCardState extends State<_CatalogKpiCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: hovered
            ? (Matrix4.identity()..translateByDouble(0, -2, 0, 1))
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdmTokens.grey200),
          boxShadow: hovered ? AdmTokens.hoverShadow : AdmTokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: .10),
              ),
              child: Icon(data.icon, color: data.color, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: AdmTokens.label),
                  const SizedBox(height: 2),
                  Text(data.value, style: AdmTokens.statValue),
                  Text(data.caption, style: AdmTokens.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: primary ? AdmTokens.primary : AdmTokens.surface,
        foregroundColor: primary ? Colors.white : AdmTokens.grey700,
        side: BorderSide(
          color: primary ? AdmTokens.primary : AdmTokens.grey200,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  const _RoundIcon({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AdmTokens.primarySoft,
    ),
    child: Icon(icon, color: AdmTokens.primary),
  );
}

class _MetaInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaInfo(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AdmTokens.grey500),
      const SizedBox(width: 6),
      Text(label, style: AdmTokens.bodySmall),
    ],
  );
}

class _CodeCell extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CodeCell({required this.item});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AdmTokens.primarySoft,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          size: 18,
          color: AdmTokens.primary,
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 145, child: admText(item['codigo'])),
    ],
  );
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction(this.icon, this.tooltip, this.onTap);
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, size: 19),
    color: AdmTokens.primary,
    visualDensity: VisualDensity.compact,
  );
}

class _CatalogDetailPanel extends StatelessWidget {
  final Map<String, dynamic>? item;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  const _CatalogDetailPanel({
    required this.item,
    this.onEdit,
    this.onDuplicate,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final current = item;
    if (current == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: _decoration,
        child: const Center(
          child: Text('Seleccione un registro', style: AdmTokens.subtitle),
        ),
      );
    }
    final active = admIsActive(current, key: 'estado');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Detalles del Catálogo', style: AdmTokens.label),
          const SizedBox(height: 18),
          Row(
            children: [
              const _RoundIcon(icon: Icons.person_outline_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${current['codigo'] ?? ''}', style: AdmTokens.h2),
                    const SizedBox(height: 5),
                    AdmStateChip(active: active),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AdmTokens.grey200),
          _DetailRow('Código', current['codigo']),
          _DetailRow('Nombre', current['nombre']),
          _DetailRow('Orden', current['orden']),
          const _DetailRow('Fecha de creación', '—'),
          const _DetailRow('Última modificación', '—'),
          const SizedBox(height: 14),
          const Text('Descripción', style: AdmTokens.label),
          const SizedBox(height: 6),
          Text(
            '${current['descripcion'] ?? 'Sin descripción'}',
            style: AdmTokens.body,
          ),
          const SizedBox(height: 18),
          const Divider(color: AdmTokens.grey200),
          const Text('Acciones rápidas', style: AdmTokens.label),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              _QuickAction('Editar', Icons.edit_outlined, onEdit),
              _QuickAction('Duplicar', Icons.copy_outlined, onDuplicate),
              _QuickAction(
                active ? 'Desactivar' : 'Activar',
                Icons.block_outlined,
                onToggle,
                danger: true,
              ),
              _QuickAction(
                'Eliminar',
                Icons.delete_outline_rounded,
                onDelete,
                danger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration get _decoration => BoxDecoration(
    color: AdmTokens.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AdmTokens.grey200),
    boxShadow: AdmTokens.cardShadow,
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Object? value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AdmTokens.bodySmall)),
        Expanded(
          child: Text(
            '${value ?? '—'}',
            textAlign: TextAlign.right,
            style: AdmTokens.body,
          ),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  const _QuickAction(this.label, this.icon, this.onTap, {this.danger = false});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: danger ? AdmTokens.error : AdmTokens.primary,
      side: BorderSide(
        color: danger ? const Color(0xFFFCA5A5) : const Color(0xFF93C5FD),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _CatalogSkeleton extends StatefulWidget {
  final double height;
  const _CatalogSkeleton({required this.height});
  @override
  State<_CatalogSkeleton> createState() => _CatalogSkeletonState();
}

class _CatalogSkeletonState extends State<_CatalogSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .45, end: .85).animate(controller),
    child: Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AdmTokens.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
