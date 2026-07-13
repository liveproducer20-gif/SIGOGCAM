import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_design_tokens.dart';
import 'adm_export.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class RutasTab extends StatefulWidget {
  final AdmApi api;
  final int tabIndex;
  const RutasTab({super.key, required this.api, this.tabIndex = 0});

  @override
  State<RutasTab> createState() => _RutasTabState();
}

class _RutasTabState extends State<RutasTab> with AdmLazyTabMixin<RutasTab> {
  late Future<_RouteDashboardData> future;
  String search = '';
  String status = 'Todos';
  String district = 'Todos';
  String sort = 'Nombre A-Z';
  int page = 1;
  int pageSize = 10;

  @override
  void initState() {
    super.initState();
    future = Future.value(const _RouteDashboardData(routes: [], places: []));
    initLazy(widget.tabIndex, _reloadFromLazy);
  }

  Future<void> _reloadFromLazy() async {
    if (!mounted) return;
    setState(() => future = _fetch());
    await future;
  }

  Future<_RouteDashboardData> _fetch() async {
    final result = await Future.wait([
      widget.api.getRutas(),
      widget.api.getLugaresList(),
    ]);
    final routes = result[0];
    final places = result[1];
    return _RouteDashboardData(routes: routes, places: places);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RouteDashboardData>(
      future: future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const _RouteDashboardData(routes: [], places: []);
        final routes =
            data.routes.where((route) => _matches(route, data)).toList()
              ..sort((a, b) => _compare(a, b, data));
        final pages = (routes.length / pageSize).ceil().clamp(1, 999999);
        final safePage = page.clamp(1, pages);
        final visible = routes
            .skip((safePage - 1) * pageSize)
            .take(pageSize)
            .toList();
        final districts =
            data.places
                .map((e) => e['distrito']?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final active = data.routes.where(admIsActive).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rutas', style: AdmTokens.h1),
                        SizedBox(height: 5),
                        Text(
                          'Rutas organizativas para lugares de servicio.',
                          style: AdmTokens.subtitle,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _export(data),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Exportar'),
                  ),
                  const SizedBox(width: 8),
                  _RouteIconButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Actualizar',
                    onTap: _reload,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _edit(null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nueva ruta'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AdminSummaryRow(
                cards: [
                  AdminSummaryCardData(
                    icon: Icons.route_outlined,
                    value: '${data.routes.length}',
                    label: 'Rutas registradas',
                    color: AdmTokens.primary,
                  ),
                  AdminSummaryCardData(
                    icon: Icons.verified_user_outlined,
                    value: '$active',
                    label: 'En funcionamiento',
                    color: AdmTokens.success,
                  ),
                  AdminSummaryCardData(
                    icon: Icons.location_on_outlined,
                    value: '${data.places.length}',
                    label: 'Puntos operativos',
                    color: const Color(0xFFF59E0B),
                  ),
                  AdminSummaryCardData(
                    icon: Icons.apartment_outlined,
                    value: '${districts.length}',
                    label: 'Distritos operativos',
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RouteFilters(
                searchChanged: (v) => setState(() {
                  search = v;
                  page = 1;
                }),
                status: status,
                district: district,
                sort: sort,
                districts: districts,
                onStatus: (v) => setState(() {
                  status = v;
                  page = 1;
                }),
                onDistrict: (v) => setState(() {
                  district = v;
                  page = 1;
                }),
                onSort: (v) => setState(() {
                  sort = v;
                  page = 1;
                }),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 330,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final table = _RouteTable(
                      routes: visible,
                      data: data,
                      onView: (r) => _showRoute(r, data),
                      onPlaces: (r) => _showPlaces(r, data),
                      onEdit: _edit,
                      onToggle: _toggle,
                      onDelete: _confirmDelete,
                    );
                    final map = _RouteMapPanel(
                      routes: data.routes,
                      data: data,
                      onExpand: () => _showMap(data),
                    );
                    if (constraints.maxWidth < 1150) {
                      return Column(
                        children: [table, const SizedBox(height: 16), map],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: table),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: map),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 14),
              _RouteFooter(
                page: safePage,
                totalPages: pages,
                total: routes.length,
                visible: visible.length,
                pageSize: pageSize,
                onPage: (v) => setState(() => page = v),
                onPageSize: (v) => setState(() {
                  pageSize = v;
                  page = 1;
                }),
              ),
              const SizedBox(height: 16),
              _RouteBottomStats(
                districts: districts.length,
                places: data.places.length,
                active: active,
              ),
            ],
          ),
        );
      },
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      future = _fetch();
    });
  }

  bool _matches(Map<String, dynamic> route, _RouteDashboardData data) {
    final name = route['nombre']?.toString() ?? '';
    final routeDistricts = data.districtsFor(name);
    if (search.trim().isNotEmpty &&
        !name.toLowerCase().contains(search.trim().toLowerCase())) {
      return false;
    }
    if (status == 'Activos' && !admIsActive(route)) return false;
    if (status == 'Inactivos' && admIsActive(route)) return false;
    if (district != 'Todos' && !routeDistricts.contains(district)) return false;
    return true;
  }

  int _compare(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    _RouteDashboardData data,
  ) {
    String value(Map<String, dynamic> route) => switch (sort) {
      'Cantidad de lugares' =>
        data
            .placesFor(route['nombre']?.toString() ?? '')
            .length
            .toString()
            .padLeft(8, '0'),
      'Distrito' =>
        data.districtsFor(route['nombre']?.toString() ?? '').join(', '),
      'Fecha creación' => admId(route).toString().padLeft(10, '0'),
      _ => route['nombre']?.toString() ?? '',
    };
    final result = value(a).toLowerCase().compareTo(value(b).toLowerCase());
    return sort == 'Nombre Z-A' ||
            sort == 'Cantidad de lugares' ||
            sort == 'Fecha creación'
        ? -result
        : result;
  }

  Future<void> _export(_RouteDashboardData data) async {
    final rows = <String>['Código,Ruta,Lugares,Distritos,Estado'];
    for (final route in data.routes) {
      final name = route['nombre']?.toString() ?? '';
      rows.add(
        'RUT-${admId(route).toString().padLeft(3, '0')},"${name.replaceAll('"', '""')}",${data.placesFor(name).length},"${data.districtsFor(name).join(' / ')}",${admIsActive(route) ? 'Activo' : 'Inactivo'}',
      );
    }
    final path = await exportAdminCsv(rows.join('\n'), 'rutas_sigo_gcam.csv');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Rutas exportadas en $path')));
  }

  Future<void> _showPlaces(
    Map<String, dynamic> route,
    _RouteDashboardData data,
  ) => showDialog<void>(
    context: context,
    builder: (_) {
      final items = data.placesFor(route['nombre']?.toString() ?? '');
      return AlertDialog(
        title: Text('Lugares de ${route['nombre'] ?? 'ruta'}'),
        content: SizedBox(
          width: 560,
          child: items.isEmpty
              ? const Text('No existen lugares asociados.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(item['direccion']?.toString() ?? 'Lugar'),
                        subtitle: Text(
                          item['distrito']?.toString() ?? 'Sin distrito',
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );

  Future<void> _showRoute(
    Map<String, dynamic> route,
    _RouteDashboardData data,
  ) => _showPlaces(route, data);
  Future<void> _showMap(_RouteDashboardData data) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: SizedBox(
        width: 980,
        height: 650,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vista general de rutas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _RouteMapPanel(
                  routes: data.routes,
                  data: data,
                  expanded: true,
                  onExpand: () {},
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
    final ok = await admConfirm(
      context,
      'Confirmar',
      '¿Eliminar ruta ${item['nombre']}?',
    );
    if (ok != true) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.deleteRuta(admId(item));
      _reload();
    });
  }
}

class _RouteDashboardData {
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> places;
  const _RouteDashboardData({required this.routes, required this.places});
  List<Map<String, dynamic>> placesFor(String route) => places
      .where((p) => p['ruta']?.toString().toLowerCase() == route.toLowerCase())
      .toList();
  Set<String> districtsFor(String route) => placesFor(route)
      .map((p) => p['distrito']?.toString() ?? '')
      .where((d) => d.isNotEmpty)
      .toSet();
}

class _RouteFilters extends StatelessWidget {
  final ValueChanged<String> searchChanged;
  final String status;
  final String district;
  final String sort;
  final List<String> districts;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onDistrict;
  final ValueChanged<String> onSort;
  const _RouteFilters({
    required this.searchChanged,
    required this.status,
    required this.district,
    required this.sort,
    required this.districts,
    required this.onStatus,
    required this.onDistrict,
    required this.onSort,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AdmTokens.grey100),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fields = [
          _RouteSelect(
            label: 'Estado',
            value: status,
            values: const ['Todos', 'Activos', 'Inactivos'],
            onChanged: onStatus,
          ),
          _RouteSelect(
            label: 'Distrito',
            value: district,
            values: ['Todos', ...districts],
            onChanged: onDistrict,
          ),
          _RouteSelect(
            label: 'Ordenar',
            value: sort,
            values: const [
              'Nombre A-Z',
              'Nombre Z-A',
              'Cantidad de lugares',
              'Distrito',
              'Fecha creación',
            ],
            onChanged: onSort,
          ),
        ];
        if (constraints.maxWidth < 920) {
          return Column(
            children: [
              AdminSearchBar(
                onChanged: searchChanged,
                hintText: 'Buscar ruta...',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in fields) SizedBox(width: 220, child: f),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: AdminSearchBar(
                onChanged: searchChanged,
                hintText: 'Buscar ruta...',
              ),
            ),
            const SizedBox(width: 12),
            ...fields.map(
              (f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: f,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RouteSelect extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _RouteSelect({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFCFF),
      border: Border.all(color: AdmTokens.grey200),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: values.contains(value) ? value : values.first,
        icon: const Icon(Icons.expand_more_rounded, size: 18),
        items: [
          for (final item in values)
            DropdownMenuItem(
              value: item,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AdmTokens.grey500,
                    ),
                  ),
                  Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}

class _RouteIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RouteIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 46,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    ),
  );
}

class _RouteTable extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final _RouteDashboardData data;
  final ValueChanged<Map<String, dynamic>> onView;
  final ValueChanged<Map<String, dynamic>> onPlaces;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onDelete;
  const _RouteTable({
    required this.routes,
    required this.data,
    required this.onView,
    required this.onPlaces,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 20,
          offset: Offset(0, 5),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 56,
        dataRowMinHeight: 78,
        dataRowMaxHeight: 86,
        horizontalMargin: 17,
        columnSpacing: 19,
        headingRowColor: WidgetStateProperty.all(const Color(0xFF0D3F8A)),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? const Color(0xFFF4F8FD)
              : Colors.white,
        ),
        columns: const [
          DataColumn(label: _RouteHeader('Ruta')),
          DataColumn(label: _RouteHeader('Descripción')),
          DataColumn(label: _RouteHeader('Lugares')),
          DataColumn(label: _RouteHeader('Distrito')),
          DataColumn(label: _RouteHeader('Estado')),
          DataColumn(label: _RouteHeader('Acciones')),
        ],
        rows: routes.isEmpty
            ? [
                DataRow(
                  cells: [
                    const DataCell(
                      SizedBox(
                        width: 180,
                        child: Text('Sin rutas para mostrar'),
                      ),
                    ),
                    for (var i = 1; i < 6; i++)
                      const DataCell(SizedBox.shrink()),
                  ],
                ),
              ]
            : [for (final route in routes) DataRow(cells: _cells(route))],
      ),
    ),
  );

  List<DataCell> _cells(Map<String, dynamic> route) {
    final id = admId(route);
    final name = route['nombre']?.toString() ?? 'Ruta';
    final places = data.placesFor(name);
    final districts = data.districtsFor(name);
    final color = _routeColors[id.abs() % _routeColors.length];
    final short = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
    return [
      DataCell(
        SizedBox(
          width: 180,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  short.isEmpty ? 'R' : short,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'RUT-${id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdmTokens.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 220,
          child: Text(
            'Ruta organizativa para los puntos operativos de $name.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.35, color: AdmTokens.grey600),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${places.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              InkWell(
                onTap: () => onPlaces(route),
                child: const Text(
                  'Ver lugares',
                  style: TextStyle(
                    fontSize: 11,
                    color: AdmTokens.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 120,
          child: Text(
            districts.isEmpty ? 'Sin distrito' : districts.join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(AdmStateChip(active: admIsActive(route))),
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RouteAction(
              icon: Icons.visibility_outlined,
              tooltip: 'Ver',
              onTap: () => onView(route),
            ),
            const SizedBox(width: 5),
            _RouteAction(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              onTap: () => onEdit(route),
            ),
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              icon: const Icon(Icons.more_vert_rounded, size: 19),
              onSelected: (v) {
                if (v == 'toggle') onToggle(route);
                if (v == 'delete') onDelete(route);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(admIsActive(route) ? 'Desactivar' : 'Activar'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Eliminar',
                    style: TextStyle(color: AdmTokens.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _RouteHeader extends StatelessWidget {
  final String text;
  const _RouteHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
  );
}

class _RouteAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RouteAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: AdmTokens.grey200),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AdmTokens.primary),
      ),
    ),
  );
}

const _routeColors = [
  Color(0xFF2563EB),
  Color(0xFF22C55E),
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
  Color(0xFF06B6D4),
];

class _RouteMapPanel extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final _RouteDashboardData data;
  final VoidCallback onExpand;
  final bool expanded;
  const _RouteMapPanel({
    required this.routes,
    required this.data,
    required this.onExpand,
    this.expanded = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: expanded ? null : 430,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdmTokens.grey100),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vista general de rutas',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 3),
        const Text(
          'Estructura preparada para información geográfica',
          style: TextStyle(color: AdmTokens.grey500, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RouteMapPainter(routeCount: routes.length),
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 34,
                        color: AdmTokens.grey400,
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Coordenadas pendientes',
                        style: TextStyle(
                          color: AdmTokens.grey500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: expanded ? 110 : 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < routes.length; i++)
                Container(
                  width: 145,
                  margin: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 7,
                        backgroundColor: _routeColors[i % _routeColors.length],
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routes[i]['nombre']?.toString() ?? 'Ruta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${data.placesFor(routes[i]['nombre']?.toString() ?? '').length} lugares',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AdmTokens.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onExpand,
            icon: const Icon(Icons.open_in_full_rounded, size: 15),
            label: const Text('Ver mapa completo'),
          ),
        ),
      ],
    ),
  );
}

class _RouteMapPainter extends CustomPainter {
  final int routeCount;
  const _RouteMapPainter({required this.routeCount});
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFDCE6F1)
      ..strokeWidth = 1;
    for (double x = 18; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 24, size.height), grid);
    }
    for (double y = 20; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), grid);
    }
    for (var i = 0; i < routeCount.clamp(0, 5); i++) {
      final path = Path()
        ..moveTo(size.width * (.12 + i * .06), size.height * (.2 + i * .08))
        ..cubicTo(
          size.width * .35,
          size.height * (.05 + i * .12),
          size.width * .52,
          size.height * (.8 - i * .08),
          size.width * (.82 - i * .05),
          size.height * (.65 + i * .04),
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = _routeColors[i % _routeColors.length]
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.routeCount != routeCount;
}

class _RouteFooter extends StatelessWidget {
  final int page, totalPages, total, visible, pageSize;
  final ValueChanged<int> onPage, onPageSize;
  const _RouteFooter({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.visible,
    required this.pageSize,
    required this.onPage,
    required this.onPageSize,
  });
  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = total == 0 ? 0 : (start + visible - 1).clamp(0, total);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      children: [
        Text(
          'Mostrando $start a $end de $total rutas',
          style: const TextStyle(fontSize: 13, color: AdmTokens.grey500),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: page > 1 ? () => onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AdmTokens.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$page',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: page < totalPages ? () => onPage(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 por página')),
                DropdownMenuItem(value: 25, child: Text('25 por página')),
                DropdownMenuItem(value: 50, child: Text('50 por página')),
              ],
              onChanged: (v) {
                if (v != null) onPageSize(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteBottomStats extends StatelessWidget {
  final int districts, places, active;
  const _RouteBottomStats({
    required this.districts,
    required this.places,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final stats = [
      (
        Icons.apartment_outlined,
        'Cobertura total',
        '$districts distritos',
        'Distritos operativos',
      ),
      (
        Icons.map_outlined,
        'Puntos operativos',
        '$places lugares',
        'Asociados a rutas',
      ),
      (
        Icons.route_outlined,
        'Rutas activas',
        '$active rutas',
        'En funcionamiento',
      ),
      (Icons.update_rounded, 'Última actualización', date, time),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AdmTokens.grey100),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final count = constraints.maxWidth >= 900
              ? 4
              : (constraints.maxWidth >= 480 ? 2 : 1);
          final width = (constraints.maxWidth - ((count - 1) * 16)) / count;
          return Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              for (final stat in stats)
                SizedBox(
                  width: width,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AdmTokens.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          stat.$1,
                          color: AdmTokens.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.$2,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AdmTokens.grey500,
                              ),
                            ),
                            Text(
                              stat.$3,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              stat.$4,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AdmTokens.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
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
    children: [admField(nombre, 'Nombre')],
    onSave: () => Navigator.pop(context, {'nombre': nombre.text.trim()}),
  );
  String _s(String key) => widget.item?[key]?.toString() ?? '';
}
