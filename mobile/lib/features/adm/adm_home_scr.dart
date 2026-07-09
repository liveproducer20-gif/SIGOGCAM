import 'dart:async';

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

class _AdmHomeScrState extends State<AdmHomeScr> with SingleTickerProviderStateMixin {
  final api = AdmApi();
  late TabController _tabController;

  List<_TabDef> get _tabs {
    final list = <_TabDef>[];
    if (widget.user.hasPermission('personal.ver')) {
      list.add(_TabDef(
        icon: Icons.groups_outlined,
        label: 'Personal',
        child: PersonalTab(api: api),
      ));
    }
    if (widget.user.hasPermission('catalogos.ver')) {
      list.add(_TabDef(
        icon: Icons.list_alt_outlined,
        label: 'Catalogos',
        child: CatalogosTab(api: api),
      ));
    }
    if (widget.user.hasPermission('roles.ver')) {
      list.add(_TabDef(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Roles',
        child: RolesTab(api: api),
      ));
    }
    if (widget.user.hasPermission('lugares_servicio.ver')) {
      list.add(_TabDef(
        icon: Icons.place_outlined,
        label: 'Lugares',
        child: LugaresTab(api: api),
      ));
    }
    if (widget.user.hasPermission('rutas.ver')) {
      list.add(_TabDef(
        icon: Icons.map_outlined,
        label: 'Rutas',
        child: RutasTab(api: api),
      ));
    }
    if (widget.user.hasPermission('eas.ver')) {
      list.add(_TabDef(
        icon: Icons.location_city_outlined,
        label: 'EAS',
        child: EasTab(api: api),
      ));
    }
    if (widget.user.hasPermission('moviles.ver')) {
      list.add(_TabDef(
        icon: Icons.directions_car_outlined,
        label: 'Moviles',
        child: MovilesTab(api: api, tabIndex: list.length),
      ));
    }
    if (widget.user.hasPermission('moviles.asignar')) {
      list.add(_TabDef(
        icon: Icons.compare_arrows_outlined,
        label: 'Asignaciones',
        child: AsignacionesTab(api: api),
      ));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (_tabController.length != tabs.length) {
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this, initialIndex: oldIndex.clamp(0, tabs.length - 1));
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });
    }
    return Scaffold(
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
                  controller: _tabController,
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
                    controller: _tabController,
                    children: [
                      for (final tab in tabs)
                        _LoadingDelay(child: tab.child),
                    ],
                  ),
                ),
              ],
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

class _LoadingDelay extends StatefulWidget {
  final Widget child;
  const _LoadingDelay({required this.child});
  @override
  State<_LoadingDelay> createState() => _LoadingDelayState();
}

class _LoadingDelayState extends State<_LoadingDelay> with AutomaticKeepAliveClientMixin {
  bool _ready = false;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _ready = false;
    unawaited(_wait());
  }

  Future<void> _wait() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_ready) return widget.child;
    return const Center(child: CircularProgressIndicator());
  }
}
