import 'crt_text_generator.dart';

class OtrasCartillasData {
  final String servicio;
  final String distrito;
  final String circuito;
  final DateTime fechaHora;
  final String direccion;
  final String causa;
  final String novedades;
  final String? moto;
  final String? can;
  final String? movil;
  final String? bicicleta;
  final String? videoperador;
  final List<String> movilesEnCirculacion;
  final String reporta;

  const OtrasCartillasData({
    required this.servicio,
    required this.distrito,
    required this.circuito,
    required this.fechaHora,
    required this.direccion,
    required this.causa,
    required this.novedades,
    this.moto,
    this.can,
    this.movil,
    this.bicicleta,
    this.videoperador,
    this.movilesEnCirculacion = const [],
    this.reporta = '',
  });
}

class OtrasCartillasText {
  OtrasCartillasText._();

  static String servicioTitle(String servicio) {
    const titles = {
      'MOTORIZADO': 'REPORTE DE MOTORIZADO',
      'K9': 'REPORTE DE K9',
      'EAS': 'REPORTE DE EAS',
      'PEDESTRE': 'REPORTE DE PEDESTRE',
      'TURISMO': 'REPORTE DE TURISMO',
      'CICLISTA': 'REPORTE DE CICLISTA',
      'ADMINISTRATIVO': 'REPORTE DE ADMINISTRATIVO',
      'AMBIENTE': 'REPORTE DE AMBIENTE GOCAM',
      'ENCARGADO': 'REPORTE DE ENCARGADO',
      'GESTION DE RIESGOS': 'REPORTE DE GESTIÓN DE RIESGOS',
      'SUPERVISION': 'REPORTE DE SUPERVISIÓN',
      'RADIOPERADOR': 'REPORTE DE RADIOPERADOR',
    };
    return titles[servicio] ?? 'REPORTE DE $servicio';
  }

  static String build(OtrasCartillasData data) {
    final servicio = _clean(data.servicio).toUpperCase();
    final distrito = _clean(data.distrito);
    final circuito = _clean(data.circuito);
    final direccion = _clean(data.direccion);
    final causa = _clean(data.causa);
    final novedades = _clean(data.novedades);
    final now = data.fechaHora;
    final hora = '${_two(now.hour)}:${_two(now.minute)}';
    final fecha = '${_two(now.day)}/${_two(now.month)}/${now.year}';
    final horario = CrtTextGenerator.obtenerHorarioJornada();

    final header = <String>[
      '*CUERPO DE AGENTES DE CONTROL MUNICIPAL*',
      '*$servicio*',
      if (distrito.isNotEmpty) '*DISTRITO:* $distrito',
      if (circuito.isNotEmpty) '*CIRCUITO:* $circuito',
      '*HORARIO:* $horario',
      '*HORA:* $hora',
      '*FECHA:* $fecha',
      if (direccion.isNotEmpty) '*DIRECCIÓN:* $direccion',
      '*CAUSA:* $causa',
    ];

    final saludo = now.hour >= 6 && now.hour < 12
        ? 'Buenos días'
        : now.hour >= 12 && now.hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';
    final jefe = CrtTextGenerator.jefeDisplay;

    final bodyText = novedades.isNotEmpty
        ? novedades
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.';

    final extrasReporta = <String>[
      if (_has(data.moto)) '*MOTO:* ${_clean(data.moto!)}',
      if (_has(data.can)) '*CAN:* ${_clean(data.can!)}',
      if (_has(data.bicicleta)) '*BICICLETA:* ${_clean(data.bicicleta!)}',
      if (_has(data.videoperador))
        '*VIDEOPERADOR:* ${_clean(data.videoperador!)}',
    ];

    final extrasAntesReporta = <String>[];
    if (data.movilesEnCirculacion.isNotEmpty) {
      final moviles = data.movilesEnCirculacion
          .map(_clean)
          .where((value) => value.isNotEmpty)
          .map(
            (value) => value.toLowerCase().startsWith('móvil ')
                ? value
                : 'MÓVIL $value',
          )
          .join('\n');
      if (moviles.isNotEmpty) {
        extrasAntesReporta.add('*MOVILES EN CIRCULACION:*\n$moviles');
      }
    }

    final reporta = _clean(data.reporta);

    return <String>[
      ...header,
      '',
      '$saludo, permiso Sr. $jefe.',
      '',
      bodyText,
      '',
      ...extrasAntesReporta,
      if (_has(data.movil)) '*MÓVIL:* ${_clean(data.movil!)}',
      if (reporta.isNotEmpty) '',
      if (reporta.isNotEmpty) '*REPORTA:*',
      if (reporta.isNotEmpty) 'ACM. $reporta',
      if (extrasReporta.isNotEmpty && reporta.isNotEmpty) ...extrasReporta,
      '',
      '"LEALTAD, VALOR Y ORDEN"',
      '',
      '*ADJUNTO FOTOGRAFIA:*',
    ].join('\n');
  }

  static String _clean(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _two(int value) => value.toString().padLeft(2, '0');

  static bool _has(String? value) => value != null && _clean(value).isNotEmpty;
}
