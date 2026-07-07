import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../mdl/evt_mdl.dart';
import 'evt_estado_style.dart';

class EvtTblWdg extends StatelessWidget {
  final List<EvtMdl> items;
  final void Function(EvtMdl evt, String estado)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;

  const EvtTblWdg({
    super.key,
    required this.items,
    this.onEstado,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 36,
                horizontalMargin: 30,
                headingRowColor: WidgetStateProperty.all(
                  AppThm.priClr.withValues(alpha: 0.08),
                ),
                columns: const [
                  DataColumn(label: Text('Evento')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Convocados'), numeric: true),
                  DataColumn(label: Text('Confirmados'), numeric: true),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acción')),
                ],
                rows: items.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(e.nom)),
                      DataCell(Text(e.tipo)),
                      DataCell(Text(e.fecha)),
                      DataCell(Text(e.hora)),
                      DataCell(Text('${e.convocados}')),
                      DataCell(Text('${e.confirmados}')),
                      DataCell(
                        Chip(
                          label: Text(EvtEstadoStyle.label(e.estado)),
                          backgroundColor: EvtEstadoStyle.background(e.estado),
                          labelStyle: TextStyle(
                            color: EvtEstadoStyle.color(e.estado),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Align(
                          alignment: Alignment.center,
                          child: onEstado == null
                              ? const Icon(Icons.visibility_outlined)
                              : _EvtActionsMenu(
                                  evt: e,
                                  onEstado: onEstado,
                                  onEditar: onEditar,
                                  onEliminar: onEliminar,
                                ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EvtActionsMenu extends StatelessWidget {
  final EvtMdl evt;
  final void Function(EvtMdl evt, String estado)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;

  const _EvtActionsMenu({
    required this.evt,
    this.onEstado,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        if (action.startsWith('estado:')) {
          onEstado?.call(evt, action.substring(7));
        } else if (action == 'editar') {
          onEditar?.call(evt);
        } else if (action == 'eliminar') {
          onEliminar?.call(evt);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          enabled: false,
          child: Text('Estado'),
        ),
        PopupMenuItem(
          value: 'estado:PLANIFICADO',
          child: Text('Planificado'),
        ),
        PopupMenuItem(
          value: 'estado:EN_CURSO',
          child: Text('En curso'),
        ),
        PopupMenuItem(
          value: 'estado:FINALIZADO',
          child: Text('Finalizar'),
        ),
        PopupMenuItem(
          value: 'estado:CANCELADO',
          child: Text('Cancelar'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'editar',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline),
            title: Text('Eliminar'),
          ),
        ),
      ],
    );
  }
}
