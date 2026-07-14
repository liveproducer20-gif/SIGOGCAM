import 'package:flutter/material.dart';

import '../config_mdl.dart';

class PreviewMenuWdg extends StatelessWidget {
  final List<RolMenuConfigModel> items;
  final String? rolNombre;

  const PreviewMenuWdg({
    super.key,
    this.items = const [],
    this.rolNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF082F6B), Color(0xFF061F48)],
        ),
      ),
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Vista previa${rolNombre != null ? ': $rolNombre' : ''}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('Seleccione un rol y agregue módulos',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final item in items)
                        _previewTile(item),
                    ],
                  ),
          ),
          if (items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Text(
                '${items.length} elemento(s) en el menú',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewTile(RolMenuConfigModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          minLeadingWidth: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          leading: Icon(
            _iconFor(item.icono),
            size: 18,
            color: Colors.white70,
          ),
          title: Text(
            item.etiquetaPersonalizada ?? item.moduloNombre ?? 'Item',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          trailing: item.visible == 0
              ? const Icon(Icons.visibility_off, color: Colors.white38, size: 14)
              : const SizedBox.shrink(),
        ),
      ),
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
        _ => Icons.circle_outlined,
      };
}
