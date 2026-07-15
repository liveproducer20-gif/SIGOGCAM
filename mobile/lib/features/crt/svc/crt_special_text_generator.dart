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

    return '''*CUERPO AGENTE DE CONTROL MUNICIPAL*

*REPORTE DE FORMACIÓN DE RADIO-OPERADORES*

*Distrito ${data.distrito}*

*Circuito:* ${data.circuito}

*Dirección:* ${data.direccion}

*Horario:* ${data.horario}

*Hora:* ${_time(data.fechaHora)}

*Fecha:* ${_date(data.fechaHora)}

*Causa:* ${data.tipo.causa}

${saludo(data.fechaHora)}, permiso Sr. ${data.jefe}. Muy respetuosamente, le informo que:

Al momento *Forma Personal ${entrante ? 'Entrante' : 'Saliente'} de Radio Operadores del EAS CEIBOS, ACM JP y CONDUCTORES,* se notifican novedades para fines pertinentes, quedando así en constancia que se ${entrante ? 'INICIA' : 'CULMINA'} LA JORNADA LABORAL como se establece la distribución.

*NOVEDADES:*

${novedades.isEmpty ? 'Sin Novedades' : novedades.join('\n')}

*Personal participante:*

${_twoDigits(data.radiooperadores)} ACM Radio operadores

${_twoDigits(data.acmOperativos)} ACM Operativos$personalPolicial

*Móviles en circulación:*

${data.moviles.map((e) => e.trim()).where((e) => e.isNotEmpty).join('-')}

*Reporta:*

$reportantes

*“Lealtad, Valor y Orden”*

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

  static String saludo(DateTime value) {
    if (value.hour < 12) return 'Muy buenos días';
    if (value.hour < 19) return 'Muy buenas tardes';
    return 'Muy buenas noches';
  }

  static List<String> _lines(String value) => value
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && e.toLowerCase() != 'sin novedades')
      .toList();

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
