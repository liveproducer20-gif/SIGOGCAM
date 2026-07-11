import 'package:flutter/material.dart';

import 'achievement_unlocked_card.dart';

void showShareAchievement(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required int metaCartillas,
  required int totalCartillas,
  required String nombreUsuario,
  String? nivelName,
}) {
  showAchievementCard(
    context,
    title: titulo,
    metaCartillas: metaCartillas,
    totalCartillas: totalCartillas,
    userName: nombreUsuario,
    mode: AchievementCardMode.sharePreview,
  );
}
