import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/thm/app_thm.dart';
import '../../profile/profile_menu_wdg.dart';

enum SideMenuSection { main, operational, reports, settings, support }

enum SideMenuDestination {
  dashboard,
  events,
  booklets,
  badges,
  services,
  operations,
  reports,
  statistics,
  administration,
  rolesPermisos,
  support,
  custom,
}

class SideMenuItem {
  final SideMenuDestination destination;
  final String title;
  final IconData icon;
  final SideMenuSection section;
  final List<String> requiredPermissions;
  final bool requireAllPermissions;
  final bool available;
  final bool authorized;
  final String? unavailableMessage;
  final int badge;
  final String? moduleCode;
  final String? route;

  const SideMenuItem({
    required this.destination,
    required this.title,
    required this.icon,
    required this.section,
    this.requiredPermissions = const [],
    this.requireAllPermissions = false,
    this.available = true,
    this.authorized = true,
    this.unavailableMessage,
    this.badge = 0,
    this.moduleCode,
    this.route,
  });

  bool get enabled => available && authorized;

  SideMenuItem resolveFor(AppUser user, {int? badge}) => SideMenuItem(
    destination: destination,
    title: title,
    icon: icon,
    section: section,
    requiredPermissions: requiredPermissions,
    requireAllPermissions: requireAllPermissions,
    available: available,
    authorized:
        requiredPermissions.isEmpty ||
        (requireAllPermissions
            ? user.permissions.containsAll(requiredPermissions)
            : user.permissions.containsAny(requiredPermissions)),
    unavailableMessage: unavailableMessage,
    badge: badge ?? this.badge,
    moduleCode: moduleCode,
    route: route,
  );

  String get pageKey =>
      moduleCode == null ? destination.name : '${destination.name}:$moduleCode';
}

class SideMenuWdg extends StatelessWidget {
  final bool menuOpen;
  final int idxSel;
  final List<SideMenuItem> items;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;

  const SideMenuWdg({
    super.key,
    required this.menuOpen,
    required this.idxSel,
    required this.items,
    required this.onMenuTap,
    required this.onItemTap,
    required this.onLogout,
    required this.user,
    this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      width: menuOpen ? 280 : 72,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF082F6B), Color(0xFF061F48)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -28,
                  bottom: 120,
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 190,
                    color: Color(0x0FFFFFFF),
                  ),
                ),
                Column(
                  children: [
                    _MenuHeader(open: menuOpen, onToggle: onMenuTap),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                        children: _menuChildren(),
                      ),
                    ),
                    _UserCard(
                      open: menuOpen,
                      user: user,
                      onUserChanged: onUserChanged,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      child: _LogoutTile(open: menuOpen, onTap: onLogout),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _menuChildren() {
    const groups = [
      (SideMenuSection.main, 'MENÚ PRINCIPAL'),
      (SideMenuSection.operational, 'OPERATIVO'),
      (SideMenuSection.reports, 'ANÁLISIS'),
      (SideMenuSection.settings, 'CONFIGURACIÓN'),
    ];
    return [
      for (final group in groups) ...[
        if (items.any((item) => item.section == group.$1)) ...[
          if (menuOpen) _SectionLabel(group.$2),
          for (final entry in items.indexed)
            if (entry.$2.section == group.$1)
              _MenuTile(
                item: entry.$2,
                selected: entry.$1 == idxSel,
                open: menuOpen,
                onTap: () => onItemTap(entry.$1),
              ),
          const SizedBox(height: 8),
        ],
      ],
      for (final entry in items.indexed)
        if (entry.$2.section == SideMenuSection.support) ...[
          const Divider(color: Colors.white12, height: 12),
          _MenuTile(
            item: entry.$2,
            selected: idxSel == entry.$1,
            open: menuOpen,
            onTap: () => onItemTap(entry.$1),
          ),
        ],
    ];
  }
}

class _MenuHeader extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  const _MenuHeader({required this.open, required this.onToggle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(open ? 16 : 8, 12, 8, 8),
    child: Row(
      mainAxisAlignment: open
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: [
        if (open)
          Expanded(
            child: Column(
              children: [
                Image.asset(
                  'assets/img/logo_segura.png',
                  width: 88,
                  height: 88,
                ),
                const Text(
                  'SIGO-GCAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        Material(
          color: Colors.white.withValues(alpha: .09),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: open ? 'Contraer menú' : 'Expandir menú',
            onPressed: onToggle,
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 7),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8FA9CA),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.15,
      ),
    ),
  );
}

class _MenuTile extends StatefulWidget {
  final SideMenuItem item;
  final bool selected;
  final bool open;
  final VoidCallback onTap;
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.open,
    required this.onTap,
  });
  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: widget.item.enabled ? 1 : .58,
    child: MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Tooltip(
        message: widget.open ? '' : widget.item.title,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF0D4E9B)
                : (hovered
                      ? Colors.white.withValues(alpha: .08)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(11),
            boxShadow: widget.selected
                ? const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
            border: Border(
              left: BorderSide(
                color: widget.selected ? AppThm.accClr : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            child: ListTile(
              dense: true,
              minLeadingWidth: 0,
              horizontalTitleGap: 12,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.open ? 12 : 17,
                vertical: 2,
              ),
              leading: Icon(
                widget.item.icon,
                size: 21,
                color: widget.selected ? AppThm.accClr : Colors.white70,
              ),
              title: widget.open
                  ? Text(
                      widget.item.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    )
                  : null,
              trailing: widget.open
                  ? widget.item.badge > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.item.badge > 99
                                  ? '99+'
                                  : '${widget.item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : !widget.item.enabled
                        ? const Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: Colors.white54,
                          )
                        : null
                  : null,
              onTap: widget.item.enabled ? widget.onTap : null,
            ),
          ),
        ),
      ),
    ),
  );
}

