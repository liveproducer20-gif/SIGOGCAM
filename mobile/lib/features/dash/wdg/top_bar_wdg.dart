import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/thm/app_thm.dart';
import '../../../core/wdg/responsive.dart';
import '../../profile/profile_menu_wdg.dart';

class TopBarWdg extends StatelessWidget implements PreferredSizeWidget {
  final String ttl;
  final AppUser? user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final Widget? leading;

  const TopBarWdg({
    super.key,
    required this.ttl,
    this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    return AppBar(
      backgroundColor: AppThm.priClr,
      elevation: 0,
      centerTitle: false,
      leading: leading,
      title: Text(
        ttl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: isMobile ? 17 : 20,
        ),
      ),
      actions: [
        if (user != null)
          ProfileMenuWdg(
            user: user!,
            onUserChanged: onUserChanged,
            onLogout: onLogout,
            onNotifications: onNotifications,
          ),
      ],
    );
  }
}
