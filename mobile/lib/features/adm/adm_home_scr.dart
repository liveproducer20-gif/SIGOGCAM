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
      list.add(_TabDef(icon: Icons.groups_rounded, label: 'Personal', child: PersonalTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('catalogos.ver')) {
      list.add(_TabDef(icon: Icons.list_alt_rounded, label: 'Catálogos', child: CatalogosTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('roles.ver')) {
      list.add(_TabDef(icon: Icons.admin_panel_settings_rounded, label: 'Roles', child: RolesTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('lugares_servicio.ver')) {
      list.add(_TabDef(icon: Icons.place_rounded, label: 'Lugares', child: LugaresTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('rutas.ver')) {
      list.add(_TabDef(icon: Icons.map_rounded, label: 'Rutas', child: RutasTab(api: api)));
    }
    if (widget.user.hasPermission('personal.ver')) {
      list.add(_TabDef(icon: Icons.school_rounded, label: 'Grados', child: GradosTab(api: api)));
    }
    if (widget.user.hasPermission('eas.ver')) {
      list.add(_TabDef(icon: Icons.location_city_rounded, label: 'EAS', child: EasTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('moviles.ver')) {
      list.add(_TabDef(icon: Icons.directions_car_rounded, label: 'Móviles', child: MovilesTab(api: api, tabIndex: list.length)));
    }
    if (widget.user.hasPermission('moviles.asignar')) {
      list.add(_TabDef(icon: Icons.compare_arrows_rounded, label: 'Asignaciones', child: AsignacionesTab(api: api, tabIndex: list.length)));
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
    final curIdx = _tabCtrl.index;

    if (tabs.isEmpty) {
      return Scaffold(
        backgroundColor: AdmTokens.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: AdmTokens.grey300),
              const SizedBox(height: 16),
              Text('No tienes permisos de administración',
                style: TextStyle(fontSize: 16, color: AdmTokens.grey500)),
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
      body: Column(
        children: [
          // Header section
          _buildPageHeader(tabs[curIdx]),

          // Submenu
          _buildSubmenu(tabs),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                for (final tab in tabs)
                  RepaintBoundary(child: tab.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(_TabDef tab) {
    final user = widget.user;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdmTokens.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tab.icon, color: AdmTokens.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Administración', style: AdmTokens.h2),
              const SizedBox(height: 2),
              Text('Gestión centralizada de usuarios y catálogos institucionales.',
                style: AdmTokens.subtitle),
            ],
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onNotifications,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdmTokens.grey50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined, size: 20, color: AdmTokens.grey600),
              ),
            ),
          ),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 20,
            backgroundColor: AdmTokens.primary,
            child: Text(
              _initials(user),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.nombreCompleto,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdmTokens.grey800)),
              const SizedBox(height: 1),
              Text(user.rol,
                style: const TextStyle(fontSize: 12, color: AdmTokens.grey500)),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(AppUser user) {
    final parts = user.nombreCompleto.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'U';
  }

  Widget _buildSubmenu(List<_TabDef> tabs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AdmTokens.cardShadow,
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: tabs.length,
          itemBuilder: (context, i) => _buildTabItem(tabs[i], i),
        ),
      ),
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
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive
                ? AdmTokens.primary
                : isHovered
                    ? AdmTokens.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : isHovered
                        ? AdmTokens.primary
                        : AdmTokens.grey400,
              ),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : isHovered
                          ? AdmTokens.primary
                          : AdmTokens.grey500,
                ),
              ),
              if (isActive)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.arrow_drop_up_rounded, size: 16, color: Colors.white70),
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
