import 'package:flutter/material.dart';

import '../config_api.dart';
import '../config_mdl.dart';

class AuditoriaWdg extends StatefulWidget {
  final List<RolModel> roles;

  const AuditoriaWdg({super.key, required this.roles});

  @override
  State<AuditoriaWdg> createState() => _AuditoriaWdgState();
}

class _AuditoriaWdgState extends State<AuditoriaWdg> {
  final ConfigApi _api = ConfigApi();
  List<AuditoriaModel> _items = [];
  bool _loading = false;
  int? _filterRolId;
  final String _filterAccion = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _api.getAuditoria(rolId: _filterRolId, accion: _filterAccion.isNotEmpty ? _filterAccion : null, limite: 100);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _filterRolId,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Rol',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF0F4F8),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos los roles')),
                    ...widget.roles.where((r) => r.activo).map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)),
                    ),
                  ],
                  onChanged: (id) {
                    setState(() => _filterRolId = id);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                tooltip: 'Refrescar',
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Sin registros de auditoría'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildCard(_items[index]),
                  ),
          ),
      ],
    );
  }

  Widget _buildCard(AuditoriaModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _accionChip(item.accion),
                const SizedBox(width: 8),
                if (item.modulo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(item.modulo, style: const TextStyle(fontSize: 10)),
                  ),
                const Spacer(),
                if (item.creadoEn != null)
                  Text(
                    '${item.creadoEn!.day}/${item.creadoEn!.month}/${item.creadoEn!.year} ${item.creadoEn!.hour}:${item.creadoEn!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
            if (item.detalle != null) ...[
              const SizedBox(height: 4),
              Text(item.detalle!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
            if (item.rolId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Rol ID: ${item.rolId} | Usuario ID: ${item.usuarioId ?? "-"}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accionChip(String accion) {
    final color = switch (accion) {
      'crear_modulo' || 'crear_version' => Colors.green,
      'actualizar_modulo' || 'guardar_menu_rol' || 'guardar_alcance_rol' || 'guardar_campos_rol' => Colors.blue,
      'eliminar_modulo' => Colors.red,
      'restaurar_version' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(accion, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}
