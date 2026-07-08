import 'crt_enums.dart';

class CrtFieldConfig {
  final String key;
  final String label;
  final bool required;
  final int minLines;

  const CrtFieldConfig({
    required this.key,
    required this.label,
    this.required = true,
    this.minLines = 1,
  });
}

class CrtModuleConfig {
  final TipoModuloCartilla modulo;
  final List<TipoCartilla> tipos;
  final List<CrtFieldConfig> fields;

  const CrtModuleConfig({
    required this.modulo,
    required this.tipos,
    required this.fields,
  });
}

class CrtEasStation {
  final String codigo;
  final String nombre;
  final String direccion;

  const CrtEasStation({
    required this.codigo,
    required this.nombre,
    required this.direccion,
  });
}

class CrtMovilDotacion {
  final String movil;
  final Map<RolMovil, String> integrantes;

  const CrtMovilDotacion({
    required this.movil,
    required this.integrantes,
  });
}

class CrtFormData {
  final TipoModuloCartilla modulo;
  final TipoCartilla tipo;
  final Jornada jornada;
  final String horario;
  final String fecha;
  final String hora;
  final CrtEasStation? eas;
  final String? movil;
  final RolMovil? rolMovil;
  final Map<RolMovil, String> dotacion;
  final Map<String, String> values;

  const CrtFormData({
    required this.modulo,
    required this.tipo,
    required this.jornada,
    required this.horario,
    required this.fecha,
    required this.hora,
    required this.values,
    this.eas,
    this.movil,
    this.rolMovil,
    this.dotacion = const {},
  });
}

class CrtDesalojoData {
  final String jp;
  final String auxiliar;
  final String movil;
  final String cp;
  final String? servidorPolicial;
  final String direccion;
  final bool agresivo;
  final bool necesitaColaboracion;

  const CrtDesalojoData({
    required this.jp,
    this.auxiliar = '',
    required this.movil,
    required this.cp,
    this.servidorPolicial,
    required this.direccion,
    required this.agresivo,
    required this.necesitaColaboracion,
  });
}
