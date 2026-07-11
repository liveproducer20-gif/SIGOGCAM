import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'badge_catalog.dart';

/// Renders the independent asset configured for an achievement.
///
/// Keeping the lookup here makes every badge consumer (dashboard, profile,
/// ranking, dialogs and sharing) use the same catalog without duplicating
/// visual rules.
class BadgeIcon extends StatelessWidget {
  final int metaCartillas;
  final double size;
  final bool unlocked;
  final int? nivel;

  const BadgeIcon({
    super.key,
    required this.metaCartillas,
    this.size = 68,
    this.unlocked = true,
    this.nivel,
  });

  @override
  Widget build(BuildContext context) {
    final badge = BadgeCatalog.byMeta(metaCartillas);

    if (badge == null) {
      return SizedBox.square(
        dimension: size,
        child: const Icon(Icons.workspace_premium_outlined),
      );
    }

    final image = SvgPicture.asset(
      badge.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: badge.name,
    );

    return SizedBox.square(
      dimension: size,
      child: unlocked
          ? image
          : Opacity(
              opacity: 0.48,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: image,
              ),
            ),
    );
  }
}
