import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import 'side_menu_wdg.dart';

class SideMenuConfig {
  SideMenuConfig._();

  static const definitions = <SideMenuItem>[
    SideMenuItem(
      destination: SideMenuDestination.dashboard,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      section: SideMenuSection.main,
    ),
    SideMenuItem(
      destination: SideMenuDestination.events,
      title: 'Eventos y anuncios',
      icon: Icons.event_outlined,
      section: SideMenuSection.main,
      requiredPermissions: ['eventos.ver', 'eventos.ver_convocado'],
    ),
    SideMenuItem(
      destination: SideMenuDestination.booklets,
      title: 'Cartillas',
      icon: Icons.description_outlined,
      section: SideMenuSection.main,
      requiredPermissions: ['cartillas.ver', 'cartillas.generar'],
    ),
    SideMenuItem(
      destination: SideMenuDestination.badges,
      title: 'Mis insignias',
      icon: Icons.workspace_premium_outlined,
      section: SideMenuSection.main,
      requiredPermissions: ['insignias.ver'],
    ),
    SideMenuItem(
      destination: SideMenuDestination.services,
      title: 'Servicios',
      icon: Icons.local_police_outlined,
      section: SideMenuSection.operational,
      requiredPermissions: ['servicios.ver', 'servicios.ver_asignado'],
      available: false,
      unavailableMessage: 'El módulo Servicios aún no está disponible.',
    ),
    SideMenuItem(
      destination: SideMenuDestination.operations,
      title: 'Operaciones',
      icon: Icons.security_outlined,
      section: SideMenuSection.operational,
      requiredPermissions: [
        'novedades.ver',
        'novedades.crear',
        'incidencias.ver',
        'asistencia.registrar',
      ],
      available: false,
      unavailableMessage: 'El módulo Operaciones aún no está disponible.',
    ),
    SideMenuItem(
      destination: SideMenuDestination.reports,
      title: 'Reportes',
      icon: Icons.bar_chart_outlined,
      section: SideMenuSection.reports,
      requiredPermissions: ['reportes.ver', 'reportes.exportar'],
      available: false,
      unavailableMessage: 'El módulo Reportes aún no está disponible.',
    ),
    SideMenuItem(
      destination: SideMenuDestination.statistics,
      title: 'Estadísticas',
      icon: Icons.insights_outlined,
      section: SideMenuSection.reports,
      requiredPermissions: ['estadisticas.ver'],
      available: false,
      unavailableMessage: 'El módulo Estadísticas aún no está disponible.',
    ),
    SideMenuItem(
      destination: SideMenuDestination.administration,
      title: 'Administración',
      icon: Icons.admin_panel_settings_outlined,
      section: SideMenuSection.settings,
      requiredPermissions: ['administracion.ver'],
    ),
    SideMenuItem(
      destination: SideMenuDestination.rolesPermisos,
      title: 'Roles, permisos y estructura',
      icon: Icons.settings_outlined,
      section: SideMenuSection.settings,
      requiredPermissions: ['configuracion.roles.gestionar'],
    ),
    SideMenuItem(
      destination: SideMenuDestination.support,
      title: 'Alertas / Soporte',
      icon: Icons.notifications_active_outlined,
      section: SideMenuSection.support,
    ),
  ];

  static List<SideMenuItem> forUser(AppUser user, {int supportBadge = 0}) {
    return definitions
        .map(
          (item) => item.resolveFor(
            user,
            badge: item.destination == SideMenuDestination.support
                ? supportBadge
                : null,
          ),
        )
        .where((item) => item.authorized)
        .toList(growable: false);
  }

