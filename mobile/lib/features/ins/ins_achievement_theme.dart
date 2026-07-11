import 'package:flutter/material.dart';
import 'badge_catalog.dart';

// ── NEW 10-LEVEL THEME SYSTEM ────────────────────

class LevelTheme {
  final int nivel;
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final Color borderColor;
  final Color textColor;
  final Color progressColor;
  final Color glowColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color titleColor;
  final Color dividerColor;
  final Color subtitleColor;
  final List<Color> confettiColors;
  final List<Color> particleColors;

  const LevelTheme({
    required this.nivel,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.borderColor,
    required this.textColor,
    required this.progressColor,
    required this.glowColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.titleColor,
    required this.dividerColor,
    required this.subtitleColor,
    required this.confettiColors,
    required this.particleColors,
  });

  static const List<LevelTheme> all = [
    nivel1, nivel2, nivel3, nivel4, nivel5,
    nivel6, nivel7, nivel8, nivel9, nivel10,
  ];

  static LevelTheme forNivel(int nivel) {
    if (nivel < 1 || nivel > 10) return nivel1;
    return all[nivel - 1];
  }

  static LevelTheme forMeta(int metaCartillas) {
    final badge = BadgeCatalog.byMeta(metaCartillas);
    return forNivel(badge?.nivel ?? 1);
  }

