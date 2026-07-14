import 'package:flutter/material.dart';

import '../config_api.dart';
import '../config_mdl.dart';

class CamposRolWdg extends StatefulWidget {
  final List<RolModel> roles;

  const CamposRolWdg({super.key, required this.roles});

  @override
  State<CamposRolWdg> createState() => _CamposRolWdgState();
}

class _CamposRolWdgState extends State<CamposRolWdg> {
  final ConfigApi _api = ConfigApi();
  RolModel? _selectedRol;
  List<CampoPermisoModel> _items = [];
  bool _loading = false;

  Future<void> _load() async {
    if (_selectedRol == null) return;
    setState(() => _loading = true);
    try {
      _items = await _api.getCamposRol(_selectedRol!.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selectedRol == null) return;
    final items = _items
        .map((c) => {
              'campo_id': c.campoId,
              'puede_ver': c.puedeVer,
              'puede_editar': c.puedeEditar,
              'requerido': c.requerido,
            })
        .toList();
    try {
      await _api.guardarCamposRol(_selectedRol!.id, items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos de campos guardados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
                  initialValue: _selectedRol?.id,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Rol',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF0F4F8),
                  ),
                  isExpanded: true,
                  items: widget.roles
                      .where((r) => r.activo)
                      .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      setState(() {
                        _selectedRol = widget.roles.firstWhere((r) => r.id == id);
                      });
                      _load();
                    }
                  },
                ),
              ),
              if (_selectedRol != null) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  onPressed: _save,
                ),
              ],
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_selectedRol == null)
          const Expanded(
            child: Center(child: Text('Seleccione un rol para configurar sus campos')),
          )
        else
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Sin configuración de campos'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildCard(_items[index], index),
                  ),
          ),
      ],
    );
  }

  Widget _buildCard(CampoPermisoModel item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.campoNombre ?? 'Campo #${item.campoId}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (item.campoCodigo != null)
                        Text(
                          item.campoCodigo!,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (item.entidad != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.entidad!,
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _toggle('Ver', item.puedeVer, (v) {
                  setState(() => _items[index] = CampoPermisoModel(
                    id: item.id,
                    rolId: item.rolId,
                    campoId: item.campoId,
                    puedeVer: v,
                    puedeEditar: item.puedeEditar,
                    requerido: item.requerido,
                    campoNombre: item.campoNombre,
                    campoCodigo: item.campoCodigo,
                    tipoDato: item.tipoDato,
                    entidad: item.entidad,
                    seccion: item.seccion,
                  ));
                }),
                const SizedBox(width: 16),
                _toggle('Editar', item.puedeEditar, (v) {
                  setState(() => _items[index] = CampoPermisoModel(
                    id: item.id,
                    rolId: item.rolId,
                    campoId: item.campoId,
                    puedeVer: item.puedeVer,
                    puedeEditar: v,
                    requerido: item.requerido,
                    campoNombre: item.campoNombre,
                    campoCodigo: item.campoCodigo,
                    tipoDato: item.tipoDato,
                    entidad: item.entidad,
                    seccion: item.seccion,
                  ));
                }),
                const SizedBox(width: 16),
                _toggle('Requerido', item.requerido, (v) {
                  setState(() => _items[index] = CampoPermisoModel(
                    id: item.id,
                    rolId: item.rolId,
                    campoId: item.campoId,
                    puedeVer: item.puedeVer,
                    puedeEditar: item.puedeEditar,
                    requerido: v,
                    campoNombre: item.campoNombre,
                    campoCodigo: item.campoCodigo,
                    tipoDato: item.tipoDato,
                    entidad: item.entidad,
                    seccion: item.seccion,
                  ));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
