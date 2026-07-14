class ModuloModel {
  final int id;
  final String nombre;
  final String codigo;
  final String? icono;
  final String? ruta;
  final int? moduloPadreId;
  final int orden;
  final bool activo;

  ModuloModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.icono,
    this.ruta,
    this.moduloPadreId,
    this.orden = 0,
    this.activo = true,
  });

  factory ModuloModel.fromJson(Map<String, dynamic> json) => ModuloModel(
    id: _asInt(json['id']),
    nombre: json['nombre'] ?? '',
    codigo: json['codigo'] ?? '',
    icono: json['icono'],
    ruta: json['ruta'],
    moduloPadreId: json['modulo_padre_id'] != null
        ? (json['modulo_padre_id'] is int
            ? json['modulo_padre_id']
            : int.tryParse(json['modulo_padre_id'].toString()))
        : null,
    orden: _asInt(json['orden']),
    activo: _asBool(json['activo'], fallback: true),
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'codigo': codigo,
    'icono': icono,
    'ruta': ruta,
    'modulo_padre_id': moduloPadreId,
    'orden': orden,
    'activo': activo,
  };
}

class MenuItemModel {
  final int moduloId;
  final String nombre;
  final String codigo;
  final String? icono;
  final String? ruta;
  final int? moduloPadreId;
  final int nivel;
  final int orden;
  final bool visible;
  final String? etiquetaPersonalizada;
  final List<MenuItemModel> hijos;

