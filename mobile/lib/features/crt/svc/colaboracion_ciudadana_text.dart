class ColaboracionCiudadanaData {
  final String servicio;
  final String distrito;
  final String circuito;
  final DateTime fechaHora;
  final String direccion;
  final String jefe;
  final String reporta;
  final String nombreCiudadano;
  final String cedula;
  final String contacto;
  final String motivo;
  final String accion;
  final String resultado;
  final bool conNovedades;
  final String detalleNovedad;
  final String? moto;
  final String? can;
  final String? movil;
  final String? bicicleta;
  final String? videoperador;
  final List<String> movilesEnCirculacion;

  const ColaboracionCiudadanaData({
    required this.servicio,
    required this.distrito,
    required this.circuito,
    required this.fechaHora,
    required this.direccion,
    required this.jefe,
    required this.reporta,
    required this.nombreCiudadano,
    required this.cedula,
    required this.contacto,
    required this.motivo,
    required this.accion,
    required this.resultado,
    required this.conNovedades,
    this.detalleNovedad = '',
    this.moto,
    this.can,
    this.movil,
    this.bicicleta,
    this.videoperador,
    this.movilesEnCirculacion = const [],
  });
}

class ColaboracionCiudadanaText {
  ColaboracionCiudadanaText._();

  static const motivos = <String>[
    'Robo o hurto',
    'Persona extraviada',
    'Persona desorientada',
    'Localización de familiar',
    'Adulto mayor',
    'Persona con discapacidad',
    'Menor de edad',
    'Persona vulnerable',
    'Persona en situación de calle',
    'Pérdida de pertenencias',
    'Objeto extraviado',
    'Caída o accidente menor',
    'Primeros auxilios',
    'Problema de movilidad',
    'Contactar a familiares',
    'Asistencia a turista',
    'Situación de riesgo',
    'Acompañamiento preventivo',
    'Traslado a punto seguro',
    'Vehículo averiado',
    'Conflicto entre ciudadanos',
    'Crisis emocional',
    'Recuperación de documentos',
    'Solicitud de ayuda',
    'Otro motivo',
  ];

  static bool cedulaValida(String value) =>
      RegExp(r'^\d{10}$').hasMatch(value.trim());

  static bool telefonoValido(String value) =>
      RegExp(r'^0\d{9}$').hasMatch(value.trim());

  static String build(ColaboracionCiudadanaData data) {
    final servicio = _clean(data.servicio).toUpperCase();
    final distrito = _clean(data.distrito);
    final circuito = _clean(data.circuito);
    final direccion = _clean(data.direccion);
    final jefe = _clean(data.jefe);
    final reporta = _clean(data.reporta);
    final ciudadano = _clean(data.nombreCiudadano);
    final cedula = _clean(data.cedula);
    final contacto = _clean(data.contacto);
    final motivo = _lowerFirst(_withoutTerminalPunctuation(data.motivo));
    final accion = _withoutTerminalPunctuation(data.accion);
    final resultado = _withoutTerminalPunctuation(data.resultado);
    final novedad = _withoutTerminalPunctuation(data.detalleNovedad);
    final now = data.fechaHora;
    final hora = '${_two(now.hour)}:${_two(now.minute)}';
    final fecha = '${_two(now.day)}/${_two(now.month)}/${now.year}';

    final header = <String>[
      '*CUERPO DE AGENTES DE CONTROL MUNICIPAL*',
      '*REPORTE DE $servicio*',
      if (distrito.isNotEmpty) '*DISTRITO:* $distrito',
      if (circuito.isNotEmpty) '*CIRCUITO:* $circuito',
      '*HORA:* $hora',
      '*FECHA:* $fecha',
      if (direccion.isNotEmpty) '*DIRECCIÓN:* $direccion',
      '*CAUSA:* COLABORACIÓN CIUDADANA',
    ];

    final saludo = now.hour >= 6 && now.hour < 12
        ? 'Muy buenos días'
        : now.hour >= 12 && now.hour < 19
        ? 'Muy buenas tardes'
        : 'Muy buenas noches';
    final jefeTexto = jefe.isEmpty
        ? 'Jefe de Control Municipal'
        : jefe.toLowerCase().endsWith('jefe de control municipal')
        ? jefe
        : '$jefe Jefe de Control Municipal';

    final cuerpo = StringBuffer(
      'Muy respetuosamente me permito informar que se procedió a brindar '
      'colaboración ciudadana en el sector de $direccion, atendiendo el '
      'requerimiento realizado por el ciudadano/a $ciudadano, portador/a de '
      'la cédula de identidad $cedula y número de contacto $contacto, quien '
      'solicitó apoyo por motivo de $motivo. Durante el procedimiento, '
      'personal de Agentes de Control Municipal realizó $accion, permitiendo '
      '$resultado. La colaboración culminó ',
    );
    if (data.conNovedades) {
      cuerpo.write('con novedades, registrándose $novedad.');
    } else {
      cuerpo.write('sin novedades.');
    }

    final extrasAntesReporta = <String>[];
    if (data.movilesEnCirculacion.isNotEmpty) {
      final moviles = data.movilesEnCirculacion
          .map(_clean)
          .where((value) => value.isNotEmpty)
          .map(
            (value) => value.toLowerCase().startsWith('móvil ')
                ? value
                : 'Móvil $value',
          )
          .join(', ');
      if (moviles.isNotEmpty) {
        extrasAntesReporta.add('*MÓVILES EN CIRCULACIÓN:* $moviles');
      }
    }

    final extrasReporta = <String>[
      if (_has(data.moto)) '*MOTO:* ${_clean(data.moto!)}',
      if (_has(data.can)) '*CAN:* ${_clean(data.can!)}',
      if (_has(data.movil)) '*MÓVIL:* ${_clean(data.movil!)}',
      if (_has(data.bicicleta)) '*BICICLETA:* ${_clean(data.bicicleta!)}',
      if (_has(data.videoperador))
        '*VIDEOPERADOR:* ${_clean(data.videoperador!)}',
    ];

    return <String>[
      ...header,
      '',
      '$saludo, permiso Sr. $jefeTexto.',
      '',
      cuerpo.toString(),
      if (extrasAntesReporta.isNotEmpty) '',
      ...extrasAntesReporta,
      if (reporta.isNotEmpty) '',
      if (reporta.isNotEmpty) '*REPORTA:*',
      if (reporta.isNotEmpty) 'ACM. $reporta',
      if (reporta.isNotEmpty) ...extrasReporta,
      '',
      'Lealtad, Valor y Orden.',
      'Adjunto fotografía.',
    ].join('\n');
  }

  static String _clean(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _withoutTerminalPunctuation(String value) =>
      _clean(value).replaceFirst(RegExp(r'[\s.,;:]+$'), '');

  static String _lowerFirst(String value) => value.isEmpty
      ? value
      : '${value.substring(0, 1).toLowerCase()}${value.substring(1)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  static bool _has(String? value) => value != null && _clean(value).isNotEmpty;
}
