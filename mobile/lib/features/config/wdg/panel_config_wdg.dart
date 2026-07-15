import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../config_mdl.dart';

class PanelConfigWdg extends StatefulWidget {
  final ModuloModel? modulo;
  final List<RolModel> roles;
  final int? selectedRolId;
  final List<RolMenuConfigModel> menuConfig;
  final ValueChanged<RolModel> onRolSelected;
  final ValueChanged<int> onAddModulo;
  final ValueChanged<int> onRemoveModulo;
  final ValueChanged<RolMenuConfigModel> onEditItem;
  final bool hasChanges;
  final bool saving;
  final VoidCallback onSave;

  const PanelConfigWdg({
    super.key,
    this.modulo,
    required this.roles,
    this.selectedRolId,
    this.menuConfig = const [],
    required this.onRolSelected,
    required this.onAddModulo,
    required this.onRemoveModulo,
    required this.onEditItem,
    required this.hasChanges,
    required this.saving,
    required this.onSave,
  });

  @override
  State<PanelConfigWdg> createState() => _PanelConfigWdgState();
}

class _PanelConfigWdgState extends State<PanelConfigWdg> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF082F6B),
          child: const Row(
            children: [
              Icon(Icons.tune_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Configuración',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _sectionLabel('Seleccionar Rol'),
              const SizedBox(height: 6),
              _rolSelector(),
              const SizedBox(height: 16),
              if (widget.modulo != null) ...[
                _sectionLabel('Módulo Seleccionado'),
                const SizedBox(height: 6),
                _moduleInfo(),
              ],
              const SizedBox(height: 16),
              if (widget.selectedRolId != null) ...[
                _sectionLabel(
                  'Menú del Rol (${widget.menuConfig.length} items)',
                ),
                const SizedBox(height: 6),
                ...widget.menuConfig.map(_menuItemTile),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.hasChanges && !widget.saving
                        ? widget.onSave
                        : null,
                    icon: widget.saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.hasChanges
                          ? 'Guardar menú del rol'
                          : 'Menú guardado',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF8FA9CA),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.15,
    ),
  );

  Widget _rolSelector() {
    return DropdownButtonFormField<int>(
      initialValue: widget.selectedRolId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFFF0F4F8),
      ),
      hint: const Text('Seleccione un rol'),
      items: widget.roles
          .where((r) => r.activo)
          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)))
          .toList(),
      onChanged: (id) {
        if (id != null) {
          final rol = widget.roles.firstWhere((r) => r.id == id);
          widget.onRolSelected(rol);
        }
      },
    );
  }

  Widget _moduleInfo() {
    final m = widget.modulo!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Código: ${m.codigo}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              'Ruta: ${m.ruta ?? "-"}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (widget.selectedRolId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _smallBtn(
                      icon: Icons.add,
                      label: 'Agregar al menú',
                      color: Colors.green,
                      onTap: () => widget.onAddModulo(m.id),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuItemTile(RolMenuConfigModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.visible == 1 ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: item.visible == 1 ? Colors.green : Colors.grey,
        ),
        title: Text(
          item.etiquetaPersonalizada ??
              item.moduloNombre ??
              'Item ${item.moduloId}',
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: item.moduloCodigo != null
            ? Text(
                'Nivel ${item.nivel} · Orden ${item.orden}',
                style: const TextStyle(fontSize: 10),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _smallBtn(icon: Icons.edit, onTap: () => widget.onEditItem(item)),
            const SizedBox(width: 4),
            _smallBtn(
              icon: Icons.remove_circle_outline,
              color: Colors.red,
              onTap: () => widget.onRemoveModulo(item.moduloId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallBtn({
    required IconData icon,
    VoidCallback? onTap,
    String? label,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color ?? AppThm.accClr),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color ?? AppThm.accClr),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
