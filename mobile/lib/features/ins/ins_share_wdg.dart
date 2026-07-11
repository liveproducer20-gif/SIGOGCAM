import 'package:flutter/material.dart';

import 'achievement_unlocked_card.dart';
import 'ins_mdl.dart';

/// Compatibility wrapper for callers that still construct the old share widget.
/// The visual experience and export logic now live in one reusable component.
class InsShareWdg extends StatelessWidget {
  final InsMdl insignia;
  final String nombreUsuario;

  const InsShareWdg({
    super.key,
    required this.insignia,
    required this.nombreUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return AchievementUnlockedCard(
      title: insignia.titulo,
      metaCartillas: insignia.metaCartillas,
      totalCartillas: insignia.totalAlDesbloquear ?? insignia.metaCartillas,
      userName: nombreUsuario,
      mode: AchievementCardMode.sharePreview,
    );
  }
}
