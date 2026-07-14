import 'package:flutter/material.dart';

import '../config_api.dart';
import '../config_mdl.dart';

class VersionesWdg extends StatefulWidget {
  final List<RolModel> roles;

  const VersionesWdg({super.key, required this.roles});

  @override
  State<VersionesWdg> createState() => _VersionesWdgState();
}

class _VersionesWdgState extends State<VersionesWdg> {
  final ConfigApi _api = ConfigApi();
  RolModel? _selectedRol;
  List<VersionModel> _versiones = [];
  bool _loading = false;

  Future<void> _load() async {
    if (_selectedRol == null) return;
    setState(() => _loading = true);
    try {
      _versiones = await _api.getVersiones(_selectedRol!.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _crearVersion() async {
    if (_selectedRol == null) return;
    final descCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear versión'),
        content: TextField(
          controller: descCtl,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Ej: Configuración antes de cambios de horario',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.crearVersion(_selectedRol!.id, '{}', descripcion: descCtl.text.trim());
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versión creada')),
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

  Future<void> _restaurar(VersionModel v) async {
    if (_selectedRol == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar versión'),
        content: Text('¿Restaurar la versión ${v.version}${v.descripcion != null ? ': ${v.descripcion}' : ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.restaurarVersion(_selectedRol!.id, v.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versión restaurada')),
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
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva versión'),
                  onPressed: _crearVersion,
                ),
              ],
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_selectedRol == null)
          const Expanded(
            child: Center(child: Text('Seleccione un rol para ver su historial de versiones')),
          )
        else
          Expanded(
            child: _versiones.isEmpty
                ? const Center(child: Text('Sin versiones guardadas'))
                : ListView.builder(
                    itemCount: _versiones.length,
                    itemBuilder: (context, index) => _buildCard(_versiones[index]),
                  ),
          ),
      ],
    );
  }

  Widget _buildCard(VersionModel v) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: .15),
          child: Text('v${v.version}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        title: Text(v.descripcion ?? 'Versión ${v.version}', style: const TextStyle(fontSize: 13)),
        subtitle: v.creadoEn != null
            ? Text(
                '${v.creadoEn!.day}/${v.creadoEn!.month}/${v.creadoEn!.year} ${v.creadoEn!.hour}:${v.creadoEn!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.restore_outlined, size: 20),
          tooltip: 'Restaurar',
          onPressed: () => _restaurar(v),
        ),
      ),
    );
  }
}
