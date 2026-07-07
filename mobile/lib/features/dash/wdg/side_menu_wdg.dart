import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';

class SideMenuItem {
  final String title;
  final IconData icon;
  final bool enabled;

  const SideMenuItem({
    required this.title,
    required this.icon,
    required this.enabled,
  });
}

class SideMenuWdg extends StatelessWidget {
  final bool menuOpen;
  final int idxSel;
  final List<SideMenuItem> items;
  final VoidCallback onMenuTap;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  const SideMenuWdg({
    super.key,
    required this.menuOpen,
    required this.idxSel,
    required this.items,
    required this.onMenuTap,
    required this.onItemTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeInOut,
      width: menuOpen ? 280 : 72,
      child: Material(
        color: AppThm.priClr,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: menuOpen
                    ? Center(
                        key: const ValueKey('logo_open'),
                        child: Image.asset(
                          'assets/img/logo_segura.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('logo_closed'),
                        height: 0,
                      ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final selected = index == idxSel;

                    return ListTile(
                      dense: !menuOpen,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: menuOpen ? 16 : 20,
                      ),
                      minLeadingWidth: 0,
                      selected: selected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.12),
                      leading: Icon(
                        item.icon,
                        color: selected ? AppThm.accClr : Colors.white70,
                      ),
                      title: menuOpen
                          ? Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            )
                          : null,
                      trailing: menuOpen && !item.enabled
                          ? const Icon(
                              Icons.lock_outline,
                              color: Colors.white38,
                            )
                          : null,
                      onTap: () => onItemTap(index),
                    );
                  },
                ),
              ),

              const Divider(
                color: Colors.white24,
                height: 1,
              ),

              ListTile(
                dense: !menuOpen,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: menuOpen ? 16 : 20,
                ),
                minLeadingWidth: 0,
                leading: const Icon(
                  Icons.logout,
                  color: Colors.white70,
                ),
                title: menuOpen
                    ? const Text(
                        'Cerrar sesión',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      )
                    : null,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}