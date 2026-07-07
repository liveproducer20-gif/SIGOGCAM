class EvtTipoMdl {
  final int id;
  final String codigo;
  final String nombre;

  const EvtTipoMdl({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  factory EvtTipoMdl.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo']?.toString() ?? '';

    return EvtTipoMdl(
      id: json['id'] as int,
      codigo: codigo,
      nombre: _nombrePorCodigo(codigo, json['nombre']?.toString() ?? ''),
    );
  }

  static String _nombrePorCodigo(String codigo, String fallback) {
    switch (codigo.toUpperCase()) {
      case 'CAPACITACION':
        return 'Capacitación';
      case 'REUNION':
        return 'Reunión';
      case 'OPERATIVO':
        return 'Operativo';
      case 'COMISION':
        return 'Comisión';
      case 'CURSO':
        return 'Curso';
      case 'OTRO':
        return 'Otro';
      default:
        return fallback;
    }
  }
}
