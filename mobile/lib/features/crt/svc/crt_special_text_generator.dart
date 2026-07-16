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
        : '\n*Móviles en circulación:*\n\n${movilesValidos.join('-')}\n';
    final radioSection = data.radiooperadores > 0
        ? '\n${_twoDigits(data.radiooperadores)} ACM Radio operadores'
        : '';
    final acmSection = data.acmOperativos > 0
        ? '\n${_twoDigits(data.acmOperativos)} ACM Operativos'
        : '';
    final personalHeader = (data.radiooperadores > 0 || data.acmOperativos > 0 || policias.isNotEmpty)
        ? '\n*Personal participante:*'
        : '';

    final circuitoLine = data.circuito.isEmpty ? '' : '*Circuito:* ${data.circuito}\n\n';
    final causa = data.causa.isNotEmpty ? data.causa : data.tipo.causa;
    return '''*CUERPO AGENTE DE CONTROL MUNICIPAL*

$circuitoLine*Dirección:* ${data.direccion}

*Causa:* $causa

*Hora:* ${_time(data.fechaHora)}

*Fecha:* ${_date(data.fechaHora)}

${saludo(data.fechaHora)}, permiso Sr. ${data.jefe}. Muy respetuosamente, le informo que:

Al momento *Forma Personal ${entrante ? 'Entrante' : 'Saliente'} de Radio Operadores del EAS CEIBOS, ACM JP y CONDUCTORES,* se notifican novedades para fines pertinentes, quedando así en constancia que se ${entrante ? 'INICIA' : 'CULMINA'} LA JORNADA LABORAL como se establece la distribución.$novedadesSection$personalHeader$radioSection$acmSection$personalPolicial$movilesSection
*Reporta:*

$reportantes

*"Lealtad, Valor y Orden"*

*Adjunto Fotografía:*''';
  }

  static String conductor(ConductorData data) {
    final observaciones = data.observaciones.trim().isEmpty
        ? 'Sin novedades'
        : data.observaciones.trim();
    return '''*REGISTRO VEHICULAR*

*Nombres del Conductor:* ${data.conductor.trim()}

*Los cuatro últimos números de la Cédula (XXXXXX0000):* ${data.cedulaUltimos4}

*Elige la opción a reportar:* ${data.opcion.label}

*Lugar de la opción a reportar:* ${data.lugar.trim()}

*No. de Disco del Vehículo:* ${data.disco.trim()}

*Indique fecha y hora del reporte:* ${_date(data.fechaHora)} - ${_time(data.fechaHora)}

*Cantidad del Combustible:* ${data.combustible}

*Kilometraje del odómetro al momento del reporte:*

${data.kilometraje} Km

*Circuito, Ruta o Servicio Asignado:* ${data.servicio.trim()}

*Horario Asignado:* ${data.horario.trim()}

*Jefe de Patrulla o Encargado:*

${data.encargado.trim()}

*Observaciones y Novedades:*

$observaciones''';
  }

  static String otras(OtrasCartillasData data) {
    final reportantes = data.reportantes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => 'ACM. $e')
        .join('\n');
    final header = _buildHeader(data);
    final circuitoLine = data.circuito.isEmpty ? '' : '*Circuito:* ${data.circuito}\n\n';
    final horarioLine = data.horario.isEmpty ? '' : '*Horario:* ${data.horario}\n\n';
    final distritoLine = data.distrito.isEmpty ? '' : '*Distrito:* ${data.distrito}\n\n';
    return '''$header*CUERPO AGENTE DE CONTROL MUNICIPAL*

$distritoLine$circuitoLine*Dirección:* ${data.direccion}

*Causa:* ${data.causa}

$horarioLine*Hora:* ${_time12(data.fechaHora)}

*Fecha:* ${_shortDate(data.fechaHora)}

${saludo(data.fechaHora)}, permiso Sr. ${data.jefe}. Muy respetuosamente me permito informarle que en las instalaciones de EAS CEIBOS se registra la siguiente novedad:

${data.novedad.trim()}

Así mismo, se le informó a la Central para que registre la novedad. Información puesta en conocimiento para los fines pertinentes.

*Reporta:*

$reportantes

*"Lealtad Valor Orden"*

*Adjunto Fotografía:*''';
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