  MenuItemModel({
    required this.moduloId,
    required this.nombre,
    required this.codigo,
    this.icono,
    this.ruta,
    this.moduloPadreId,
    this.nivel = 0,
    this.orden = 0,
    this.visible = true,
    this.etiquetaPersonalizada,
    this.hijos = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
    moduloId: _asInt(json['id']),
    nombre: json['nombre'] ?? '',
    codigo: json['codigo'] ?? '',
    icono: json['icono'],
    ruta: json['ruta'],
    moduloPadreId: json['modulo_padre_id'],
    nivel: _asInt(json['nivel']),
    orden: _asInt(json['orden']),
    visible: _asBool(json['visible'], fallback: true),
    etiquetaPersonalizada: json['etiqueta_personalizada'],
    hijos: (json['hijos'] as List<dynamic>?)
            ?.map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class RolMenuConfigModel {
  final int id;
  final int rolId;
  final int moduloId;
  final int nivel;
  final int orden;
  final int visible;
  final String? etiquetaPersonalizada;
  final String? moduloNombre;
  final String? moduloCodigo;
  final String? icono;
  final String? ruta;

  RolMenuConfigModel({
    required this.id,
    required this.rolId,
    required this.moduloId,
    this.nivel = 0,
    this.orden = 0,
    this.visible = 1,
    this.etiquetaPersonalizada,
    this.moduloNombre,
    this.moduloCodigo,
    this.icono,
    this.ruta,
  });

  factory RolMenuConfigModel.fromJson(Map<String, dynamic> json) =>
      RolMenuConfigModel(
        id: _asInt(json['id']),
        rolId: _asInt(json['rol_id']),
        moduloId: _asInt(json['modulo_id']),
        nivel: _asInt(json['nivel']),
        orden: _asInt(json['orden']),
        visible: _asBool(json['visible'], fallback: true) ? 1 : 0,
        etiquetaPersonalizada: json['etiqueta_personalizada'],
        moduloNombre: json['modulo_nombre'],
        moduloCodigo: json['modulo_codigo'],
        icono: json['icono'],
        ruta: json['ruta'],
      );
}

class ScopeModel {
  final int id;
  final int rolId;
  final String modulo;
  final String alcance;
  final String entidad;
  final Map<String, dynamic>? condicionAdicional;

  ScopeModel({
    required this.id,
    required this.rolId,
    required this.modulo,
    required this.alcance,
    required this.entidad,
    this.condicionAdicional,
  });

  factory ScopeModel.fromJson(Map<String, dynamic> json) => ScopeModel(
    id: _asInt(json['id']),
    rolId: _asInt(json['rol_id']),
    modulo: json['modulo'] ?? '',
    alcance: json['alcance'] ?? 'todos',
    entidad: json['entidad'] ?? '',
    condicionAdicional: json['condicion_adicional'] is Map
        ? Map<String, dynamic>.from(json['condicion_adicional'])
        : null,
  );
}

class CampoPermisoModel {
  final int id;
  final int rolId;
  final int campoId;
  final bool puedeVer;
  final bool puedeEditar;
  final bool requerido;
  final String? campoNombre;
  final String? campoCodigo;
  final String? tipoDato;
  final String? entidad;
  final String? seccion;

  CampoPermisoModel({
    required this.id,
    required this.rolId,
    required this.campoId,
    this.puedeVer = true,
    this.puedeEditar = false,
    this.requerido = false,
    this.campoNombre,
    this.campoCodigo,
    this.tipoDato,
    this.entidad,
    this.seccion,
  });

  factory CampoPermisoModel.fromJson(Map<String, dynamic> json) =>
      CampoPermisoModel(
        id: _asInt(json['id']),
        rolId: _asInt(json['rol_id']),
        campoId: _asInt(json['campo_id']),
        puedeVer: _asBool(json['puede_ver']),
        puedeEditar: _asBool(json['puede_editar']),
        requerido: _asBool(json['requerido']),
        campoNombre: json['campo_nombre'],
        campoCodigo: json['campo_codigo'],
        tipoDato: json['tipo_dato'],
        entidad: json['entidad'],
        seccion: json['seccion'],
      );
}

class VersionModel {
  final int id;
  final int rolId;
  final int version;
  final String datosJson;
  final String? descripcion;
  final int? creadoPor;
  final DateTime? creadoEn;

  VersionModel({
    required this.id,
    required this.rolId,
    required this.version,
    required this.datosJson,
    this.descripcion,
    this.creadoPor,
    this.creadoEn,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) => VersionModel(
    id: _asInt(json['id']),
    rolId: _asInt(json['rol_id']),
    version: _asInt(json['version']),
    datosJson: json['datos_json'] ?? '{}',
    descripcion: json['descripcion'],
    creadoPor: json['creado_por'] != null
        ? int.tryParse(json['creado_por'].toString())
        : null,
    creadoEn: json['creado_en'] != null
        ? DateTime.tryParse(json['creado_en'].toString())
        : null,
  );
}

class AuditoriaModel {
  final int id;
  final int? rolId;
  final String modulo;
  final String accion;
  final String? detalle;
  final int? usuarioId;
  final Map<String, dynamic>? datosAntiguos;
  final Map<String, dynamic>? datosNuevos;
  final DateTime? creadoEn;

  AuditoriaModel({
    required this.id,
    this.rolId,
    required this.modulo,
    required this.accion,
    this.detalle,
    this.usuarioId,
    this.datosAntiguos,
    this.datosNuevos,
    this.creadoEn,
  });

  factory AuditoriaModel.fromJson(Map<String, dynamic> json) => AuditoriaModel(
    id: _asInt(json['id']),
    rolId: json['rol_id'] != null
        ? int.tryParse(json['rol_id'].toString())
        : null,
    modulo: json['modulo'] ?? '',
    accion: json['accion'] ?? '',
    detalle: json['detalle'],
    usuarioId: json['usuario_id'] != null
        ? int.tryParse(json['usuario_id'].toString())
        : null,
    datosAntiguos: json['datos_antiguos'] is Map
        ? Map<String, dynamic>.from(json['datos_antiguos'])
        : null,
    datosNuevos: json['datos_nuevos'] is Map
        ? Map<String, dynamic>.from(json['datos_nuevos'])
        : null,
    creadoEn: json['creado_en'] != null
        ? DateTime.tryParse(json['creado_en'].toString())
        : null,
  );
}

class RolModel {
  final int id;
  final String nombre;
  final String codigo;
  final bool activo;

  RolModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.activo = true,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) => RolModel(
    id: _asInt(json['id']),
    nombre: json['nombre'] ?? '',
    codigo: json['codigo'] ?? '',
    activo: _asBool(json['activo'], fallback: true),
  );
}

class EstructuraData {
  final List<ModuloModel> modulos;
  final List<RolModel> roles;

  EstructuraData({required this.modulos, required this.roles});

  factory EstructuraData.fromJson(Map<String, dynamic> json) => EstructuraData(
    modulos: (json['modulos'] as List<dynamic>?)
            ?.map((e) => ModuloModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    roles: (json['roles'] as List<dynamic>?)
            ?.map((e) => RolModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (const {'1', 'true', 'si', 'sí'}.contains(text)) return true;
  if (const {'0', 'false', 'no'}.contains(text)) return false;
  return fallback;
}