class _UserCard extends StatefulWidget {
  final bool open;
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  const _UserCard({required this.open, required this.user, this.onUserChanged});
  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  late final DateTime sessionStart = DateTime.now();
  String presence = 'En línea';

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final parts = user.nombreCompleto
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'U'
        : (parts.length == 1
                  ? parts.first[0]
                  : '${parts.first[0]}${parts.last[0]}')
              .toUpperCase();
    return PopupMenuButton<String>(
      tooltip: 'Opciones de usuario',
      offset: const Offset(12, -280),
      onSelected: _onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.person_outline),
            title: Text('Mi perfil'),
          ),
        ),
        PopupMenuItem(
          value: 'account',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.settings_outlined),
            title: Text('Mi cuenta'),
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.circle_outlined),
            title: Text('Estado'),
          ),
        ),
        PopupMenuItem(
          value: 'session',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Información de sesión'),
          ),
        ),
        PopupMenuItem(
          value: 'personalization',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.palette_outlined),
            title: Text('Personalización'),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        padding: EdgeInsets.all(widget.open ? 11 : 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppThm.accClr,
                  backgroundImage: user.fotoPerfilUrl?.isNotEmpty == true
                      ? NetworkImage(user.fotoPerfilUrl!)
                      : null,
                  child: user.fotoPerfilUrl?.isNotEmpty == true
                      ? null
                      : Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF082F6B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 1,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: _presenceColor,
                  ),
                ),
              ],
            ),
            if (widget.open) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombreCompleto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      user.rol,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB9C9DD),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '● $presence',
                      style: TextStyle(color: _presenceColor, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _presenceColor => switch (presence) {
    'Ausente' => const Color(0xFFFBBF24),
    'Ocupado' => const Color(0xFFF87171),
    'Invisible' => const Color(0xFF94A3B8),
    _ => const Color(0xFF22C55E),
  };

  Future<void> _onSelected(String action) async {
    if (action == 'profile' || action == 'account') {
      final updated = await showDialog<AppUser>(
        context: context,
        builder: (_) =>
            ProfileDialog(user: widget.user, editMode: action == 'account'),
      );
      if (updated != null) widget.onUserChanged?.call(updated);
      return;
    }
    if (action == 'status') {
      final selected = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Estado de disponibilidad'),
          children: [
            for (final item in const [
              'En línea',
              'Ausente',
              'Ocupado',
              'Invisible',
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: _colorFor(item)),
                    const SizedBox(width: 10),
                    Text(item),
                  ],
                ),
              ),
          ],
        ),
      );
      if (selected != null) setState(() => presence = selected);
      return;
    }
    if (action == 'session') {
      final now = DateTime.now();
      final elapsed = now.difference(sessionStart);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Información de sesión'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inicio de sesión: ${_formatDate(sessionStart)}'),
                Text('Último acceso: ${_formatDate(now)}'),
                const Text('Dirección IP: No proporcionada por la API'),
                Text('Dispositivo: ${Theme.of(context).platform.name}'),
                Text(
                  'Tiempo activo: ${elapsed.inHours} h ${elapsed.inMinutes.remainder(60)} min',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Personalización'),
        content: const Text(
          'La estructura está preparada para tema, tamaño de fuente, color de acento e idioma. Estas preferencias estarán disponibles próximamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String value) => switch (value) {
    'Ausente' => const Color(0xFFF59E0B),
    'Ocupado' => const Color(0xFFEF4444),
    'Invisible' => const Color(0xFF64748B),
    _ => const Color(0xFF22C55E),
  };
  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _LogoutTile extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _LogoutTile({required this.open, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    hoverColor: const Color(0x22EF4444),
    contentPadding: EdgeInsets.symmetric(horizontal: open ? 14 : 18),
    minLeadingWidth: 0,
    leading: const Icon(
      Icons.logout_rounded,
      size: 20,
      color: Color(0xFFFCA5A5),
    ),
    title: open
        ? const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          )
        : null,
    onTap: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Deseas cerrar la sesión actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );
      if (ok == true) onTap();
    },
  );
}
