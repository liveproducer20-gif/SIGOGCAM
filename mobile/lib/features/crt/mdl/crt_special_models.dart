enum TipoFormacion { entrante, saliente }

enum OpcionConductor { entradaPersonal, salidaPersonal, novedadesMovil }

extension TipoFormacionX on TipoFormacion {
  String get label => this == TipoFormacion.entrante
      ? 'Formación entrante'
      : 'Formación saliente';

  String get causa => this == TipoFormacion.entrante
      ? 'FORMACION ENTRANTE'
      : 'FORMACION SALIENTE';
}

extension OpcionConductorX on OpcionConductor {
  String get label => switch (this) {
    OpcionConductor.entradaPersonal => 'Entrada de personal',
    OpcionConductor.salidaPersonal => 'Salida de personal',
    OpcionConductor.novedadesMovil => 'Novedades del móvil',
  };

  String get code => switch (this) {
    OpcionConductor.entradaPersonal => 'ENTRADA_PERSONAL',
    OpcionConductor.salidaPersonal => 'SALIDA_PERSONAL',
    OpcionConductor.novedadesMovil => 'NOVEDADES_MOVIL',
  };
}

class FormacionData {
  final TipoFormacion tipo;
  final String distrito;
  final String circuito;
  final String direccion;
  final String horario;
  final DateTime fechaHora;
  final String novedades;
  final int radiooperadores;
  final int acmOperativos;
  final List<String> personalPolicial;
  final List<String> moviles;
  final List<String> reportantes;
  final String jefe;

  const FormacionData({
    required this.tipo,
    required this.distrito,
    required this.circuito,
    required this.direccion,
    required this.horario,
    required this.fechaHora,
    required this.novedades,
    required this.radiooperadores,
    required this.acmOperativos,
    required this.personalPolicial,
    required this.moviles,
    required this.reportantes,
    required this.jefe,
  });

  Map<String, dynamic> toJson() => {
    'tipo_formacion': tipo.causa,
    'distrito': distrito,
    'circuito': circuito,
    'direccion': direccion,
    'horario': horario,
    'fecha_hora': fechaHora.toIso8601String(),
    'novedades': novedades,
    'radiooperadores': radiooperadores,
    'acm_operativos': acmOperativos,
    'personal_policial': personalPolicial,
    'moviles': moviles,
    'reportantes': reportantes,
  };
}

class ConductorData {
  final int? conductorId;
  final String conductor;
  final String cedulaUltimos4;
  final OpcionConductor opcion;
  final String lugar;
  final int? movilId;
  final String disco;
  final DateTime fechaHora;
  final String combustible;
  final int kilometraje;
  final String servicio;
  final String horario;
  final int? encargadoId;
  final String encargado;
  final String observaciones;

  const ConductorData({
    this.conductorId,
    required this.conductor,
    required this.cedulaUltimos4,
    required this.opcion,
    required this.lugar,
    this.movilId,
    required this.disco,
    required this.fechaHora,
    required this.combustible,
    required this.kilometraje,
    required this.servicio,
    required this.horario,
    this.encargadoId,
    required this.encargado,
    required this.observaciones,
  });

  Map<String, dynamic> toJson() => {
    'conductor_id': conductorId,
    'conductor': conductor,
    'cedula_ultimos_4': cedulaUltimos4,
    'opcion': opcion.code,
    'lugar': lugar,
    'movil_id': movilId,
    'numero_disco': disco,
    'fecha_hora': fechaHora.toIso8601String(),
    'combustible': combustible,
    'kilometraje': kilometraje,
    'servicio': servicio,
    'horario': horario,
    'encargado_id': encargadoId,
    'encargado': encargado,
    'observaciones': observaciones,
  };
}

class OtrasCartillasData {
  final String distrito;
  final String circuito;
  final String direccion;
  final String horario;
  final DateTime fechaHora;
  final String causa;
  final String novedad;
  final List<String> reportantes;
  final String jefe;

  const OtrasCartillasData({
    required this.distrito,
    required this.circuito,
    required this.direccion,
    required this.horario,
    required this.fechaHora,
    required this.causa,
    required this.novedad,
    required this.reportantes,
    required this.jefe,
  });

  Map<String, dynamic> toJson() => {
    'distrito': distrito,
    'circuito': circuito,
    'direccion': direccion,
    'horario': horario,
    'fecha_hora': fechaHora.toIso8601String(),
    'causa': causa,
    'novedad': novedad,
    'reportantes': reportantes,
  };
}
