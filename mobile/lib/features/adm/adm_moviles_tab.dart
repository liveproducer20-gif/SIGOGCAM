import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_lazy_tab.dart';
import 'adm_widgets.dart';

class MovilesTab extends AdmCrudTab {
  final int tabIndex;
  const MovilesTab({super.key, required super.api, this.tabIndex = 0});

  @override
  State<AdmCrudTab> createState() => _MovilState();
}

class _MovilState extends State<AdmCrudTab> with AdmLazyTabMixin<AdmCrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = Future.value([]);
    initLazy((widget as MovilesTab).tabIndex, () => future = widget.api.getMoviles());
  }

  void _reload() {
    setState(() {
      future = widget.api.getMoviles();
    });
  }

  @override
  Widget build(BuildContext context) => AdmAsyncTable(
        title: 'Moviles',
        subtitle: 'Unidades, kilometraje y mantenimiento preventivo.',
        future: future,
        columns: const ['Movil', 'Tipo', 'Km', 'Prox. mant.', 'Alerta', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        rowBuilder: (item) => [
          admText('${item['numero_movil'] ?? ''} ${item['placa'] ?? ''}'.trim()),
          admText(item['tipo']),
          admText(item['kilometraje_actual']),
          admText(item['proximo_mantenimiento']),
          AdmAlertText(text: item['estado_mantenimiento']?.toString()),
          AdmActions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            onDelete: () => _confirmDelete(
              item,
              'movil ${item['numero_movil']}',
              () => widget.api.deleteMovil(admId(item)),
            ),
            onHistory: () => _showHistory(item),
            active: admIsActive(item),
          ),
        ],
      );

  Future<void> _edit(Map<String, dynamic>? item) async {
    final catalogs = await admLoadCatalogs(widget.api);
    if (!mounted) return;
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MovilDialog(item: item, catalogs: catalogs),
    );
    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      item == null
          ? await widget.api.createMovil(data)
          : await widget.api.updateMovil(admId(item), data);
      _reload();
    });
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    await admSafeRun(context, () async {
      await widget.api.setMovilActivo(admId(item), !admIsActive(item));
      _reload();
    });
  }

  Future<void> _showHistory(Map<String, dynamic> item) async {
    final id = admId(item);
    final catalogs = await admLoadCatalogs(widget.api);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _MantenimientoDialog(
        movilId: id,
        movilLabel: '${item['numero_movil']} ${item['placa'] ?? ''}'.trim(),
        api: widget.api,
        catalogs: catalogs,
        onChanged: _reload,
      ),
    );
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

abstract class _BaseCatalogDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  const _BaseCatalogDialog({this.item, required this.catalogs});
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
  late final obsEstado = TextEditingController(text: _s('observacion_estado'));
  int? tipoId;
  int? estadoId;
  @override
  void initState() {
    super.initState();
    tipoId = _int('tipo_movil_id');
    estadoId = _int('estado_movil_id');
  }

  @override
  Widget build(BuildContext context) => AdmFormDialog(
        title: widget.item == null ? 'Nuevo movil' : 'Editar movil',
        children: [
          admField(numero, 'Número de móvil'),
          admField(placa, 'Placa'),
          admDropdown('Tipo', widget.catalogs['TIPOS_MOVIL'], tipoId, (v) => setState(() => tipoId = v)),
          admField(km, 'Kilometraje actual', number: true),
          admField(kmMant, 'Kilometraje último mantenimiento', number: true),
          admDropdown('Estado', widget.catalogs['ESTADOS_MOVIL'], estadoId, (v) => setState(() => estadoId = v)),
          admField(obsEstado, 'Observación del estado'),
          admField(obs, 'Observación general'),
        ],
        onSave: () => Navigator.pop(context, {
          'numeroMovil': numero.text.trim(),
          'placa': placa.text.trim(),
          'tipoMovilId': tipoId,
          'kilometrajeActual': int.tryParse(km.text) ?? 0,
          'kilometrajeUltimoMantenimiento': int.tryParse(kmMant.text) ?? 0,
          'estadoMovilId': estadoId,
          'observacion': obs.text.trim(),
          'observacionEstado': obsEstado.text.trim(),
        }),
      );
  String _s(String key, {String fallback = ''}) => widget.item?[key]?.toString() ?? fallback;
  int? _int(String key) => int.tryParse(widget.item?[key]?.toString() ?? '');
}

class _MantenimientoDialog extends StatefulWidget {
  final int movilId;
  final String movilLabel;
  final AdmApi api;
  final Map<String, List<Map<String, dynamic>>> catalogs;
  final VoidCallback onChanged;
  const _MantenimientoDialog({
    required this.movilId,
    required this.movilLabel,
    required this.api,
    required this.catalogs,
    required this.onChanged,
  });
  @override
  State<_MantenimientoDialog> createState() => _MantenimientoDialogState();
}

class _MantenimientoDialogState extends State<_MantenimientoDialog> {
  late Future<List<Map<String, dynamic>>> _mantenimientos;

  @override
  void initState() {
    super.initState();
    _mantenimientos = widget.api.getMantenimientos(widget.movilId);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Mantenimientos - ${widget.movilLabel}'),
        content: SizedBox(
          width: 600,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _mantenimientos,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final items = snap.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Historial de mantenimiento',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _nuevo,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin registros de mantenimiento'),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Km')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Descripción')),
                          ],
                          rows: items.map((r) => DataRow(cells: [
                            DataCell(admText(r['fecha_mantenimiento']?.toString().substring(0, 10) ?? '')),
                            DataCell(admText(r['kilometraje']?.toString() ?? '')),
                            DataCell(admText(r['tipo_mantenimiento']?.toString())),
                            DataCell(admText(r['descripcion']?.toString())),
                          ])).toList(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      );

  void _nuevo() async {
    final tipos = widget.catalogs['TIPOS_MANTENIMIENTO'] ?? [];
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final kmCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    int? tipoId;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar mantenimiento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fechaCtrl,
                decoration: const InputDecoration(labelText: 'Fecha (yyyy-mm-dd)'),
              ),
              TextField(
                controller: kmCtrl,
                decoration: const InputDecoration(labelText: 'Kilometraje'),
                keyboardType: TextInputType.number,
              ),
              if (tipos.isNotEmpty)
                admDropdown('Tipo mantenimiento', tipos, tipoId, (v) => tipoId = v, optional: true),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'fechaMantenimiento': fechaCtrl.text.trim(),
              'kilometraje': int.tryParse(kmCtrl.text) ?? 0,
              'tipoMantenimientoId': tipoId,
              'descripcion': descCtrl.text.trim(),
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (data == null) return;
    if (!mounted) return;
    await admSafeRun(context, () async {
      await widget.api.createMantenimiento(widget.movilId, data);
      setState(() {
        _mantenimientos = widget.api.getMantenimientos(widget.movilId);
      });
      widget.onChanged();
    });
  }
}
