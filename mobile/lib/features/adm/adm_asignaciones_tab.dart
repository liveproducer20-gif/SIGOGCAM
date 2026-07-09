import 'package:flutter/material.dart';

import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class AsignacionesTab extends AdmCrudTab {
  final int tabIndex;
  const AsignacionesTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _AsignacionState();
}

class _AsignacionState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _search = '';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value([]);
    initLazy((widget as AsignacionesTab).tabIndex, _load);
  }

  Future<void> _load() async {
    final result = await widget.api.getAsignaciones(page: _page, search: _search);
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
  Widget build(BuildContext context) => AdmAsyncTable(
        title: 'Asignación de móviles a EAS',
        subtitle: 'Historial de asignaciones con una sola asignacion activa por movil.',
        future: _future,
        columns: const ['EAS', 'Movil', 'Fecha', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        total: _total,
        currentPage: _page,
        totalPages: _totalPages,
        onPageChanged: _onPageChanged,
        onSearch: _onSearch,
        searchHint: 'Buscar asignación...',
        rowBuilder: (item) => [
          admText('${item['eas_codigo'] ?? ''} ${item['eas'] ?? ''}'.trim()),
          admText('${item['numero_movil'] ?? ''} ${item['placa'] ?? ''}'.trim()),
          admText(item['fecha_asignacion']),
          AdmStateChip(active: admIsActive(item), label: item['estado']?.toString()),
          AdmActions(
            onEdit: () => _edit(item),
            onDelete: () => _confirmDelete(
              item,
              'asignacion',
              () => widget.api.deleteAsignacion(admId(item)),
            ),
            active: admIsActive(item),
          ),
        ],
      );

  Future<void> _edit(Map<String, dynamic>? item) async {
    final eas = await widget.api.getEasList();
    final moviles = await widget.api.getMovilesList();
    final estados = (await widget.api.getCatalogo('ESTADOS_ASIGNACION_MOVIL', limit: 200)).datos;
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
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createAsignacion(data)
          : await widget.api.updateAsignacion(admId(item), data);
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

class _AsignacionDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> eas;
  final List<Map<String, dynamic>> moviles;
  final List<Map<String, dynamic>> estados;
  const _AsignacionDialog(
      {this.item, required this.eas, required this.moviles, required this.estados});
  @override
  State<_AsignacionDialog> createState() => _AsignacionDialogState();
}

class _AsignacionDialogState extends State<_AsignacionDialog> {
  late final fecha = TextEditingController(
      text: admFormatDate(widget.item?['fecha_asignacion']?.toString() ??
          DateTime.now().toIso8601String()));
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
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nueva asignacion' : 'Editar asignacion',
        children: [
          admDropdown('EAS', widget.eas, easId, (v) => setState(() => easId = v)),
          admDropdown('Movil', widget.moviles, movilId, (v) => setState(() => movilId = v),
              labelBuilder: (m) => '${m['numero_movil']} ${m['placa'] ?? ''}'),
          admField(fecha, 'Fecha asignación (yyyy-mm-dd)'),
          admDropdown('Estado', widget.estados, estadoId, (v) => setState(() => estadoId = v)),
          admField(obs, 'Observación'),
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
