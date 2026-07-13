import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_crud_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class LugaresTab extends AdmCrudTab {
  final int tabIndex;
  const LugaresTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _LugarState();
}

class _LugarState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _pageSize = 10;
  String _search = '';
  String _status = 'Todos';
  String _place = 'Todos';
  String _district = 'Todos';
  String _sort = 'Nombre A-Z';
  bool _gridView = false;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as LugaresTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final items = await widget.api.getLugaresList();
    if (!mounted) return;
    setState(() {
      _future = Future.value(items);
    });
  }

  void _reload() {
    setState(() { _page = 1; });
    _load();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _future,
    builder: (context, snapshot) {
      final all = snapshot.data ?? const <Map<String, dynamic>>[];
      final places = all.map((e) => e['ruta']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
      final districts = all.map((e) => e['distrito']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
      final filtered = all.where(_matchesFilters).toList()..sort(_comparePlaces);
      final pages = (filtered.length / _pageSize).ceil().clamp(1, 999999);
      final safePage = _page.clamp(1, pages);
      final start = (safePage - 1) * _pageSize;
      final visible = filtered.skip(start).take(_pageSize).toList();
      final active = all.where(admIsActive).length;
      final routes = all.map((e) => e['ruta']?.toString()).whereType<String>().toSet().length;
      final coveredDistricts = all.map((e) => e['distrito']?.toString()).whereType<String>().toSet().length;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lugares de servicio', style: AdmTokens.h1),
              SizedBox(height: 5),
              Text('Puntos operativos organizados por ruta y distrito.', style: AdmTokens.subtitle),
            ])),
            _LugarIconButton(icon: Icons.refresh_rounded, tooltip: 'Refrescar', onTap: _reload),
            const SizedBox(width: 9),
            FilledButton.icon(onPressed: () => _edit(null), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nuevo lugar')),
          ]),
          const SizedBox(height: 22),
          AdminSummaryRow(cards: [
            AdminSummaryCardData(icon: Icons.location_on_outlined, value: '${all.length}', label: 'Lugares registrados', color: AdmTokens.primary),
            AdminSummaryCardData(icon: Icons.apartment_rounded, value: '$active', label: 'En funcionamiento', color: AdmTokens.success),
            AdminSummaryCardData(icon: Icons.map_outlined, value: '$routes', label: 'Rutas asignadas', color: const Color(0xFFF97316)),
            AdminSummaryCardData(icon: Icons.shield_outlined, value: '$coveredDistricts', label: 'Distritos operativos', color: const Color(0xFF7C3AED)),
          ]),
          const SizedBox(height: 20),
          _LugarFilters(
            status: _status, place: _place, district: _district, sort: _sort,
            places: places, districts: districts, gridView: _gridView,
            onSearch: _onSearch,
            onStatus: (v) => setState(() { _status = v; _page = 1; }),
            onPlace: (v) => setState(() { _place = v; _page = 1; }),
            onDistrict: (v) => setState(() { _district = v; _page = 1; }),
            onSort: (v) => setState(() { _sort = v; _page = 1; }),
            onView: (grid) => setState(() => _gridView = grid),
            onManageRoutes: _showRutasManager,
          ),
          const SizedBox(height: 16),
          if (snapshot.connectionState == ConnectionState.waiting)
            const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
          else if (_gridView)
            _LugarGrid(items: visible, onView: _showDetails, onEdit: _edit, onToggle: _toggle, onDelete: _deletePlace)
          else
            _LugarTable(items: visible, onView: _showDetails, onEdit: _edit, onToggle: _toggle, onDelete: _deletePlace),
          const SizedBox(height: 14),
          _LugarFooter(page: safePage, totalPages: pages, total: filtered.length, visible: visible.length, pageSize: _pageSize, onPage: _onPageChanged, onPageSize: (value) => setState(() { _pageSize = value; _page = 1; })),
        ]),
      );
    },
  );

  bool _matchesFilters(Map<String, dynamic> item) {
    final route = item['ruta']?.toString() ?? '';
    final address = item['direccion']?.toString() ?? '';
    final district = item['distrito']?.toString() ?? '';
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty && !'$route $address $district'.toLowerCase().contains(query)) return false;
    if (_status == 'Activos' && !admIsActive(item)) return false;
    if (_status == 'Inactivos' && admIsActive(item)) return false;
    if (_place != 'Todos' && route != _place) return false;
    if (_district != 'Todos' && district != _district) return false;
    return true;
  }

  int _comparePlaces(Map<String, dynamic> a, Map<String, dynamic> b) {
    String value(Map<String, dynamic> item) => switch (_sort) {
      'Distrito' => item['distrito']?.toString() ?? '',
      'Ruta' => item['ruta']?.toString() ?? '',
      'Más recientes' || 'Más antiguos' => admId(item).toString().padLeft(12, '0'),
      _ => item['ruta']?.toString() ?? '',
    };
    final result = value(a).toLowerCase().compareTo(value(b).toLowerCase());
    return (_sort == 'Nombre Z-A' || _sort == 'Más recientes') ? -result : result;
  }

  Future<void> _showDetails(Map<String, dynamic> item) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(item['ruta']?.toString() ?? 'Lugar de servicio'),
      content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _detail('Código', 'LUG-${admId(item).toString().padLeft(2, '0')}'),
        _detail('Ubicación', item['direccion']),
        _detail('Distrito', item['distrito']),
        _detail('Horario', '${item['hora_entrada'] ?? '—'} - ${item['hora_salida'] ?? '—'}'),
        _detail('Consignas', item['consignas']),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    ),
  );

  Widget _detail(String label, Object? value) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Expanded(child: Text(value?.toString().trim().isNotEmpty == true ? value.toString() : '—'))]));

  Future<void> _deletePlace(Map<String, dynamic> item) => _confirmDelete(item, 'lugar ${item['direccion']}', () => widget.api.deleteLugar(admId(item)));

  void _showRutasManager() {
    showDialog(
      context: context,
      builder: (_) => _RutasManagerDialog(api: widget.api),
    );
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final results = await Future.wait([
      CatalogCache.instance.getOrLoad(widget.api),
      widget.api.getRutas(),
    ]);
    final catalogs = results[0] as Map<String, List<Map<String, dynamic>>>;
    final rutas = results[1] as List<Map<String, dynamic>>;
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LugarDialog(item: item, rutas: rutas, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createLugar(data)
          : await widget.api.updateLugar(admId(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setLugarActivo(admId(item), !admIsActive(item));
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

class _LugarFilters extends StatelessWidget {
  final String status;
  final String place;
  final String district;
  final String sort;
  final List<String> places;
  final List<String> districts;
  final bool gridView;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onPlace;
  final ValueChanged<String> onDistrict;
  final ValueChanged<String> onSort;
  final ValueChanged<bool> onView;
  final VoidCallback onManageRoutes;
  const _LugarFilters({required this.status, required this.place, required this.district, required this.sort, required this.places, required this.districts, required this.gridView, required this.onSearch, required this.onStatus, required this.onPlace, required this.onDistrict, required this.onSort, required this.onView, required this.onManageRoutes});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdmTokens.grey100), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 4))]),
    child: LayoutBuilder(builder: (context, constraints) {
      final filters = [
        _LugarSelect(label: 'Estado', value: status, values: const ['Todos', 'Activos', 'Inactivos'], onChanged: onStatus),
        _LugarSelect(label: 'Lugar', value: place, values: ['Todos', ...places], onChanged: onPlace),
        _LugarSelect(label: 'Distrito', value: district, values: ['Todos', ...districts], onChanged: onDistrict),
        _LugarSelect(label: 'Ordenar', value: sort, values: const ['Nombre A-Z', 'Nombre Z-A', 'Distrito', 'Ruta', 'Más recientes', 'Más antiguos'], onChanged: onSort),
      ];
      return Column(children: [
        if (constraints.maxWidth >= 1050)
          Row(children: [Expanded(flex: 2, child: AdminSearchBar(onChanged: onSearch, hintText: 'Buscar lugar, ruta o distrito...')), const SizedBox(width: 10), ...filters.map((f) => Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: f)))])
        else ...[
          AdminSearchBar(onChanged: onSearch, hintText: 'Buscar lugar, ruta o distrito...'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final f in filters) SizedBox(width: 200, child: f)]),
        ],
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton.icon(onPressed: onManageRoutes, icon: const Icon(Icons.map_outlined, size: 17), label: const Text('Gestionar rutas')),
          const Spacer(),
          _ViewButton(icon: Icons.grid_view_rounded, selected: gridView, tooltip: 'Vista cuadrícula', onTap: () => onView(true)),
          const SizedBox(width: 6),
          _ViewButton(icon: Icons.view_list_rounded, selected: !gridView, tooltip: 'Vista tabla', onTap: () => onView(false)),
        ]),
      ]);
    }),
  );
}

