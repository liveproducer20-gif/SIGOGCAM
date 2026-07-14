enum PermissionScope { none, assigned, full }

class PermissionGrant {
  final String code;
  final String module;
  final String action;
  final String? label;

  const PermissionGrant({
    required this.code,
    required this.module,
    required this.action,
    this.label,
  });

  factory PermissionGrant.fromJson(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final code = map['codigo']?.toString() ?? map['code']?.toString() ?? '';
      final parts = code.split('.');
      return PermissionGrant(
        code: code,
        module: map['modulo']?.toString() ??
            map['module']?.toString() ??
            (parts.isEmpty ? '' : parts.first),
        action: map['accion']?.toString() ??
            map['action']?.toString() ??
            (parts.length > 1 ? parts.sublist(1).join('.') : ''),
        label: map['nombre']?.toString() ?? map['label']?.toString(),
      );
    }

    final code = value?.toString().trim() ?? '';
    final parts = code.split('.');
    return PermissionGrant(
      code: code,
      module: parts.isEmpty ? '' : parts.first,
      action: parts.length > 1 ? parts.sublist(1).join('.') : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'module': module,
        'action': action,
        if (label != null) 'label': label,
      };
}

class PermissionSet {
  final Map<String, PermissionGrant> _byCode;
  final Map<String, List<PermissionGrant>> _byModule;

  const PermissionSet._(this._byCode, this._byModule);
  const PermissionSet.empty()
      : _byCode = const {},
        _byModule = const {};

  factory PermissionSet.fromJson(Object? value) {
    final raw = value is List ? value : const [];
    final grants = raw
        .map(PermissionGrant.fromJson)
        .where((grant) => grant.code.isNotEmpty);
    final byCode = <String, PermissionGrant>{};
    final byModule = <String, List<PermissionGrant>>{};
    for (final grant in grants) {
      byCode[grant.code] = grant;
      byModule.putIfAbsent(grant.module, () => []).add(grant);
    }
    return PermissionSet._(byCode, byModule);
  }

  bool contains(String code) => _byCode.containsKey(code);
  bool containsAny(Iterable<String> codes) => codes.any(contains);
  bool containsAll(Iterable<String> codes) => codes.every(contains);
  List<PermissionGrant> forModule(String module) =>
      List.unmodifiable(_byModule[module] ?? const []);

  PermissionScope scopeFor(
    String module, {
    String fullAction = 'ver',
    String assignedAction = 'ver_asignado',
  }) {
    if (contains('$module.$fullAction')) return PermissionScope.full;
    if (contains('$module.$assignedAction')) return PermissionScope.assigned;
    return PermissionScope.none;
  }

  List<Map<String, dynamic>> toJson() =>
      _byCode.values.map((grant) => grant.toJson()).toList(growable: false);
}

class AppUser {
  final int id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correo;
  final String? telefono;
  final String? fechaNacimiento;
  final String? fechaIngreso;
  final String nombreCompleto;
  final String rol;
  final String? estadoPersonal;
  final String? fotoPerfilUrl;
  final PermissionSet permissions;

  const AppUser({
    required this.id,
    required this.cedula,
    this.nombres = '',
    this.apellidos = '',
    required this.correo,
    this.telefono,
    this.fechaNacimiento,
    this.fechaIngreso,
    required this.nombreCompleto,
    required this.rol,
    this.estadoPersonal,
    this.fotoPerfilUrl,
    this.permissions = const PermissionSet.empty(),
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final nombres = json['nombres']?.toString() ?? '';
    final apellidos = json['apellidos']?.toString() ?? '';
    final nombreCompleto = json['nombreCompleto']?.toString().trim();
    return AppUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      cedula: json['cedula']?.toString() ?? '',
      nombres: nombres,
      apellidos: apellidos,
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      fechaNacimiento: json['fechaNacimiento']?.toString(),
      fechaIngreso: json['fechaIngreso']?.toString(),
      nombreCompleto: nombreCompleto?.isNotEmpty == true
          ? nombreCompleto!
          : '$nombres $apellidos'.trim(),
      rol: json['rol']?.toString().toUpperCase() ?? 'USUARIO',
      estadoPersonal: json['estadoPersonal']?.toString(),
      fotoPerfilUrl: json['fotoPerfilUrl']?.toString(),
      permissions: PermissionSet.fromJson(
        json['permissions'] ?? json['permisos'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
        'telefono': telefono,
        'fechaNacimiento': fechaNacimiento,
        'fechaIngreso': fechaIngreso,
        'nombreCompleto': nombreCompleto,
        'rol': rol,
        'estadoPersonal': estadoPersonal,
        'fotoPerfilUrl': fotoPerfilUrl,
        'permissions': permissions.toJson(),
      };

  AppUser copyWith({
    String? cedula,
    String? nombres,
    String? apellidos,
    String? correo,
    String? telefono,
    String? fechaNacimiento,
    String? fotoPerfilUrl,
    PermissionSet? permissions,
  }) {
    final nextNombres = nombres ?? this.nombres;
    final nextApellidos = apellidos ?? this.apellidos;
    return AppUser(
      id: id,
      cedula: cedula ?? this.cedula,
      nombres: nextNombres,
      apellidos: nextApellidos,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fechaIngreso: fechaIngreso,
      nombreCompleto: '$nextNombres $nextApellidos'.trim().isEmpty
          ? nombreCompleto
          : '$nextNombres $nextApellidos'.trim(),
      rol: rol,
      estadoPersonal: estadoPersonal,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      permissions: permissions ?? this.permissions,
    );
  }

  bool hasPermission(String code) => permissions.contains(code);
  bool hasAnyPermission(Iterable<String> codes) =>
      permissions.containsAny(codes);

  bool get esAdmin => rol == 'ADMINISTRADOR';
  bool get esOperaciones => rol == 'OPERACIONES';
  bool get esUsuario => rol == 'USUARIO';
  bool get puedeVerAdministracion => hasPermission('administracion.ver');
  bool get puedeGestionarEventos => hasAnyPermission(const [
        'eventos.crear',
        'eventos.editar',
        'eventos.eliminar',
      ]);
  bool get puedeGestionarAnuncios => hasAnyPermission(const [
        'anuncios.crear',
        'anuncios.editar',
        'anuncios.eliminar',
        'eventos.publicar',
      ]);
  PermissionScope get eventAccess => permissions.scopeFor(
        'eventos',
        assignedAction: 'ver_convocado',
      );
  bool get soloEventosConvocados => eventAccess == PermissionScope.assigned;
}
