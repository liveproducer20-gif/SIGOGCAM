import 'package:flutter/material.dart';

import 'achievement_unlocked_card.dart';
import 'ins_mdl.dart';

class AchievementUnlockedDialog extends StatelessWidget {
  final InsigniaDesbloqueadaMdl insignia;
  final int? totalCartillas;
  final String? nombreUsuario;
  final VoidCallback? onContinue;
  final AchievementCardMode mode;

  const AchievementUnlockedDialog({
    super.key,
    required this.insignia,
    this.totalCartillas,
    this.nombreUsuario,
    this.onContinue,
    this.mode = AchievementCardMode.unlock,
  });

  @override
  Widget build(BuildContext context) {
    final meta = int.tryParse(insignia.icono) ?? 0;
    return AchievementUnlockedCard(
      title: insignia.titulo,
      metaCartillas: meta,
      totalCartillas: totalCartillas ?? meta,
      userName: nombreUsuario?.trim().isNotEmpty == true
          ? nombreUsuario!
          : 'Agente SIGO-GCAM',
      mode: mode,
      onContinue: onContinue,
    );
  }
}

class BadgeUnlockDialog extends AchievementUnlockedDialog {
  const BadgeUnlockDialog({
    super.key,
    required super.insignia,
    super.totalCartillas,
    super.nombreUsuario,
    super.onContinue,
    super.mode,
  });
}