class _LugarSelect extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _LugarSelect({required this.label, required this.value, required this.values, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFFFAFCFF), border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: values.contains(value) ? value : values.first, icon: const Icon(Icons.expand_more_rounded, size: 18), items: [for (final item in values) DropdownMenuItem(value: item, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: AdmTokens.grey500)), Text(item, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]))], onChanged: (next) { if (next != null) onChanged(next); })),
  );
}

class _ViewButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  const _ViewButton({required this.icon, required this.selected, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: AnimatedContainer(duration: const Duration(milliseconds: 130), width: 44, height: 38, decoration: BoxDecoration(color: selected ? AdmTokens.primary : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? AdmTokens.primary : AdmTokens.grey200)), child: Icon(icon, size: 19, color: selected ? Colors.white : AdmTokens.grey600))));
}

class _LugarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _LugarIconButton({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: SizedBox(width: 46, height: 46, child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Icon(icon, size: 20))));
}

class _LugarTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _LugarTable({required this.items, required this.onView, required this.onEdit, required this.onToggle, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 22, offset: Offset(0, 6))]),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowHeight: 56, dataRowMinHeight: 70, dataRowMaxHeight: 78, horizontalMargin: 20, columnSpacing: 25,
      headingRowColor: WidgetStateProperty.all(const Color(0xFF0D3F8A)),
      dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? const Color(0xFFF4F8FD) : Colors.white),
      columns: const [DataColumn(label: _Header('Lugar')), DataColumn(label: _Header('Ruta')), DataColumn(label: _Header('Ubicación')), DataColumn(label: _Header('Distrito')), DataColumn(label: _Header('Estado')), DataColumn(label: _Header('Acciones'))],
      rows: items.isEmpty ? [DataRow(cells: [const DataCell(SizedBox(width: 180, child: Text('Sin lugares para mostrar'))), for (var i = 1; i < 6; i++) const DataCell(SizedBox.shrink())])] : [for (final item in items) DataRow(cells: _cells(item))],
    )),
  );

  List<DataCell> _cells(Map<String, dynamic> item) {
    final id = admId(item);
    final color = _placeColors[id.abs() % _placeColors.length];
    return [
      DataCell(SizedBox(width: 210, child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 21)), const SizedBox(width: 11), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['ruta']?.toString() ?? 'Lugar', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AdmTokens.grey800)), Text('LUG-${id.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: AdmTokens.grey500))]))]))),
      DataCell(SizedBox(width: 190, child: Text(item['ruta']?.toString() ?? '—', maxLines: 2))),
      DataCell(SizedBox(width: 250, child: Text(item['direccion']?.toString() ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis))),
      DataCell(SizedBox(width: 150, child: Text(item['distrito']?.toString() ?? '—'))),
      DataCell(AdmStateChip(active: admIsActive(item))),
      DataCell(_LugarActions(item: item, onView: onView, onEdit: onEdit, onToggle: onToggle, onDelete: onDelete)),
    ];
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700));
}

