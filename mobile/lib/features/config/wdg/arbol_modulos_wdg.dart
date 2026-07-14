import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../config_mdl.dart';

class ArbolModulosWdg extends StatelessWidget {
  final List<ModuloModel> modulos;
  final int? selectedId;
  final ValueChanged<ModuloModel> onSelect;
  final VoidCallback onAdd;

  const ArbolModulosWdg({
    super.key,
    required this.modulos,
    this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final raices =
        modulos.where((m) => m.moduloPadreId == null).toList();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF082F6B),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Módulos del Sistema',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                onPressed: onAdd,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final mod in raices) _buildTile(context, mod, 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, ModuloModel mod, int depth) {
    final hijos = modulos.where((m) => m.moduloPadreId == mod.id).toList();
    final selected = mod.id == selectedId;
    return Column(
      children: [
        InkWell(
          onTap: () => onSelect(mod),
          child: Container(
            padding: EdgeInsets.only(
              left: 12.0 + depth * 16,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0D4E9B) : null,
              border: Border(
                left: BorderSide(
                  color: selected ? AppThm.accClr : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconFor(mod.icono),
                  size: 16,
                  color: selected ? AppThm.accClr : Colors.white70,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mod.nombre,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (!mod.activo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('INACT',
                        style: TextStyle(color: Colors.orange, fontSize: 9)),
                  ),
              ],
            ),
          ),
        ),
        for (final hijo in hijos) _buildTile(context, hijo, depth + 1),
      ],
    );
  }

  IconData _iconFor(String? icono) => switch (icono) {
        'event_outlined' => Icons.event_outlined,
        'description_outlined' => Icons.description_outlined,
        'workspace_premium_outlined' => Icons.workspace_premium_outlined,
        'admin_panel_settings_outlined' => Icons.admin_panel_settings_outlined,
        'settings_outlined' => Icons.settings_outlined,
        'people_outlined' => Icons.people_outlined,
        'security_outlined' => Icons.security_outlined,
        'notifications_active_outlined' => Icons.notifications_active_outlined,
        _ => Icons.folder_outlined,
      };
}
