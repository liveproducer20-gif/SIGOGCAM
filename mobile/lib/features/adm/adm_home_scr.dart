import 'package:flutter/material.dart';
import '../../core/auth/app_user.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'adm_api.dart';
import 'adm_asignaciones_tab.dart';
import 'adm_catalogos_tab.dart';
import 'adm_design_tokens.dart';
import 'adm_eas_tab.dart';
import 'adm_grados_tab.dart';
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

class _AdmHomeScrState extends State<AdmHomeScr> with TickerProviderStateMixin {
  final api = AdmApi();
  List<_TabDef>? _cachedTabs;
  late TabController _tabCtrl;
  int _hoveredTabIndex = -1;

  List<_TabDef> _buildTabs() {
    final list = <_TabDef>[];
    if (widget.user.hasPermission('personal.ver')) {
      list.add(
        _TabDef(
          icon: Icons.groups_rounded,
          label: 'Personal',
          child: PersonalTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('catalogos.ver')) {
      list.add(
        _TabDef(
          icon: Icons.list_alt_rounded,
          label: 'Catálogos',
          child: CatalogosTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('roles.ver')) {
      list.add(
        _TabDef(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Roles',
          child: RolesTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('lugares_servicio.ver')) {
      list.add(
        _TabDef(
          icon: Icons.place_rounded,
          label: 'Lugares',
          child: LugaresTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('rutas.ver')) {
      list.add(
        _TabDef(
          icon: Icons.map_rounded,
          label: 'Rutas',
          child: RutasTab(api: api),
        ),
      );
    }
    if (widget.user.hasPermission('personal.ver')) {
      list.add(
        _TabDef(
          icon: Icons.school_rounded,
          label: 'Grados',
          child: GradosTab(api: api),
        ),
      );
    }
    if (widget.user.hasPermission('eas.ver')) {
      list.add(
        _TabDef(
          icon: Icons.location_city_rounded,
          label: 'EAS',
          child: EasTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('moviles.ver')) {
      list.add(
        _TabDef(
          icon: Icons.directions_car_rounded,
          label: 'Móviles',
          child: MovilesTab(api: api, tabIndex: list.length),
        ),
      );
    }
    if (widget.user.hasPermission('moviles.asignar')) {
      list.add(
        _TabDef(
          icon: Icons.compare_arrows_rounded,
          label: 'Asignaciones',
          child: AsignacionesTab(api: api, tabIndex: list.length),
        ),
      );
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _cachedTabs ??= _buildTabs();
    _tabCtrl = TabController(length: _cachedTabs!.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _cachedTabs!;

    if (tabs.isEmpty) {
      return Scaffold(
        backgroundColor: AdmTokens.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AdmTokens.grey300,
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes permisos de administración',
                style: TextStyle(fontSize: 16, color: AdmTokens.grey500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdmTokens.background,
      appBar: TopBarWdg(
        ttl: 'Administración',
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AdmTokens.surface,
            borderRadius: BorderRadius.circular(AdmTokens.radiusLg),
            border: Border.all(color: AdmTokens.grey200),
            boxShadow: AdmTokens.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildSubmenu(tabs),
              const Divider(height: 1, color: AdmTokens.grey200),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [for (final tab in tabs) tab.child],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenu(List<_TabDef> tabs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 18,
              vertical: 6,
            ),
            itemCount: tabs.length,
            itemBuilder: (context, i) => _buildTabItem(tabs[i], i),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(_TabDef tab, int i) {
    final isActive = _tabCtrl.index == i;
    final isHovered = _hoveredTabIndex == i;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredTabIndex = i),
      onExit: (_) => setState(() => _hoveredTabIndex = -1),
      child: GestureDetector(
        onTap: () => _tabCtrl.animateTo(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AdmTokens.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 20,
                color: isActive
                    ? AdmTokens.primary
                    : isHovered
                    ? AdmTokens.primary.withValues(alpha: 0.6)
                    : AdmTokens.grey400,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AdmTokens.primary
                      : isHovered
                      ? AdmTokens.primary.withValues(alpha: 0.6)
                      : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
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