const _placeColors = [Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF97316), Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFEC4899)];

class _LugarActions extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _LugarActions({required this.item, required this.onView, required this.onEdit, required this.onToggle, required this.onDelete});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    _ActionSquare(icon: Icons.visibility_outlined, tooltip: 'Ver', onTap: () => onView(item)), const SizedBox(width: 6),
    _ActionSquare(icon: Icons.edit_outlined, tooltip: 'Editar', onTap: () => onEdit(item)), const SizedBox(width: 3),
    PopupMenuButton<String>(tooltip: 'Más opciones', icon: const Icon(Icons.more_vert_rounded, size: 19, color: AdmTokens.grey600), onSelected: (value) { if (value == 'toggle') onToggle(item); if (value == 'delete') onDelete(item); }, itemBuilder: (_) => [PopupMenuItem(value: 'toggle', child: Text(admIsActive(item) ? 'Desactivar' : 'Activar')), const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AdmTokens.error)))]),
  ]);
}

class _ActionSquare extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionSquare({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: AdmTokens.grey200), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 17, color: AdmTokens.primary))));
}

class _LugarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _LugarGrid({required this.items, required this.onView, required this.onEdit, required this.onToggle, required this.onDelete});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final count = constraints.maxWidth >= 1400 ? 4 : (constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1));
    if (items.isEmpty) return const SizedBox(height: 180, child: Center(child: Text('Sin lugares para mostrar')));
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.7), itemBuilder: (_, index) {
      final item = items[index];
      final color = _placeColors[admId(item).abs() % _placeColors.length];
      return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AdmTokens.grey100), boxShadow: const [BoxShadow(color: Color(0x0D0F172A), blurRadius: 15, offset: Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 20)), const Spacer(), AdmStateChip(active: admIsActive(item))]),
        const SizedBox(height: 11), Text(item['ruta']?.toString() ?? 'Lugar', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AdmTokens.grey800)), const SizedBox(height: 3), Text(item['direccion']?.toString() ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AdmTokens.grey500)), const Spacer(), Row(children: [Expanded(child: Text(item['distrito']?.toString() ?? '—', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))), _LugarActions(item: item, onView: onView, onEdit: onEdit, onToggle: onToggle, onDelete: onDelete)]),
      ]));
    });
  });
}