  static List<SideMenuItem> fromApi(
    List<Map<String, dynamic>> raw,
    AppUser user, {
    int supportBadge = 0,
  }) {
    final flattened = <Map<String, dynamic>>[];
    void collect(List<Map<String, dynamic>> nodes) {
      for (final node in nodes) {
        flattened.add(node);
        final children = node['hijos'];
        if (children is List) {
          collect(
            children
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(),
          );
        }
      }
    }

    collect(raw);
    final items = <SideMenuItem>[];
    for (final node in flattened) {
      final code = node['codigo']?.toString().trim() ?? '';
      final destination = _destination(code) ?? SideMenuDestination.custom;
      if (destination == SideMenuDestination.custom) {
        items.add(
          SideMenuItem(
            destination: destination,
            title:
                node['etiqueta_personalizada']?.toString().trim().isNotEmpty ==
                    true
                ? node['etiqueta_personalizada'].toString()
                : node['nombre']?.toString() ?? code,
            icon: _icon(node['icono']?.toString()) ?? Icons.extension_outlined,
            section: SideMenuSection.main,
            moduleCode: code,
            route: node['ruta']?.toString(),
          ),
        );
        continue;
      }
      final definition = definitions.firstWhere(
        (item) => item.destination == destination,
      );
      final resolved = definition.resolveFor(
        user,
        badge: destination == SideMenuDestination.support ? supportBadge : null,
      );
      // La estructura ya fue autorizada por el backend usando el rol real del
      // usuario. Los permisos granulares controlan si el destino se puede abrir,
      // pero no deben ocultar un menu que el administrador hizo visible.
      final hasAccess = resolved.authorized;
      items.add(
        SideMenuItem(
          destination: destination,
          title:
              node['etiqueta_personalizada']?.toString().trim().isNotEmpty ==
                  true
              ? node['etiqueta_personalizada'].toString()
              : node['nombre']?.toString() ?? resolved.title,
          icon: _icon(node['icono']?.toString()) ?? resolved.icon,
          section: destination == SideMenuDestination.administration
              ? SideMenuSection.settings
              : resolved.section,
          requiredPermissions: resolved.requiredPermissions,
          requireAllPermissions: resolved.requireAllPermissions,
          available: resolved.available && hasAccess,
          authorized: true,
          unavailableMessage: hasAccess
              ? resolved.unavailableMessage
              : 'No tienes permisos para acceder a este modulo.',
          badge: resolved.badge,
          moduleCode: code,
          route: node['ruta']?.toString(),
        ),
      );
    }
    return items.toList(growable: false);
  }

  static SideMenuDestination? _destination(String? rawCode) =>
      switch (rawCode?.trim().toLowerCase()) {
        'dashboard' => SideMenuDestination.dashboard,
        'eventos_anuncios' => SideMenuDestination.events,
        'cartillas' => SideMenuDestination.booklets,
        'insignias' => SideMenuDestination.badges,
        'servicios' => SideMenuDestination.services,
        'operaciones' => SideMenuDestination.operations,
        'reportes' => SideMenuDestination.reports,
        'estadisticas' => SideMenuDestination.statistics,
        'administracion' => SideMenuDestination.administration,
        'roles_permisos' => SideMenuDestination.rolesPermisos,
        'configuracion' => SideMenuDestination.rolesPermisos,
        'soporte' => SideMenuDestination.support,
        _ => null,
      };

  static IconData? _icon(String? value) => switch (value) {
    'dashboard_outlined' => Icons.dashboard_outlined,
    'event_outlined' => Icons.event_outlined,
    'description_outlined' => Icons.description_outlined,
    'workspace_premium_outlined' => Icons.workspace_premium_outlined,
    'local_police_outlined' => Icons.local_police_outlined,
    'security_outlined' => Icons.security_outlined,
    'bar_chart_outlined' => Icons.bar_chart_outlined,
    'insights_outlined' => Icons.insights_outlined,
    'admin_panel_settings_outlined' => Icons.admin_panel_settings_outlined,
    'settings_outlined' => Icons.settings_outlined,
    'notifications_active_outlined' => Icons.notifications_active_outlined,
    _ => null,
  };
}
