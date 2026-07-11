import 'package:flutter/material.dart';

enum AchievementRank {
  amateur,
  operativo,
  experimentado,
  profesional,
  elite,
  comandante,
  leyenda,
}

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
    required this.rank,
    required this.nombre,
    required this.accentColor,
    required this.progressColor,
    required this.glowColor,
    required this.borderColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.titleColor,
    required this.dividerColor,
    required this.subtitleColor,
    required this.confettiColors,
    required this.particleColors,
  });

  static const List<AchievementTheme> all = [
    amateur,
    operativo,
    experimentado,
    profesional,
    elite,
    comandante,
    leyenda,
  ];

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
    rank: AchievementRank.amateur,
    nombre: 'Amateur',
    accentColor: Color(0xFFF6C343),
    progressColor: Color(0xFFF6C343),
    glowColor: Color(0x30F6C343),
    borderColor: instBlue,
    buttonColor: Color(0xFFF6C343),
    buttonTextColor: instBlue,
    titleColor: Color(0xFFF6C343),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFF6C343), white, Color(0xFFFFE082)],
    particleColors: [Color(0x80F6C343), Color(0x50FFFFFF)],
  );

  static const operativo = AchievementTheme(
    rank: AchievementRank.operativo,
    nombre: 'Operativo',
    accentColor: Color(0xFF2ECC71),
    progressColor: Color(0xFF2ECC71),
    glowColor: Color(0x302ECC71),
    borderColor: instBlue,
    buttonColor: Color(0xFF2ECC71),
    buttonTextColor: white,
    titleColor: Color(0xFF2ECC71),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF2ECC71), white, Color(0xFFA9DFBF)],
    particleColors: [Color(0x802ECC71), Color(0x50FFFFFF)],
  );

  static const experimentado = AchievementTheme(
    rank: AchievementRank.experimentado,
    nombre: 'Experimentado',
    accentColor: Color(0xFF1ABC9C),
    progressColor: Color(0xFF1ABC9C),
    glowColor: Color(0x301ABC9C),
    borderColor: instBlue,
    buttonColor: Color(0xFF1ABC9C),
    buttonTextColor: white,
    titleColor: Color(0xFF1ABC9C),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF1ABC9C), white, Color(0xFFA3E4D7)],
    particleColors: [Color(0x801ABC9C), Color(0x50FFFFFF)],
  );

  static const profesional = AchievementTheme(
    rank: AchievementRank.profesional,
    nombre: 'Profesional',
    accentColor: Color(0xFFE67E22),
    progressColor: Color(0xFFE67E22),
    glowColor: Color(0x30E67E22),
    borderColor: instBlue,
    buttonColor: Color(0xFFE67E22),
    buttonTextColor: white,
    titleColor: Color(0xFFE67E22),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFE67E22), white, Color(0xFFF0B27A)],
    particleColors: [Color(0x80E67E22), Color(0x50FFFFFF)],
  );

  static const elite = AchievementTheme(
    rank: AchievementRank.elite,
    nombre: 'Élite',
    accentColor: Color(0xFF8E44AD),
    progressColor: Color(0xFF8E44AD),
    glowColor: Color(0x308E44AD),
    borderColor: instBlue,
    buttonColor: Color(0xFF8E44AD),
    buttonTextColor: white,
    titleColor: Color(0xFF8E44AD),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFF8E44AD), white, Color(0xFFBB8FCE)],
    particleColors: [Color(0x808E44AD), Color(0x50FFFFFF)],
  );

  static const comandante = AchievementTheme(
    rank: AchievementRank.comandante,
    nombre: 'Comandante',
    accentColor: Color(0xFFBDC3C7),
    progressColor: Color(0xFF95A5A6),
    glowColor: Color(0x30BDC3C7),
    borderColor: instBlue,
    buttonColor: Color(0xFFBDC3C7),
    buttonTextColor: instBlue,
    titleColor: Color(0xFF95A5A6),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFBDC3C7), white, Color(0xFFD5DBDB)],
    particleColors: [Color(0x80BDC3C7), Color(0x50FFFFFF)],
  );

  static const leyenda = AchievementTheme(
    rank: AchievementRank.leyenda,
    nombre: 'Leyenda',
    accentColor: Color(0xFFF1C40F),
    progressColor: Color(0xFFF1C40F),
    glowColor: Color(0x30F1C40F),
    borderColor: instBlue,
    buttonColor: Color(0xFFF1C40F),
    buttonTextColor: instBlue,
    titleColor: Color(0xFFF1C40F),
    dividerColor: Color(0xFFE8EDF5),
    subtitleColor: Color(0xFF6B7A8F),
    confettiColors: [Color(0xFFF1C40F), white, Color(0xFFFFF9C4)],
    particleColors: [Color(0x80F1C40F), Color(0x50FFFFFF)],
  );
}
