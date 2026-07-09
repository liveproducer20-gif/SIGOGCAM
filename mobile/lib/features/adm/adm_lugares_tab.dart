import 'package:flutter/material.dart';

import 'adm_api.dart';
import 'adm_crud_tab.dart';
import 'adm_helpers.dart';
import 'adm_widgets.dart';

class LugaresTab extends AdmCrudTab {
  const LugaresTab({super.key, required super.api});

  @override
  State<AdmCrudTab> createState() => _LugarState();
}

class _LugarState extends State<AdmCrudTab> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.getLugares();
  }

  @override
  Widget build(BuildContext context) => AdmAsyncTable(
        title: 'Lugares de servicio',
        subtitle: 'Puntos operativos organizados por ruta y distrito.',
        future: future,
        columns: const ['Ruta', 'Ubicacion', 'Distrito', 'Estado', 'Acciones'],
        onRefresh: _reload,
        onCreate: () => _edit(null),
        header: OutlinedButton.icon(
          onPressed: _showRutasManager,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Gestionar Rutas'),
        ),
        rowBuilder: (item) => [
          admText(item['ruta']),
          admText(item['direccion']),
          admText(item['distrito']),
          AdmStateChip(active: admIsActive(item)),
          AdmActions(
            onEdit: () => _edit(item),
            onToggle: () => _toggle(item),
            onDelete: () => _confirmDelete(
              item,
              'lugar ${item['direccion']}',
              () => widget.api.deleteLugar(admId(item)),
            ),
            active: admIsActive(item),
          ),
        ],
      );

  void _reload() {
    setState(() {
      future = widget.api.getLugares();
    });
  }

  void _showRutasManager() {
    showDialog(
      context: context,
      builder: (_) => _RutasManagerDialog(api: widget.api),
    );
  }

  Future<void> _edit(Map<String, dynamic>? item) async {
    final results = await Future.wait([
      admLoadCatalogs(widget.api),
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
