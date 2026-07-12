import 'package:flutter/material.dart';

class AdmTokens {
  AdmTokens._();

  // Colores institucionales
  static const Color primary = Color(0xFF163E7A);
  static const Color secondary = Color(0xFF2563A9);
  static const Color primarySoft = Color(0xFFEDF4FF);
  static const Color action = Color(0xFFF6C343);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFEF4444);
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);

  // Grises
  static const Color grey50 = Color(0xFFF8F9FA);
  static const Color grey100 = Color(0xFFF0F1F3);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFC8CDD6);
  static const Color grey400 = Color(0xFF9EA6B4);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF4A5160);
  static const Color grey700 = Color(0xFF343A45);
  static const Color grey800 = Color(0xFF212529);
  static const Color grey900 = Color(0xFF1E293B);

  // Espaciado
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Radios
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  // Sombras suaves
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Text styles
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: grey900,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: grey900,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: grey500,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: grey700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: grey500,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: grey600,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: grey900,
    letterSpacing: -0.5,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: grey500,
  );
}