  // N1 — Azul institucional + Amarillo
  static const nivel1 = LevelTheme(
    nivel: 1, name: 'Amateur',
    primaryColor: Color(0xFF0B2F6B),
    accentColor: Color(0xFFF6C343),
    bgGradientStart: Color(0xFF0B2F6B),
    bgGradientEnd: Color(0xFF164C9C),
    borderColor: Color(0xFF0B2F6B),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFFF6C343),
    glowColor: Color(0x30F6C343),
    buttonColor: Color(0xFFF6C343),
    buttonTextColor: Color(0xFF0B2F6B),
    titleColor: Color(0xFFF6C343),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFF6C343), Color(0xFFFFFFFF), Color(0xFFFFE082)],
    particleColors: [Color(0x80F6C343), Color(0x50FFFFFF)],
  );

  // N2 — Verde esmeralda
  static const nivel2 = LevelTheme(
    nivel: 2, name: 'Operativo',
    primaryColor: Color(0xFF1B7A4A),
    accentColor: Color(0xFF2ECC71),
    bgGradientStart: Color(0xFF1B7A4A),
    bgGradientEnd: Color(0xFF2ECC71),
    borderColor: Color(0xFF1B7A4A),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFF2ECC71),
    glowColor: Color(0x302ECC71),
    buttonColor: Color(0xFF2ECC71),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFF2ECC71),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF2ECC71), Color(0xFFFFFFFF), Color(0xFFA9DFBF)],
    particleColors: [Color(0x802ECC71), Color(0x50FFFFFF)],
  );

  // N3 — Azul cian
  static const nivel3 = LevelTheme(
    nivel: 3, name: 'Profesional',
    primaryColor: Color(0xFF0E7C8A),
    accentColor: Color(0xFF1ABC9C),
    bgGradientStart: Color(0xFF0E7C8A),
    bgGradientEnd: Color(0xFF1ABC9C),
    borderColor: Color(0xFF0E7C8A),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFF1ABC9C),
    glowColor: Color(0x301ABC9C),
    buttonColor: Color(0xFF1ABC9C),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFF1ABC9C),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF1ABC9C), Color(0xFFFFFFFF), Color(0xFFA3E4D7)],
    particleColors: [Color(0x801ABC9C), Color(0x50FFFFFF)],
  );

  // N4 — Morado
  static const nivel4 = LevelTheme(
    nivel: 4, name: 'Avanzado',
    primaryColor: Color(0xFF6C3483),
    accentColor: Color(0xFF8E44AD),
    bgGradientStart: Color(0xFF6C3483),
    bgGradientEnd: Color(0xFF8E44AD),
    borderColor: Color(0xFF6C3483),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFF8E44AD),
    glowColor: Color(0x308E44AD),
    buttonColor: Color(0xFF8E44AD),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFF8E44AD),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF8E44AD), Color(0xFFFFFFFF), Color(0xFFBB8FCE)],
    particleColors: [Color(0x808E44AD), Color(0x50FFFFFF)],
  );

  // N5 — Naranja
  static const nivel5 = LevelTheme(
    nivel: 5, name: 'Experto',
    primaryColor: Color(0xFFD35400),
    accentColor: Color(0xFFE67E22),
    bgGradientStart: Color(0xFFD35400),
    bgGradientEnd: Color(0xFFE67E22),
    borderColor: Color(0xFFD35400),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFFE67E22),
    glowColor: Color(0x30E67E22),
    buttonColor: Color(0xFFE67E22),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFFE67E22),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFE67E22), Color(0xFFFFFFFF), Color(0xFFFAD7A0)],
    particleColors: [Color(0x80E67E22), Color(0x50FFFFFF)],
  );

  // N6 — Rojo institucional
  static const nivel6 = LevelTheme(
    nivel: 6, name: 'Élite',
    primaryColor: Color(0xFF922B21),
    accentColor: Color(0xFFE74C3C),
    bgGradientStart: Color(0xFF922B21),
    bgGradientEnd: Color(0xFFE74C3C),
    borderColor: Color(0xFF922B21),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFFE74C3C),
    glowColor: Color(0x30E74C3C),
    buttonColor: Color(0xFFE74C3C),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFFE74C3C),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFE74C3C), Color(0xFFFFFFFF), Color(0xFFF1948A)],
    particleColors: [Color(0x80E74C3C), Color(0x50FFFFFF)],
  );

  // N7 — Bronce
  static const nivel7 = LevelTheme(
    nivel: 7, name: 'Leyenda',
    primaryColor: Color(0xFFA0522D),
    accentColor: Color(0xFFCD7F32),
    bgGradientStart: Color(0xFFA0522D),
    bgGradientEnd: Color(0xFFCD7F32),
    borderColor: Color(0xFFA0522D),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFFCD7F32),
    glowColor: Color(0x30CD7F32),
    buttonColor: Color(0xFFCD7F32),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFFCD7F32),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFCD7F32), Color(0xFFFFFFFF), Color(0xFFDEB887)],
    particleColors: [Color(0x80CD7F32), Color(0x50FFFFFF)],
  );

  // N8 — Plata
  static const nivel8 = LevelTheme(
    nivel: 8, name: 'Supremo',
    primaryColor: Color(0xFF7F8C8D),
    accentColor: Color(0xFFBDC3C7),
    bgGradientStart: Color(0xFF7F8C8D),
    bgGradientEnd: Color(0xFFBDC3C7),
    borderColor: Color(0xFF7F8C8D),
    textColor: Color(0xFF1F2937),
    progressColor: Color(0xFF95A5A6),
    glowColor: Color(0x30BDC3C7),
    buttonColor: Color(0xFFBDC3C7),
    buttonTextColor: Color(0xFF1F2937),
    titleColor: Color(0xFF95A5A6),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFBDC3C7), Color(0xFFFFFFFF), Color(0xFFD5DBDB)],
    particleColors: [Color(0x80BDC3C7), Color(0x50FFFFFF)],
  );

  // N9 — Azul oscuro premium
  static const nivel9 = LevelTheme(
    nivel: 9, name: 'Mítico',
    primaryColor: Color(0xFF0A1628),
    accentColor: Color(0xFF1A3A6B),
    bgGradientStart: Color(0xFF0A1628),
    bgGradientEnd: Color(0xFF1A3A6B),
    borderColor: Color(0xFF0A1628),
    textColor: Color(0xFFFFFFFF),
    progressColor: Color(0xFF4A7CC9),
    glowColor: Color(0x304A7CC9),
    buttonColor: Color(0xFF1A3A6B),
    buttonTextColor: Color(0xFFFFFFFF),
    titleColor: Color(0xFF4A7CC9),
    dividerColor: Color(0xFF2A3A5A),
    subtitleColor: Color(0xFF8A9ABF),
    confettiColors: [Color(0xFF4A7CC9), Color(0xFFFFFFFF), Color(0xFF7BA3E0)],
    particleColors: [Color(0x804A7CC9), Color(0x50FFFFFF)],
  );

  // N10 — Dorado premium
  static const nivel10 = LevelTheme(
    nivel: 10, name: 'Máximo',
    primaryColor: Color(0xFF8B6F00),
    accentColor: Color(0xFFFFD700),
    bgGradientStart: Color(0xFF8B6F00),
    bgGradientEnd: Color(0xFFFFD700),
    borderColor: Color(0xFF8B6F00),
    textColor: Color(0xFF1F2937),
    progressColor: Color(0xFFFFD700),
    glowColor: Color(0x30FFD700),
    buttonColor: Color(0xFFFFD700),
    buttonTextColor: Color(0xFF1F2937),
    titleColor: Color(0xFFFFD700),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFFFF9C4)],
    particleColors: [Color(0x80FFD700), Color(0x50FFFFFF)],
  );
}

// ── BACKWARD COMPATIBILITY ───────────────────────
// Keep old enum and old themes so existing code still compiles

enum AchievementRank {
  amateur, operativo, experimentado, profesional, elite, comandante, leyenda
}

@Deprecated('Use LevelTheme instead')
class AchievementTheme {
  final AchievementRank rank;
  final String nombre;
  final Color accentColor;
  final Color progressColor;
  final Color glowColor;
  final Color borderColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color titleColor;
  final Color dividerColor;
  final Color subtitleColor;
  final List<Color> confettiColors;
  final List<Color> particleColors;

