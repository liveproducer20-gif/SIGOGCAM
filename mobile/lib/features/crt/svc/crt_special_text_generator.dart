import '../mdl/crt_enums.dart';
import '../mdl/crt_special_models.dart';

class CrtSpecialTextGenerator {
  CrtSpecialTextGenerator._();

  static String formacion(FormacionData data) {
    final entrante = data.tipo == TipoFormacion.entrante;
    final novedades = _lines(data.novedades);
    final policias = data.personalPolicial
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final reportantes = data.reportantes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => 'ACM: $e')
        .join('\n');
    final personalPolicial = policias.isEmpty
        ? ''
        : '\n\n${_twoDigits(policias.length)} Personal Policial\n\n${policias.join('\n')}';
    final movilesValidos = data.moviles
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final novedadesSection = novedades.isEmpty
        ? ''
        : '\n*NOVEDADES:*\n\n${novedades.join('\n')}\n';
    final movilesSection = movilesValidos.isEmpty
        ? ''
        : '\n*MÓVILES EN CIRCULACIÓN:*\n\n${movilesValidos.join('-')}\n';
    final radioSection = data.radiooperadores > 0
        ? '\n${_twoDigits(data.radiooperadores)} ACM Radio operadores'
        : '';
    final acmSection = data.acmOperativos > 0
        ? '\n${_twoDigits(data.acmOperativos)} ACM Operativos'
        : '';
    final personalHeader = (data.radiooperadores > 0 || data.acmOperativos > 0 || policias.isNotEmpty)
        ? '\n*PERSONAL PARTICIPANTE:*'
        : '';

    final circuitoLine = data.circuito.isEmpty ? '' : '*CIRCUITO:* ${data.circuito}\n\n';
    final causa = data.causa.isNotEmpty ? data.causa : data.tipo.causa;
    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

$circuitoLine*DIRECCIÓN:* ${data.direccion}

*CAUSA:* $causa

*HORA:* ${_time(data.fechaHora)}

*FECHA:* ${_date(data.fechaHora)}

${saludo(data.fechaHora)}, permiso Sr. ${data.jefe}. Muy respetuosamente, le informo que:

Al momento *Forma Personal ${entrante ? 'Entrante' : 'Saliente'} de Radio Operadores del EAS CEIBOS, ACM JP y CONDUCTORES,* se notifican novedades para fines pertinentes, quedando así en constancia que se ${entrante ? 'INICIA' : 'CULMINA'} LA JORNADA LABORAL como se establece la distribución.$novedadesSection$personalHeader$radioSection$acmSection$personalPolicial$movilesSection
*REPORTA:*

$reportantes

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String conductor(ConductorData data) {
    final observaciones = data.observaciones.trim().isEmpty
        ? 'Sin novedades'
        : data.observaciones.trim();
    return '''*REGISTRO VEHICULAR*

*NOMBRES DEL CONDUCTOR:* ${data.conductor.trim()}

*LOS CUATRO ÚLTIMOS NÚMEROS DE LA CÉDULA (XXXXXX0000):* ${data.cedulaUltimos4}

*ELIGE LA OPCIÓN A REPORTAR:* ${data.opcion.label}

*LUGAR DE LA OPCIÓN A REPORTAR:* ${data.lugar.trim()}

*NO. DE DISCO DEL VEHÍCULO:* ${data.disco.trim()}

*INDIQUE FECHA Y HORA DEL REPORTE:* ${_date(data.fechaHora)} - ${_time(data.fechaHora)}

*CANTIDAD DEL COMBUSTIBLE:* ${data.combustible}

*KILOMETRAJE DEL ODÓMETRO AL MOMENTO DEL REPORTE:*

${data.kilometraje} Km

*CIRCUITO, RUTA O SERVICIO ASIGNADO:* ${data.servicio.trim()}

*HORARIO ASIGNADO:* ${data.horario.trim()}

*JEFE DE PATRULLA O ENCARGADO:*

${data.encargado.trim()}

*OBSERVACIONES Y NOVEDADES:*

$observaciones''';
  }

  static String otras(OtrasCartillasData data) {
    final reportantes = data.reportantes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => 'ACM. $e')
        .join('\n');
    final header = _buildHeader(data);
    final circuitoLine = data.circuito.isEmpty ? '' : '*CIRCUITO:* ${data.circuito}\n\n';
    final horarioLine = data.horario.isEmpty ? '' : '*HORARIO:* ${data.horario}\n\n';
    final distritoLine = data.distrito.isEmpty ? '' : '*DISTRITO:* ${data.distrito}\n\n';
    final novedad = data.novedad.trim();
    final novedadBlock = novedad.isEmpty
        ? ''
        : '\n\n$novedad\n\n';
    return '''$header*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

$distritoLine$circuitoLine*DIRECCIÓN:* ${data.direccion}

*CAUSA:* ${data.causa}

$horarioLine*HORA:* ${_time12(data.fechaHora)}

*FECHA:* ${_shortDate(data.fechaHora)}

${saludo(data.fechaHora)}, permiso Sr. ${data.jefe}. Muy respetuosamente me permito informar a usted que, conforme a las actividades operativas desarrolladas en el sector indicado, se ejecutó el procedimiento correspondiente por concepto de la causa registrada, actuando dentro del ámbito de las competencias institucionales y de acuerdo con los protocolos establecidos.$novedadBlock
Una vez concluido el procedimiento, se deja constancia de la presente actuación para los fines administrativos y operativos correspondientes.

*REPORTA:*

$reportantes

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildHeader(OtrasCartillasData data) {
    if (data.modulo == TipoModuloCartilla.eas) return '*REPORTE DE EAS*\n\n';
    if (data.modulo == TipoModuloCartilla.radioperador) {
      final eas = data.easStation;
      final nombre = eas != null ? eas.nombre.trim() : '';
      if (nombre.isNotEmpty) return '*REPORTE DE RADIOOPERADORES EAS ($nombre)*\n\n';
      return '*REPORTE DE RADIOOPERADORES EAS*\n\n';
    }
    return '';
  }

  static String saludo(DateTime value) {
    if (value.hour < 12) return 'Muy buenos días';
    if (value.hour < 19) return 'Muy buenas tardes';
    return 'Muy buenas noches';
  }

  static List<String> _lines(String value) {
    final seen = <String>{};
    return value
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) {
          if (e.toLowerCase() != 'sin novedades') return true;
          return seen.add(e.toLowerCase());
        })
        .toList();
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _shortDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
  static String _time12(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour < 12 ? 'a. m.' : 'p. m.';
    return '${hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} $period';
  }
}