class _LugarFooter extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final int visible;
  final int pageSize;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  const _LugarFooter({required this.page, required this.totalPages, required this.total, required this.visible, required this.pageSize, required this.onPage, required this.onPageSize});
  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (start + visible - 1).clamp(0, total);
    return Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 10, children: [
      Text('Mostrando $start a $end de $total lugares', style: const TextStyle(color: AdmTokens.grey500, fontSize: 13)),
      Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: page > 1 ? () => onPage(page - 1) : null, icon: const Icon(Icons.chevron_left_rounded)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AdmTokens.primary, borderRadius: BorderRadius.circular(9)), child: Text('$page', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), IconButton(onPressed: page < totalPages ? () => onPage(page + 1) : null, icon: const Icon(Icons.chevron_right_rounded)), const SizedBox(width: 10), DropdownButton<int>(value: pageSize, underline: const SizedBox.shrink(), items: const [DropdownMenuItem(value: 10, child: Text('10 por página')), DropdownMenuItem(value: 25, child: Text('25 por página')), DropdownMenuItem(value: 50, child: Text('50 por página'))], onChanged: (value) { if (value != null) onPageSize(value); })]),
    ]);
  }
}

class _RutasManagerDialog extends StatefulWidget {
  final AdmApi api;
  const _RutasManagerDialog({required this.api});
  @override
  State<_RutasManagerDialog> createState() => _RutasManagerDialogState();
}

class _RutasManagerDialogState extends State<_RutasManagerDialog> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getRutas();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestionar Rutas'),
      content: SizedBox(
        width: 500,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva Ruta'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: [
                      for (final item in items)
                        DataRow(cells: [
                          DataCell(admText(item['nombre'])),
                          DataCell(AdmStateChip(active: admIsActive(item))),
                          DataCell(AdmActions(
                            onEdit: () => _edit(item),
                            onToggle: () => _toggle(item),
                            onDelete: () => _confirmDelete(item),
                            active: admIsActive(item),
                          )),
                        ]),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = widget.api.getRutas();
    });
  }

  Future<void> _create() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _RutaDialog(),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.createRuta(data);
      _reload();
    });
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RutaDialog(item: item),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.updateRuta(admId(item), data);
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

class _LugarDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> rutas;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _LugarDialog({this.item, required this.rutas, required this.catalogs});
  @override
  State<_LugarDialog> createState() => _LugarDialogState();
}

class _LugarDialogState extends State<_LugarDialog> {
  late final direccion = TextEditingController(text: _s('direccion'));
  late final horaEntrada = TextEditingController(text: _s('hora_entrada'));
  late final horaSalida = TextEditingController(text: _s('hora_salida'));
  late final consignas = TextEditingController(text: _s('consignas'));
  int? rutaId;
  int? distritoId;
  @override
  void initState() {
    super.initState();
    rutaId = _int('ruta_id');
    distritoId = _int('distrito_id');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo lugar' : 'Editar lugar',
        children: [
          admDropdown('Ruta', widget.rutas, rutaId, (v) => setState(() => rutaId = v)),
          admField(direccion, 'Ubicacion'),
          admDropdown('Distrito', widget.catalogs['DISTRITOS'], distritoId, (v) => setState(() => distritoId = v)),
          admField(horaEntrada, 'Horario de entrada (HH:mm)'),
          admField(horaSalida, 'Horario de salida (HH:mm)'),
          admField(consignas, 'Consignas'),
        ],
        onSave: () => Navigator.pop(context, {
          'rutaId': rutaId,
          'direccion': direccion.text.trim(),
          'distritoId': distritoId,
          'horaEntrada': horaEntrada.text.trim(),
          'horaSalida': horaSalida.text.trim(),
          'consignas': consignas.text.trim(),
        }),
      );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}
