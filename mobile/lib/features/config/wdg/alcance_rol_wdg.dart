import 'package:flutter/material.dart';

import '../config_api.dart';
import '../config_mdl.dart';

class AlcanceRolWdg extends StatefulWidget {
  final List<RolModel> roles;

  const AlcanceRolWdg({super.key, required this.roles});

  @override
  State<AlcanceRolWdg> createState() => _AlcanceRolWdgState();
}

class _AlcanceRolWdgState extends State<AlcanceRolWdg> {
  final ConfigApi _api = ConfigApi();
  RolModel? _selectedRol;
  List<ScopeModel> _items = [];
  bool _loading = false;

  Future<void> _load() async {
    if (_selectedRol == null) return;
    setState(() => _loading = true);
    try {
      _items = await _api.getAlcanceRol(_selectedRol!.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selectedRol == null) return;
    final items = _items
        .map((s) => {
              'modulo': s.modulo,
              'alcance': s.alcance,
              'entidad': s.entidad,
              'condicion_adicional': s.condicionAdicional,
            })
        .toList();
    try {
      await _api.guardarAlcanceRol(_selectedRol!.id, items);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alcance de datos guardado')),
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
            child: Center(child: Text('Seleccione un rol para configurar su alcance de datos')),
          )
        else
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Sin configuración de alcance'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildCard(_items[index], index),
                  ),
          ),
      ],
    );
  }

  Widget _buildCard(ScopeModel item, int index) {
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
                  child: Text(
                    '${item.modulo} / ${item.entidad}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _alcanceChip(item.alcance),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: item.alcance,
              decoration: const InputDecoration(
                labelText: 'Alcance',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
              ),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos los datos')),
                DropdownMenuItem(value: 'propio', child: Text('Solo propio')),
                DropdownMenuItem(value: 'unidad', child: Text('Misma unidad')),
                DropdownMenuItem(value: 'departamento', child: Text('Mismo departamento')),
                DropdownMenuItem(value: 'personalizado', child: Text('Personalizado')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _items[index] = ScopeModel(
                      id: item.id,
                      rolId: item.rolId,
                      modulo: item.modulo,
                      alcance: v,
                      entidad: item.entidad,
                      condicionAdicional: item.condicionAdicional,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _alcanceChip(String alcance) {
    final color = switch (alcance) {
      'todos' => Colors.green,
      'propio' => Colors.orange,
      'unidad' => Colors.blue,
      'departamento' => Colors.purple,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        alcance,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
