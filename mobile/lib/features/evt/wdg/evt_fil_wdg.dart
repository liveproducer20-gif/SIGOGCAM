import 'package:flutter/material.dart';

import '../../adm/adm_design_tokens.dart';

class EvtFilWdg extends StatelessWidget {
  final ValueChanged<String> onBuscar;
  final ValueChanged<String> onEstado;
  final ValueChanged<String> onTipo;

  const EvtFilWdg({
    super.key,
    required this.onBuscar,
    required this.onEstado,
    required this.onTipo,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final search = _searchField();
        final estado = _estadoField();
        final tipo = _tipoField();

        if (narrow) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              estado,
              const SizedBox(height: 12),
              tipo,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: search),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: estado),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: tipo),
          ],
        );
      },
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: onBuscar,
      decoration: InputDecoration(
        hintText: 'Buscar evento',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AdmTokens.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _estadoField() {
    return DropdownButtonFormField<String>(
      initialValue: 'Todos',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Estado',
        prefixIcon: const Icon(Icons.flag_outlined),
        filled: true,
        fillColor: AdmTokens.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'PLANIFICADO', child: Text('Planificado')),
        DropdownMenuItem(value: 'EN_CURSO', child: Text('En curso')),
        DropdownMenuItem(value: 'FINALIZADO', child: Text('Finalizado')),
        DropdownMenuItem(value: 'CANCELADO', child: Text('Cancelado')),
      ],
      selectedItemBuilder: (_) => const [
        Text('Todos', overflow: TextOverflow.ellipsis),
        Text('Planificado', overflow: TextOverflow.ellipsis),
        Text('En curso', overflow: TextOverflow.ellipsis),
        Text('Finalizado', overflow: TextOverflow.ellipsis),
        Text('Cancelado', overflow: TextOverflow.ellipsis),
      ],
      onChanged: (v) {
        if (v != null) onEstado(v);
      },
    );
  }

  Widget _tipoField() {
    return DropdownButtonFormField<String>(
      initialValue: 'Todos',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tipo',
        prefixIcon: const Icon(Icons.category_outlined),
        filled: true,
        fillColor: AdmTokens.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
        DropdownMenuItem(value: 'Capacitacion', child: Text('Capacitación')),
        DropdownMenuItem(value: 'Curso', child: Text('Curso')),
        DropdownMenuItem(value: 'Reunion', child: Text('Reunión')),
        DropdownMenuItem(value: 'Operativo', child: Text('Operativo')),
        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
      ],
      selectedItemBuilder: (_) => const [
        Text('Todos', overflow: TextOverflow.ellipsis),
        Text('Capacitación', overflow: TextOverflow.ellipsis),
        Text('Curso', overflow: TextOverflow.ellipsis),
        Text('Reunión', overflow: TextOverflow.ellipsis),
        Text('Operativo', overflow: TextOverflow.ellipsis),
        Text('Otro', overflow: TextOverflow.ellipsis),
      ],
      onChanged: (v) {
        if (v != null) onTipo(v);
      },
    );
  }
}
