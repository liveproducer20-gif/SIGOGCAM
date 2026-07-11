import 'badge_catalog.dart';
import 'ins_achievement_theme.dart';

class InsMdl {
  final int id;
  final String codigo;
  final String titulo;
  final String descripcion;
  final int metaCartillas;
  final String categoria;
  final String icono;
  final bool desbloqueada;
  final int? totalAlDesbloquear;
  final String? fechaDesbloqueo;

  const InsMdl({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.metaCartillas,
    required this.categoria,
    required this.icono,
    this.desbloqueada = false,
    this.totalAlDesbloquear,
    this.fechaDesbloqueo,
  });

  factory InsMdl.fromJson(Map<String, dynamic> json) {
    return InsMdl(
      id: _toInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      metaCartillas: _toInt(json['meta_cartillas']),
      categoria: json['categoria']?.toString() ?? 'cartillas',
      icono: json['icono']?.toString() ?? '',
      desbloqueada: json['fecha_desbloqueo'] != null ||
          json['total_cartillas_al_desbloquear'] != null,
      totalAlDesbloquear: json['total_cartillas_al_desbloquear'] == null
          ? null
          : _toInt(json['total_cartillas_al_desbloquear']),
      fechaDesbloqueo: json['fecha_desbloqueo']?.toString(),
    );
  }

  InsMdl copyWith({
    bool? desbloqueada,
    int? totalAlDesbloquear,
    String? fechaDesbloqueo,
  }) {
    return InsMdl(
      id: id,
      codigo: codigo,
      titulo: titulo,
      descripcion: descripcion,
      metaCartillas: metaCartillas,
      categoria: categoria,
      icono: icono,
      desbloqueada: desbloqueada ?? this.desbloqueada,
      totalAlDesbloquear: totalAlDesbloquear ?? this.totalAlDesbloquear,
      fechaDesbloqueo: fechaDesbloqueo ?? this.fechaDesbloqueo,
    );
  }
}

class InsProgresoMdl {
  final int totalCartillasGeneradas;
  final String? ultimaInsignia;
  final String? proximaInsignia;
  final int? metaProxima;
  final int cartillasFaltantes;
  final int porcentajeProgreso;

  const InsProgresoMdl({
    required this.totalCartillasGeneradas,
    this.ultimaInsignia,
    this.proximaInsignia,
    this.metaProxima,
    required this.cartillasFaltantes,
    required this.porcentajeProgreso,
  });

  factory InsProgresoMdl.fromJson(Map<String, dynamic> json) {
    return InsProgresoMdl(
      totalCartillasGeneradas: _toInt(json['total_cartillas_generadas']),
      ultimaInsignia: json['ultima_insignia']?.toString(),
      proximaInsignia: json['proxima_insignia']?.toString(),
      metaProxima: json['meta_proxima'] == null ? null : _toInt(json['meta_proxima']),
      cartillasFaltantes: _toInt(json['cartillas_faltantes']),
      porcentajeProgreso: _toInt(json['porcentaje_progreso']),
    );
  }
}

class CartillaRegistroMdl {
  final int cartillaId;
  final int totalCartillasGeneradas;
  final InsigniaDesbloqueadaMdl? insigniaDesbloqueada;

  const CartillaRegistroMdl({
    required this.cartillaId,
    required this.totalCartillasGeneradas,
    this.insigniaDesbloqueada,
  });

  factory CartillaRegistroMdl.fromJson(Map<String, dynamic> json) {
    final insignia = json['insignia_desbloqueada'];
    return CartillaRegistroMdl(
      cartillaId: _toInt(json['cartillaId']),
      totalCartillasGeneradas: _toInt(json['total_cartillas_generadas']),
      insigniaDesbloqueada: insignia is Map
          ? InsigniaDesbloqueadaMdl.fromJson(
              Map<String, dynamic>.from(insignia),
            )
          : null,
    );
  }
}

class InsigniaDesbloqueadaMdl {
  final String titulo;
  final String mensaje;
  final String icono;

  const InsigniaDesbloqueadaMdl({
    required this.titulo,
    required this.mensaje,
    required this.icono,
  });

  factory InsigniaDesbloqueadaMdl.fromJson(Map<String, dynamic> json) {
    return InsigniaDesbloqueadaMdl(
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      icono: json['icono']?.toString() ?? '',
    );
  }
}

int _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

extension InsMdlExt on InsMdl {
  BadgeEntry? get catalogEntry => BadgeCatalog.byMeta(metaCartillas);
  int get nivel => catalogEntry?.nivel ?? 1;
  LevelTheme get levelTheme => LevelTheme.forNivel(nivel);
  String get nivelName => levelTheme.name;
}