  const AchievementTheme({
    required this.rank, required this.nombre,
    required this.accentColor, required this.progressColor,
    required this.glowColor, required this.borderColor,
    required this.buttonColor, required this.buttonTextColor,
    required this.titleColor, required this.dividerColor,
    required this.subtitleColor,
    required this.confettiColors, required this.particleColors,
  });

  static const List<AchievementTheme> all = [amateur, operativo, experimentado, profesional, elite, comandante, leyenda];

  @Deprecated('Use LevelTheme.forMeta()')
  static AchievementTheme forCartillas(int metaCartillas) {
    if (metaCartillas <= 25) return all[0];
    if (metaCartillas <= 50) return all[1];
    if (metaCartillas <= 100) return all[2];
    if (metaCartillas <= 200) return all[3];
    if (metaCartillas <= 400) return all[4];
    if (metaCartillas <= 800) return all[5];
    return all[6];
  }

  static const Color instBlue = Color(0xFF0B2F6B);
  static const Color instBlueL = Color(0xFF164C9C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF8FAFE);

  static const amateur = AchievementTheme(
    rank: AchievementRank.amateur, nombre: 'Amateur',
    accentColor: Color(0xFFF6C343), progressColor: Color(0xFFF6C343),
    glowColor: Color(0x30F6C343), borderColor: instBlue,
    buttonColor: Color(0xFFF6C343), buttonTextColor: instBlue,
    titleColor: Color(0xFFF6C343), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFF6C343), white, Color(0xFFFFE082)],
    particleColors: [Color(0x80F6C343), Color(0x50FFFFFF)],
  );
  static const operativo = AchievementTheme(
    rank: AchievementRank.operativo, nombre: 'Operativo',
    accentColor: Color(0xFF2ECC71), progressColor: Color(0xFF2ECC71),
    glowColor: Color(0x302ECC71), borderColor: instBlue,
    buttonColor: Color(0xFF2ECC71), buttonTextColor: white,
    titleColor: Color(0xFF2ECC71), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF2ECC71), white, Color(0xFFA9DFBF)],
    particleColors: [Color(0x802ECC71), Color(0x50FFFFFF)],
  );
  static const experimentado = AchievementTheme(
    rank: AchievementRank.experimentado, nombre: 'Experimentado',
    accentColor: Color(0xFF1ABC9C), progressColor: Color(0xFF1ABC9C),
    glowColor: Color(0x301ABC9C), borderColor: instBlue,
    buttonColor: Color(0xFF1ABC9C), buttonTextColor: white,
    titleColor: Color(0xFF1ABC9C), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF1ABC9C), white, Color(0xFFA3E4D7)],
    particleColors: [Color(0x801ABC9C), Color(0x50FFFFFF)],
  );
  static const profesional = AchievementTheme(
    rank: AchievementRank.profesional, nombre: 'Profesional',
    accentColor: Color(0xFF0CBAA4), progressColor: Color(0xFF0CBAA4),
    glowColor: Color(0x300CBAA4), borderColor: instBlue,
    buttonColor: Color(0xFF0CBAA4), buttonTextColor: white,
    titleColor: Color(0xFF0CBAA4), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF0CBAA4), white, Color(0xFFA3E4D7)],
    particleColors: [Color(0x800CBAA4), Color(0x50FFFFFF)],
  );
  static const elite = AchievementTheme(
    rank: AchievementRank.elite, nombre: 'Élite',
    accentColor: Color(0xFF8E44AD), progressColor: Color(0xFF8E44AD),
    glowColor: Color(0x308E44AD), borderColor: instBlue,
    buttonColor: Color(0xFF8E44AD), buttonTextColor: white,
    titleColor: Color(0xFF8E44AD), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF8E44AD), white, Color(0xFFBB8FCE)],
    particleColors: [Color(0x808E44AD), Color(0x50FFFFFF)],
  );
  static const comandante = AchievementTheme(
    rank: AchievementRank.comandante, nombre: 'Comandante',
    accentColor: Color(0xFFBDC3C7), progressColor: Color(0xFF95A5A6),
    glowColor: Color(0x30BDC3C7), borderColor: instBlue,
    buttonColor: Color(0xFFBDC3C7), buttonTextColor: instBlue,
    titleColor: Color(0xFF95A5A6), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFBDC3C7), white, Color(0xFFD5DBDB)],
    particleColors: [Color(0x80BDC3C7), Color(0x50FFFFFF)],
  );
  static const leyenda = AchievementTheme(
    rank: AchievementRank.leyenda, nombre: 'Leyenda',
    accentColor: Color(0xFFF1C40F), progressColor: Color(0xFFF1C40F),
    glowColor: Color(0x30F1C40F), borderColor: instBlue,
    buttonColor: Color(0xFFF1C40F), buttonTextColor: instBlue,
    titleColor: Color(0xFFF1C40F), dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFF1C40F), white, Color(0xFFFFF9C4)],
    particleColors: [Color(0x80F1C40F), Color(0x50FFFFFF)],
  );
}
