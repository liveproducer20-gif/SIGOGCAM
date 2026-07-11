class BadgeEntry {
  final int id;
  final String name;
  final String description;
  final int metaCartillas;
  final String assetPath;
  final int nivel;
  final int orden;

  const BadgeEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.metaCartillas,
    required this.assetPath,
    required this.nivel,
    required this.orden,
  });
}

class BadgeCatalog {
  BadgeCatalog._();

  static const List<BadgeEntry> all = [
    // ── NIVEL 1 — AMATEUR ───────────────────
    _b1, _b2, _b3, _b4, _b5,
    // ── NIVEL 2 — OPERATIVO ─────────────────
    _b6, _b7, _b8, _b9, _b10,
    // ── NIVEL 3 — PROFESIONAL ───────────────
    _b11, _b12, _b13, _b14, _b15,
    // ── NIVEL 4 — AVANZADO ──────────────────
    _b16, _b17, _b18, _b19, _b20,
    // ── NIVEL 5 — EXPERTO ───────────────────
    _b21, _b22, _b23, _b24, _b25,
    // ── NIVEL 6 — ÉLITE ─────────────────────
    _b26, _b27, _b28, _b29, _b30,
    // ── NIVEL 7 — LEYENDA ───────────────────
    _b31, _b32, _b33, _b34, _b35,
    // ── NIVEL 8 — SUPREMO ───────────────────
    _b36, _b37, _b38, _b39, _b40,
    // ── NIVEL 9 — MÍTICO ────────────────────
    _b41, _b42, _b43, _b44,
    // ── NIVEL 10 — MÁXIMO ───────────────────
    _b45, _b46, _b47, _b48,
  ];

  static BadgeEntry? byMeta(int metaCartillas) {
    for (final b in all) {
      if (b.metaCartillas == metaCartillas) return b;
    }
    return null;
  }

