import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'adm_api.dart';
import 'adm_asignaciones_tab.dart';
import 'adm_catalogos_tab.dart';
import 'adm_eas_tab.dart';
import 'adm_lugares_tab.dart';
import 'adm_moviles_tab.dart';
import 'adm_personal_tab.dart';
import 'adm_roles_tab.dart';
import 'adm_rutas_tab.dart';

class AdmHomeScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final bool showBack;

  const AdmHomeScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
    this.showBack = false,
  });

  @override
  State<AdmHomeScr> createState() => _AdmHomeScrState();
}

class _AdmHomeScrState extends State<AdmHomeScr> {
  final api = AdmApi();
  List<_TabDef>? _cachedTabs;

  List<_TabDef> _buildTabs() {
    final list = <_TabDef>[];
    if (widget.user.hasPermission('personal.ver')) {
      list.add(_TabDef(
        icon: Icons.groups_outlined, label: 'Personal',
        child: PersonalTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('catalogos.ver')) {
      list.add(_TabDef(
        icon: Icons.list_alt_outlined, label: 'Catalogos',
        child: CatalogosTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('roles.ver')) {
      list.add(_TabDef(
        icon: Icons.admin_panel_settings_outlined, label: 'Roles',
        child: RolesTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('lugares_servicio.ver')) {
      list.add(_TabDef(
        icon: Icons.place_outlined, label: 'Lugares',
        child: LugaresTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('rutas.ver')) {
      list.add(_TabDef(
        icon: Icons.map_outlined, label: 'Rutas',
        child: RutasTab(api: api),
      ));
    }
    if (widget.user.hasPermission('eas.ver')) {
      list.add(_TabDef(
        icon: Icons.location_city_outlined, label: 'EAS',
        child: EasTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('moviles.ver')) {
      list.add(_TabDef(
        icon: Icons.directions_car_outlined, label: 'Moviles',
        child: MovilesTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('moviles.asignar')) {
      list.add(_TabDef(
        icon: Icons.compare_arrows_outlined, label: 'Asignaciones',
        child: AsignacionesTab(api: api, tabIndex: list.length),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    _cachedTabs ??= _buildTabs();
    final tabs = _cachedTabs!;
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppThm.bgClr,
        appBar: TopBarWdg(
          ttl: 'Administracion',
          user: widget.user,
          onUserChanged: widget.onUserChanged,
          onLogout: widget.onLogout,
          onNotifications: widget.onNotifications,
          leading: widget.showBack
              ? IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Salir',
                )
              : null,
        ),
        body: tabs.isEmpty
            ? const Center(child: Text('No tienes permisos de administración'))
            : Column(
                children: [
                  const SizedBox(height: 18),
                  TabBar(
                    isScrollable: true,
                    labelColor: AppThm.priClr,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: AppThm.secClr,
                    tabs: [
                      for (final tab in tabs)
                        Tab(icon: Icon(tab.icon), text: tab.label),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final tab in tabs)
                          RepaintBoundary(child: tab.child),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  final Widget child;
  const _TabDef({required this.icon, required this.label, required this.child});
}
