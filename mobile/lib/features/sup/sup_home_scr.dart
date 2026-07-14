import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../adm/adm_export.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'sup_api.dart';
import 'sup_badges.dart';
import 'sup_mdl.dart';
import 'sup_report_form.dart';
import 'sup_realtime.dart';
import 'sup_ticket_detail.dart';

class SupHomeScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout, onNotifications;
  const SupHomeScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
  });
  @override
  State<SupHomeScr> createState() => _SupHomeScrState();
}

class _SupHomeScrState extends State<SupHomeScr> {
  final api = SupportApi();
  StreamSubscription<String>? _live;
  Timer? _debounce, _liveReload;
  List<SupportTicket> _tickets = const [];
  SupportStats _stats = const SupportStats();
  bool _loading = true;
  Object? _error;
  int _page = 1, _total = 0;
  final int _pageSize = 20;
  int? _selectedId;
  int _userTab = 0;
  String _search = '',
      _status = '',
      _priority = '',
      _module = '',
      _userFilter = '',
      _area = '',
      _since = '';
  bool get admin => widget.user.esAdmin;
  @override
  void initState() {
    super.initState();
    _load();
    SupportRealtime.instance.attach();
    _live = SupportRealtime.instance.events.listen(_onLiveEvent);
  }

  @override
  void dispose() {
    _live?.cancel();
    _debounce?.cancel();
    _liveReload?.cancel();
    SupportRealtime.instance.detach();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final values = await Future.wait([
        api.list(
          page: _page,
          pageSize: _pageSize,
          search: _search,
          status: _status,
          priority: _priority,
          module: _module,
          user: _userFilter,
          area: _area,
          since: _since,
        ),
        api.stats(),
      ]);
      if (!mounted) return;
      final p = values[0] as SupportPage;
      setState(() {
        _tickets = p.tickets;
        _total = p.total;
        _stats = values[1] as SupportStats;
        _loading = false;
        if (_selectedId != null && !_tickets.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _onLiveEvent(String line) {
    _liveReload?.cancel();
    _liveReload = Timer(const Duration(milliseconds: 350), _load);
    if (admin && line.contains('"titulo"')) {
      if (!mounted) return;
      final match = RegExp(r'"titulo":"([^"]+)').firstMatch(line);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nuevo movimiento de soporte${match == null ? '' : ': ${match.group(1)}'}',
          ),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () {
              setState(() => _page = 1);
              _load();
            },
          ),
        ),
      );
    } else if (!admin && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu reporte de soporte fue actualizado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: TopBarWdg(
      ttl: 'Alertas y Soporte',
      user: widget.user,
      onUserChanged: widget.onUserChanged,
      onLogout: widget.onLogout,
      onNotifications: widget.onNotifications,
    ),
    body: admin ? _adminView() : _userView(),
  );
  Widget _adminView() => LayoutBuilder(
    builder: (context, c) => Column(
      children: [
        _header(admin: true),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              c.maxWidth < 700 ? 12 : 20,
              0,
              c.maxWidth < 700 ? 12 : 20,
              18,
            ),
            child: LayoutBuilder(
              builder: (context, inner) {
                final content = _ticketArea();
                if (inner.maxWidth < 1180 || _selectedId == null) {
                  return content;
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 7, child: content),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: SupportTicketDetail(
                          key: ValueKey(_selectedId),
                          api: api,
                          user: widget.user,
                          ticketId: _selectedId!,
                          onClose: () => setState(() => _selectedId = null),
                          onChanged: _load,
                          onExport: _export,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
  Widget _userView() => Column(
    children: [
      _header(admin: false),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final item in const [
              (Icons.list_alt_rounded, 'Mis reportes'),
              (Icons.add_alert_rounded, 'Nuevo reporte'),
              (Icons.history_rounded, 'Historial'),
            ])
              Expanded(
                child: _UserTab(
                  icon: item.$1,
                  label: item.$2,
                  selected:
                      _userTab ==
                      const [
                        (Icons.list_alt_rounded, 'Mis reportes'),
                        (Icons.add_alert_rounded, 'Nuevo reporte'),
                        (Icons.history_rounded, 'Historial'),
                      ].indexOf(item),
                  onTap: () => setState(
                    () => _userTab = const [
                      (Icons.list_alt_rounded, 'Mis reportes'),
                      (Icons.add_alert_rounded, 'Nuevo reporte'),
                      (Icons.history_rounded, 'Historial'),
                    ].indexOf(item),
                  ),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _userTab,
          children: [
            _userTickets(),
            SupportReportForm(
              api: api,
              onSubmitted: () {
                setState(() => _userTab = 0);
                _load();
              },
            ),
            _userTickets(history: true),
          ],
        ),
      ),
    ],
  );
  Widget _header({required bool admin}) => LayoutBuilder(
    builder: (context, constraints) {
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            admin ? 'Alertas y Soporte' : 'Centro de soporte',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            admin
                ? 'Centro de monitoreo de errores y problemas reportados por los usuarios.'
                : 'Reporta problemas y consulta su estado.',
            style: const TextStyle(color: Color(0xFFCFDDF0), fontSize: 12),
          ),
        ],
      );
      final actions = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            onPressed: _tickets.isEmpty ? null : _showExportMenu,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Exportar'),
          ),
          IconButton.outlined(
            color: Colors.white,
            onPressed: _settings,
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      );
      return Container(
        color: const Color(0xFF082F6B),
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth < 700 ? 16 : 22,
          14,
          18,
          15,
        ),
        child: constraints.maxWidth < 700
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (admin) ...[const SizedBox(height: 12), actions],
                ],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  if (admin) actions,
                ],
              ),
      );
    },
  );
  Widget _ticketArea() => Column(
    children: [
      _statsRow(),
      const SizedBox(height: 12),
      _filters(),
      const SizedBox(height: 12),
      Expanded(
        child: Card(elevation: 0, clipBehavior: Clip.antiAlias, child: _body()),
      ),
    ],
  );
  Widget _statsRow() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 6
          : constraints.maxWidth >= 600
          ? 3
          : 2;
      final itemWidth = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatCard(
            width: itemWidth,
            label: 'Total alertas',
            value: _stats.total,
            color: const Color(0xFF0D5BD7),
            icon: Icons.notifications_active_outlined,
            onTap: () => _filterPriority(''),
          ),
          _StatCard(
            width: itemWidth,
            label: 'Críticas',
            value: _stats.critical,
            color: supportPriorityColor('Crítica'),
            icon: Icons.error_outline,
            onTap: () => _filterPriority('Crítica'),
          ),
          _StatCard(
            width: itemWidth,
            label: 'Altas',
            value: _stats.high,
            color: supportPriorityColor('Alta'),
            icon: Icons.warning_amber,
            onTap: () => _filterPriority('Alta'),
          ),
          _StatCard(
            width: itemWidth,
            label: 'Medias',
            value: _stats.medium,
            color: supportPriorityColor('Media'),
            icon: Icons.info_outline,
            onTap: () => _filterPriority('Media'),
          ),
          _StatCard(
            width: itemWidth,
            label: 'Bajas',
            value: _stats.low,
            color: supportPriorityColor('Baja'),
            icon: Icons.task_alt,
            onTap: () => _filterPriority('Baja'),
          ),
          _StatCard(
            width: itemWidth,
            label: 'Respuesta promedio',
            text: _duration(_stats.averageMinutes),
            color: const Color(0xFF7C3AED),
            icon: Icons.schedule_outlined,
            onTap: () => _showResponseTimes(),
          ),
        ],
      );
    },
  );
  Widget _filters() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, c) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: c.maxWidth < 700 ? c.maxWidth : 290,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por título, usuario o código...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    _search = v;
                    _page = 1;
                    _load();
                  });
                },
              ),
            ),
            _select('Estado', _status, const [
              '',
              'Nuevo',
              'En proceso',
              'Pendiente',
              'Resuelto',
              'Cancelado',
            ], (v) => _setFilter(status: v)),
            _select('Prioridad', _priority, const [
              '',
              'Crítica',
              'Alta',
              'Media',
              'Baja',
            ], (v) => _setFilter(priority: v)),
            _select('Módulo', _module, [
              '',
              ...supportModules,
            ], (v) => _setFilter(module: v)),
            OutlinedButton.icon(
              onPressed: _advancedFilters,
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                'Filtros${[_userFilter, _area, _since].where((e) => e.isNotEmpty).isEmpty ? '' : ' (${[_userFilter, _area, _since].where((e) => e.isNotEmpty).length})'}',
              ),
            ),
            if (_hasFilters)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Limpiar'),
              ),
          ],
        ),
      ),
    ),
  );
  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => SizedBox(
    width: 160,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e.isEmpty ? 'Todos' : e,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => changed(v ?? ''),
    ),
  );
  Widget _body() {
    if (_loading && _tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar las alertas\n$_error',
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 50,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 10),
            Text(
              'No hay reportes para estos filtros',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) => Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: c.maxWidth < 820
                ? ListView.builder(
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) => _mobileTicket(_tickets[i]),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _table(),
                  ),
          ),
          _pager(),
        ],
      ),
    );
  }

  Widget _table() => DataTable(
    showCheckboxColumn: false,
    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
    columns: const [
      DataColumn(label: Text('ESTADO')),
      DataColumn(label: Text('TÍTULO')),
      DataColumn(label: Text('USUARIO')),
      DataColumn(label: Text('MÓDULO')),
      DataColumn(label: Text('PRIORIDAD')),
      DataColumn(label: Text('FECHA')),
      DataColumn(label: Text('ACCIONES')),
    ],
    rows: [
      for (final t in _tickets)
        DataRow(
          onSelectChanged: (_) => _open(t),
          cells: [
            DataCell(SupportStatusBadge(t.status)),
            DataCell(
              SizedBox(
                width: 240,
                child: Text(
                  t.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF082F6B),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(width: 150, child: Text(t.userName, maxLines: 2)),
            ),
            DataCell(Text(t.module)),
            DataCell(SupportPriorityBadge(t.priority)),
            DataCell(Text(_shortDate(t.createdAt))),
            DataCell(
              IconButton(
                onPressed: () => _open(t),
                tooltip: 'Ver detalle',
                icon: const Icon(Icons.visibility_outlined),
              ),
            ),
          ],
        ),
    ],
  );
  Widget _mobileTicket(SupportTicket t) => Container(
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: supportPriorityColor(t.priority), width: 4),
        bottom: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    child: ListTile(
      onTap: () => _open(t),
      title: Text(
        t.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            SupportStatusBadge(t.status),
            SupportPriorityBadge(t.priority),
            Text(
              '${t.module} · ${_shortDate(t.createdAt)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
  Widget _pager() => Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$_total reportes',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        IconButton(
          onPressed: _page > 1
              ? () {
                  _page--;
                  _load();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$_page / ${(_total / _pageSize).ceil().clamp(1, 9999)}'),
        IconButton(
          onPressed: _page * _pageSize < _total
              ? () {
                  _page++;
                  _load();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
  Widget _userTickets({bool history = false}) => Padding(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 700 ? 12 : 20),
    child: Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    history
                        ? 'Historial de mis reportes'
                        : 'Estado de mis reportes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF082F6B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    ),
  );
  void _open(SupportTicket t) {
    setState(() => _selectedId = t.id);
    if (MediaQuery.sizeOf(context).width < 1180 || !admin) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.sizeOf(context).height - 24,
            ),
            child: SupportTicketDetail(
              api: api,
              user: widget.user,
              ticketId: t.id,
              onClose: () => Navigator.pop(context),
              onChanged: _load,
              onExport: _export,
            ),
          ),
        ),
      );
    }
  }

  void _setFilter({String? status, String? priority, String? module}) {
    if (status != null) _status = status;
    if (priority != null) _priority = priority;
    if (module != null) _module = module;
    _page = 1;
    _load();
  }

  void _filterPriority(String value) {
    _priority = value;
    _page = 1;
    _load();
  }

  bool get _hasFilters =>
      _status.isNotEmpty ||
      _priority.isNotEmpty ||
      _module.isNotEmpty ||
      _search.isNotEmpty ||
      _userFilter.isNotEmpty ||
      _area.isNotEmpty ||
      _since.isNotEmpty;
  void _clearFilters() {
    _status = _priority = _module = _search = _userFilter = _area = _since = '';
    _page = 1;
    _load();
  }

  Future<void> _export([String type = 'csv']) async {
    final rows = <String>[
      'Código,Estado,Título,Usuario,Área,Módulo,Prioridad,Fecha',
    ];
    for (final t in _tickets) {
      rows.add(
        [
          t.code,
          t.status,
          t.title,
          t.userName,
          t.area,
          t.module,
          t.priority,
          t.createdAt.toIso8601String(),
        ].map(_csv).join(','),
      );
    }
    if (type == 'pdf') {
      final ok = await printAdminPage();
      if (mounted && !ok) {
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
    final extension = type == 'excel' ? 'xls' : 'csv';
    final path = await exportAdminCsv(
      rows.join('\n'),
      'ALERTAS_SOPORTE_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exportación generada en $path')));
    }
  }

  Future<void> _showExportMenu() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Exportar resultados filtrados',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.table_view_outlined),
              title: const Text('Excel'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF / Imprimir'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (type != null) await _export(type);
  }

  Future<void> _advancedFilters() async {
    final userCtl = TextEditingController(text: _userFilter);
    final areaCtl = TextEditingController(text: _area);
    var period = _since.isEmpty ? 'Todos' : 'Personalizado';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Filtros avanzados'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtl,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: period,
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                  items:
                      const [
                            'Todos',
                            'Hoy',
                            'Últimos 7 días',
                            'Últimos 30 días',
                            'Personalizado',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setLocal(() => period = v ?? 'Todos'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'usuario': '',
                'area': '',
                'desde': '',
              }),
              child: const Text('Limpiar'),
            ),
            FilledButton(
              onPressed: () {
                final days = switch (period) {
                  'Hoy' => 0,
                  'Últimos 7 días' => 7,
                  'Últimos 30 días' => 30,
                  _ => null,
                };
                final since = days == null
                    ? ''
                    : DateTime.now()
                          .subtract(Duration(days: days))
                          .toIso8601String();
                Navigator.pop(context, {
                  'usuario': userCtl.text.trim(),
                  'area': areaCtl.text.trim(),
                  'desde': since,
                });
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    userCtl.dispose();
    areaCtl.dispose();
    if (result == null || !mounted) return;
    _userFilter = result['usuario'] ?? '';
    _area = result['area'] ?? '';
    _since = result['desde'] ?? '';
    _page = 1;
    _load();
  }

  Future<void> _settings() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Configuración de soporte'),
      content: const SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bolt_rounded),
              title: Text('Actualización en tiempo real'),
              subtitle: Text(
                'Activa mediante Server-Sent Events; reconexión automática cada 8 segundos si se interrumpe.',
              ),
            ),
            ListTile(
              leading: Icon(Icons.image_outlined),
              title: Text('Evidencias'),
              subtitle: Text('PNG, JPG, JPEG o WEBP; máximo 5 MB.'),
            ),
            ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Privacidad'),
              subtitle: Text(
                'Cada usuario solo puede consultar sus propios reportes.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
  Future<void> _showResponseTimes() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Tiempo promedio de respuesta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Promedio general'),
            trailing: Text(
              _duration(_stats.averageMinutes),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const ListTile(
            title: Text('Seguimiento'),
            subtitle: Text(
              'El promedio se calcula desde la creación hasta la primera respuesta o gestión del administrador.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
  String _duration(int m) => m < 60 ? '$m min' : '${m ~/ 60} h ${m % 60} min';
  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _csv(Object? v) => '"${(v?.toString() ?? '').replaceAll('"', '""')}"';
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final int? value;
  final String? text;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _StatCard({
    required this.width,
    required this.label,
    this.value,
    this.text,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text ?? '$value',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _UserTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UserTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? const Color(0xFF0D5BD7) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? const Color(0xFF0D5BD7) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF0D5BD7)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
