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
  final List<String> permisos;

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
    this.permisos = const [],
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
      permisos: (json['permisos'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  AppUser copyWith({
    String? cedula,
    String? nombres,
    String? apellidos,
    String? correo,
    String? telefono,
    String? fechaNacimiento,
    String? fotoPerfilUrl,
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
      permisos: permisos,
    );
  }

  bool hasPermission(String codigo) => permisos.contains(codigo);
  bool hasAnyPermission(List<String> codigos) {
    return codigos.any(permisos.contains);
  }

  bool get esAdmin => rol == 'ADMINISTRADOR';
  bool get esOperaciones => rol == 'OPERACIONES';
  bool get esUsuario => rol == 'USUARIO';
  bool get puedeVerAdministracion => hasAnyPermission([
        'administracion.ver',
        'personal.ver',
        'catalogos.ver',
        'lugares_servicio.ver',
        'eas.ver',
        'moviles.ver',
      ]);
  bool get puedeGestionarEventos => hasAnyPermission([
        'eventos.crear',
        'eventos.editar',
        'eventos.eliminar',
      ]);
  bool get puedeGestionarAnuncios => hasAnyPermission([
        'eventos.publicar',
        'eventos.editar',
        'eventos.eliminar',
      ]);
  bool get soloEventosConvocados {
    return hasPermission('eventos.ver_convocado') &&
        !hasPermission('eventos.ver');
  }
}