  static BadgeEntry? byId(int id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  static List<BadgeEntry> forNivel(int nivel) {
    return all.where((b) => b.nivel == nivel).toList();
  }

  static BadgeEntry? previous(BadgeEntry current) {
    final idx = all.indexOf(current);
    if (idx <= 0) return null;
    return all[idx - 1];
  }

  static BadgeEntry? next(BadgeEntry current) {
    final idx = all.indexOf(current);
    if (idx < 0 || idx >= all.length - 1) return null;
    return all[idx + 1];
  }

  static BadgeEntry? lastUnlocked(List<int> unlockedMetas) {
    if (unlockedMetas.isEmpty) return null;
    final sorted = List.of(unlockedMetas)..sort();
    return byMeta(sorted.last);
  }

  static BadgeEntry? nextTarget(List<int> unlockedMetas) {
    if (unlockedMetas.isEmpty) return all.first;
    final last = lastUnlocked(unlockedMetas);
    if (last == null) return all.first;
    return next(last);
  }

  /// Interval progress: (userTotal - lastMeta) / (nextMeta - lastMeta)
  static double intervalProgress(int userTotal, List<int> unlockedMetas) {
    final last = lastUnlocked(unlockedMetas);
    final nextB = nextTarget(unlockedMetas);
    if (nextB == null) return 1.0;
    final lastMeta = last?.metaCartillas ?? 0;
    final nextMeta = nextB.metaCartillas;
    if (nextMeta <= lastMeta) return 1.0;
    return ((userTotal - lastMeta) / (nextMeta - lastMeta)).clamp(0.0, 1.0);
  }

  // ── NIVEL 1 ──────────────────────────────────────
  static const _b1 = BadgeEntry(
    id: 1, name: 'Agente Amateur',
    description: 'Primeros pasos en el registro de novedades.',
    metaCartillas: 5, assetPath: 'assets/badges/badge_01.svg',
    nivel: 1, orden: 1,
  );
  static const _b2 = BadgeEntry(
    id: 2, name: 'Redactor Novato',
    description: 'Tus primeras cartillas muestran tu potencial.',
    metaCartillas: 10, assetPath: 'assets/badges/badge_02.svg',
    nivel: 1, orden: 2,
  );
  static const _b3 = BadgeEntry(
    id: 3, name: 'Cronista Operativo',
    description: 'La constancia comienza a dar frutos.',
    metaCartillas: 20, assetPath: 'assets/badges/badge_03.svg',
    nivel: 1, orden: 3,
  );
  static const _b4 = BadgeEntry(
    id: 4, name: 'Reportero Activo',
    description: 'Ya eres parte del engranaje informativo.',
    metaCartillas: 30, assetPath: 'assets/badges/badge_04.svg',
    nivel: 1, orden: 4,
  );
  static const _b5 = BadgeEntry(
    id: 5, name: 'Agente Comprometido',
    description: 'Tu compromiso con la información es notable.',
    metaCartillas: 45, assetPath: 'assets/badges/badge_05.svg',
    nivel: 1, orden: 5,
  );

  // ── NIVEL 2 ──────────────────────────────────────
  static const _b6 = BadgeEntry(
    id: 6, name: 'Operador Estratégico',
    description: 'Operas con estrategia y precisión.',
    metaCartillas: 60, assetPath: 'assets/badges/badge_06.svg',
    nivel: 2, orden: 1,
  );
  static const _b7 = BadgeEntry(
    id: 7, name: 'Coordinador de Cartillas',
    description: 'Coordinación y orden en cada reporte.',
    metaCartillas: 80, assetPath: 'assets/badges/badge_07.svg',
    nivel: 2, orden: 2,
  );
  static const _b8 = BadgeEntry(
    id: 8, name: 'Supervisor de Incidencias',
    description: 'Nadie supervisa como tú las novedades.',
    metaCartillas: 100, assetPath: 'assets/badges/badge_08.svg',
    nivel: 2, orden: 3,
  );
  static const _b9 = BadgeEntry(
    id: 9, name: 'Agente Destacado',
    description: 'Te destacas entre los agentes operativos.',
    metaCartillas: 125, assetPath: 'assets/badges/badge_09.svg',
    nivel: 2, orden: 4,
  );
  static const _b10 = BadgeEntry(
    id: 10, name: 'Especialista Operativo',
    description: 'Eres un especialista en operaciones.',
    metaCartillas: 150, assetPath: 'assets/badges/badge_10.svg',
    nivel: 2, orden: 5,
  );

  // ── NIVEL 3 ──────────────────────────────────────
  static const _b11 = BadgeEntry(
    id: 11, name: 'Experto en Reportes',
    description: 'La calidad de tus reportes es profesional.',
    metaCartillas: 180, assetPath: 'assets/badges/badge_11.svg',
    nivel: 3, orden: 1,
  );
  static const _b12 = BadgeEntry(
    id: 12, name: 'Centinela Institucional',
    description: 'Vigilante institucional de cada suceso.',
    metaCartillas: 215, assetPath: 'assets/badges/badge_12.svg',
    nivel: 3, orden: 2,
  );
  static const _b13 = BadgeEntry(
    id: 13, name: 'Maestro de Cartillas',
    description: 'Dominas el arte de las cartillas.',
    metaCartillas: 255, assetPath: 'assets/badges/badge_13.svg',
    nivel: 3, orden: 3,
  );
  static const _b14 = BadgeEntry(
    id: 14, name: 'Leyenda Operativa',
    description: 'Tu nombre empieza a sonar en operaciones.',
    metaCartillas: 300, assetPath: 'assets/badges/badge_14.svg',
    nivel: 3, orden: 4,
  );
  static const _b15 = BadgeEntry(
    id: 15, name: 'Super Agente',
    description: 'Superas los límites del agente promedio.',
    metaCartillas: 350, assetPath: 'assets/badges/badge_15.svg',
    nivel: 3, orden: 5,
  );

  // ── NIVEL 4 ──────────────────────────────────────
  static const _b16 = BadgeEntry(
    id: 16, name: 'El Mejor de los Papamike',
    description: 'El mejor entre los mejores operadores.',
    metaCartillas: 405, assetPath: 'assets/badges/badge_16.svg',
    nivel: 4, orden: 1,
  );
  static const _b17 = BadgeEntry(
    id: 17, name: 'El Loco de las Cartillas',
    description: 'Tu obsesión por los reportes es legendaria.',
    metaCartillas: 465, assetPath: 'assets/badges/badge_17.svg',
    nivel: 4, orden: 2,
  );
  static const _b18 = BadgeEntry(
    id: 18, name: 'Tiburón de los Reportes',
    description: 'Depredador incansable de las novedades.',
    metaCartillas: 530, assetPath: 'assets/badges/badge_18.svg',
    nivel: 4, orden: 3,
  );
  static const _b19 = BadgeEntry(
    id: 19, name: 'Sniper de Novedades',
    description: 'Precisión quirúrgica en cada reporte.',
    metaCartillas: 600, assetPath: 'assets/badges/badge_19.svg',
    nivel: 4, orden: 4,
  );
  static const _b20 = BadgeEntry(
    id: 20, name: 'Tirador de Incidencias',
    description: 'Ninguna incidencia escapa a tu puntería.',
    metaCartillas: 675, assetPath: 'assets/badges/badge_20.svg',
    nivel: 4, orden: 5,
  );

  // ── NIVEL 5 ──────────────────────────────────────
  static const _b21 = BadgeEntry(
    id: 21, name: 'Perito de Cartillas',
    description: 'Eres un perito en la redacción de cartillas.',
    metaCartillas: 755, assetPath: 'assets/badges/badge_21.svg',
    nivel: 5, orden: 1,
  );
  static const _b22 = BadgeEntry(
    id: 22, name: 'Jefe de Patrulla',
    description: 'Lideras con ejemplo y determinación.',
    metaCartillas: 840, assetPath: 'assets/badges/badge_22.svg',
    nivel: 5, orden: 2,
  );
  static const _b23 = BadgeEntry(
    id: 23, name: 'Lluvia de Novedades',
    description: 'Incesante torrente de información.',
    metaCartillas: 930, assetPath: 'assets/badges/badge_23.svg',
    nivel: 5, orden: 3,
  );
  static const _b24 = BadgeEntry(
    id: 24, name: 'Cartillas por Doquier',
    description: 'Tus cartillas están en todos lados.',
    metaCartillas: 1025, assetPath: 'assets/badges/badge_24.svg',
    nivel: 5, orden: 4,
  );
  static const _b25 = BadgeEntry(
    id: 25, name: 'Superhéroe Operativo',
    description: 'Heroico desempeño en el campo operativo.',
    metaCartillas: 1125, assetPath: 'assets/badges/badge_25.svg',
    nivel: 5, orden: 5,
  );

  // ── NIVEL 6 ──────────────────────────────────────
  static const _b26 = BadgeEntry(
    id: 26, name: 'Merodeador de Incidencias',
    description: 'Sigiloso y efectivo ante cada incidencia.',
    metaCartillas: 1230, assetPath: 'assets/badges/badge_26.svg',
    nivel: 6, orden: 1,
  );
  static const _b27 = BadgeEntry(
    id: 27, name: 'Jefe de Asuntos Operativos',
    description: 'Autoridad máxima en asuntos operativos.',
    metaCartillas: 1340, assetPath: 'assets/badges/badge_27.svg',
    nivel: 6, orden: 2,
  );
  static const _b28 = BadgeEntry(
    id: 28, name: 'Comisionado de Élite',
    description: 'La élite de los comisionados operativos.',
    metaCartillas: 1455, assetPath: 'assets/badges/badge_28.svg',
    nivel: 6, orden: 3,
  );
  static const _b29 = BadgeEntry(
    id: 29, name: 'Guardián Supremo',
    description: 'Guardián incansable del orden institucional.',
    metaCartillas: 1575, assetPath: 'assets/badges/badge_29.svg',
    nivel: 6, orden: 4,
  );
  static const _b30 = BadgeEntry(
    id: 30, name: 'Maestro Consumado',
    description: 'Maestro consumado del arte operativo.',
    metaCartillas: 1700, assetPath: 'assets/badges/badge_30.svg',
    nivel: 6, orden: 5,
  );

  // ── NIVEL 7 ──────────────────────────────────────
  static const _b31 = BadgeEntry(
    id: 31, name: 'Leyenda Viviente',
    description: 'Ya eres una leyenda entre tus compañeros.',
    metaCartillas: 1830, assetPath: 'assets/badges/badge_31.svg',
    nivel: 7, orden: 1,
  );
  static const _b32 = BadgeEntry(
    id: 32, name: 'Emblema de Honor',
    description: 'Emblema viviente del honor institucional.',
    metaCartillas: 1965, assetPath: 'assets/badges/badge_32.svg',
    nivel: 7, orden: 2,
  );
  static const _b33 = BadgeEntry(
    id: 33, name: 'Custodio del Sistema',
    description: 'Custodias el sistema con dedicación absoluta.',
    metaCartillas: 2105, assetPath: 'assets/badges/badge_33.svg',
    nivel: 7, orden: 3,
  );
  static const _b34 = BadgeEntry(
    id: 34, name: 'Pináculo del Mérito',
    description: 'Has alcanzado la cima del mérito operativo.',
    metaCartillas: 2250, assetPath: 'assets/badges/badge_34.svg',
    nivel: 7, orden: 4,
  );
  static const _b35 = BadgeEntry(
    id: 35, name: 'Arquitecto Operativo',
    description: 'Arquitecto de la eficiencia operativa.',
    metaCartillas: 2400, assetPath: 'assets/badges/badge_35.svg',
    nivel: 7, orden: 5,
  );

  // ── NIVEL 8 ──────────────────────────────────────
  static const _b36 = BadgeEntry(
    id: 36, name: 'Director de Operaciones',
    description: 'Diriges las operaciones con maestría.',
    metaCartillas: 2555, assetPath: 'assets/badges/badge_36.svg',
    nivel: 8, orden: 1,
  );
  static const _b37 = BadgeEntry(
    id: 37, name: 'Estratega Maestro',
    description: 'Maestro en la estrategia operativa.',
    metaCartillas: 2715, assetPath: 'assets/badges/badge_37.svg',
    nivel: 8, orden: 2,
  );
  static const _b38 = BadgeEntry(
    id: 38, name: 'Vigía Supremo',
    description: 'Vigilante supremo de cada novedad.',
    metaCartillas: 2880, assetPath: 'assets/badges/badge_38.svg',
    nivel: 8, orden: 3,
  );
  static const _b39 = BadgeEntry(
    id: 39, name: 'Comandante Institucional',
    description: 'Comandante indiscutible de la institución.',
    metaCartillas: 3050, assetPath: 'assets/badges/badge_39.svg',
    nivel: 8, orden: 4,
  );
  static const _b40 = BadgeEntry(
    id: 40, name: 'Titán de las Cartillas',
    description: 'Titán incomparable en la generación de cartillas.',
    metaCartillas: 3225, assetPath: 'assets/badges/badge_40.svg',
    nivel: 8, orden: 5,
  );

  // ── NIVEL 9 ──────────────────────────────────────
  static const _b41 = BadgeEntry(
    id: 41, name: 'Gran Centinela',
    description: 'Centinela mayor de la institución.',
    metaCartillas: 3405, assetPath: 'assets/badges/badge_41.svg',
    nivel: 9, orden: 1,
  );
  static const _b42 = BadgeEntry(
    id: 42, name: 'Guardián de Hierro',
    description: 'Voluntad inquebrantable de hierro.',
    metaCartillas: 3590, assetPath: 'assets/badges/badge_42.svg',
    nivel: 9, orden: 2,
  );
  static const _b43 = BadgeEntry(
    id: 43, name: 'Soberano de Incidencias',
    description: 'Soberano absoluto de las incidencias.',
    metaCartillas: 3780, assetPath: 'assets/badges/badge_43.svg',
    nivel: 9, orden: 3,
  );
  static const _b44 = BadgeEntry(
    id: 44, name: 'Maestro de Estrategias',
    description: 'Maestro en el arte de la estrategia.',
    metaCartillas: 3975, assetPath: 'assets/badges/badge_44.svg',
    nivel: 9, orden: 4,
  );

  // ── NIVEL 10 ─────────────────────────────────────
  static const _b45 = BadgeEntry(
    id: 45, name: 'Gran Comisionado',
    description: 'El más alto comisionado del sistema.',
    metaCartillas: 4175, assetPath: 'assets/badges/badge_45.svg',
    nivel: 10, orden: 1,
  );
  static const _b46 = BadgeEntry(
    id: 46, name: 'Mariscal Operativo',
    description: 'Mariscal de las operaciones institucionales.',
    metaCartillas: 4380, assetPath: 'assets/badges/badge_46.svg',
    nivel: 10, orden: 2,
  );
  static const _b47 = BadgeEntry(
    id: 47, name: 'Leyenda Inmortal',
    description: 'Inmortalizado en la historia institucional.',
    metaCartillas: 4590, assetPath: 'assets/badges/badge_47.svg',
    nivel: 10, orden: 3,
  );
  static const _b48 = BadgeEntry(
    id: 48, name: 'Emblema Supremo',
    description: 'El emblema más supremo jamás alcanzado.',
    metaCartillas: 4805, assetPath: 'assets/badges/badge_48.svg',
    nivel: 10, orden: 4,
  );
}
