import '../mdl/crt_enums.dart';
import '../mdl/crt_models.dart';

class CrtTextGenerator {
  CrtTextGenerator._();

  static String build(CrtFormData data) {
    if (data.modulo == TipoModuloCartilla.eas) {
      return _buildEas(data);
    }

    final direccion = _direccion(data);
    final procedimiento = _procedimiento(data);
    final puntoMartillo = data.tipo == TipoCartilla.ausentismo
        ? ''
        : '\n\nSe procedió con punto martillo en la calle $direccion.';

    return '''*CUERPO AGENTE DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
*Tipo de cartilla:* ${data.tipo.label}
*Fecha:* ${data.fecha}
*Hora:* ${data.hora}
*Jornada:* ${data.jornada.label}
*Horario:* ${data.horario}
${_ubicacionInstitucional(data, direccion)}

${_saludo(DateTime.now())}, permiso Sr. Jefe de Control Municipal.

Muy respetuosamente me permito informar que $procedimiento$puntoMartillo

${_personal(data)}

${_bloqueMovil(data)}

*Reporta:*
${_reporta(data)}

*"Lealtad, Valor y Orden"*

*Adjunto fotografia:*''';
  }

  static String _buildEas(CrtFormData data) {
    final eas = data.eas;
    final direccion = _direccion(data);
    final circuito = eas == null
        ? 'EAS'
        : '${eas.codigo.replaceFirst('ECO', 'EAS')} - ${eas.nombre}';
    final causa = data.tipo.label;
    final procedimiento = _procedimientoEas(data, direccion);

    if (data.tipo == TipoCartilla.desalojoVendedores) {
      return _buildEasDesalojo(data, circuito, causa, procedimiento, direccion);
    }
    if (data.tipo == TipoCartilla.puntoMartillo) {
      return _buildEasPuntoMartillo(data, circuito, causa, direccion);
    }

    final movil = data.movil == null || data.movil!.trim().isEmpty
        ? 'Móvil'
        : 'Móvil ${data.movil}';
    final cp = data.dotacion[RolMovil.conductor]?.trim();
    final jp = data.dotacion[RolMovil.jp]?.trim();
    final policia = _v(data, 'policia');

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:* MODELO
*CIRCUITO:* $circuito
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCIÓN:* $direccion

*CAUSA:* $causa

*PROCEDIMIENTO:*

$procedimiento

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*

*CP:* ${cp == null || cp.isEmpty ? '[CP asignado]' : cp}
*JP:* ${jp == null || jp.isEmpty ? '[JP asignado]' : jp}${policia.isEmpty ? '' : '\n\n*POLICÍA:* $policia'}

*"Lealtad, Valor y Orden"*

Adjunto fotografía''';
  }

  static String _buildEasDesalojo(
    CrtFormData data,
    String circuito,
    String causa,
    String procedimiento,
    String _,
  ) {
    final direcValue = _v(data, '_desa_direccion');
    final direccion = direcValue.isNotEmpty ? direcValue : _direccion(data);
    final movilStr = _v(data, '_desa_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_desa_jp');
    final cp = _v(data, '_desa_cp');
    final aux = _v(data, '_desa_aux');
    final policia = _v(data, '_desa_policia');

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.write('*Aux.:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    } else {
      reporta.write('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
      if (aux.isNotEmpty) {
        reporta.writeln();
        reporta.write('*Aux.:* $aux');
      }
    }
    if (policia.isNotEmpty) {
      reporta.writeln();
      reporta.write('*POLICÍA:* $policia');
    }

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:* MODELO
*CIRCUITO:* $circuito
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCION:* $direccion

*CAUSA:* $causa

*PROCEDIMIENTO:*

$procedimiento

Notifico novedades para fines correspondientes.

$movil

*REPORTA*:
${reporta.toString()}

*"Lealtad, Valor y Orden"*

Adjunto fotografía''';
  }

  static String _buildEasPuntoMartillo(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_pm_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_pm_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_pm_jp');
    final cp = _v(data, '_pm_cp');
    final aux = _v(data, '_pm_aux');
    final policia = _v(data, '_pm_policia');
    final saludo = _saludoFormal(DateTime.now());

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.write('*Aux.:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    } else {
      reporta.write('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    if (aux.isNotEmpty) {
      reporta.writeln();
      reporta.write('*Aux.:* $aux');
    }
    if (policia.isNotEmpty) {
      reporta.writeln();
      reporta.write('*POLICÍA:* $policia');
    }

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:* MODELO
*CIRCUITO:* $circuito
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCION:* $dir

*CAUSA:* $causa

*PROCEDIMIENTO:*

$saludo, Sr. Maldonado Cabrera Freddy Jefe de Control Municipal muy respetuosamente me permito informarle que a la altura de la calle "$dir" se procedió con Punto martillo, dando apoyo a la seguridad ciudadana y presencia disuasiva.

Notifico novedades para fines correspondientes.

$movil

*REPORTA*:
${reporta.toString()}

*"Lealtad, Valor y Orden"*

Adjunto fotografía''';
  }

  static String _procedimientoEas(CrtFormData data, String direccion) {
    final saludo =
        '${_saludoFormal(DateTime.now())}, Sr. Maldonado Cabrera Freddy, Jefe de Control Municipal, muy respetuosamente me permito informarle que';
    final puntoMartillo = data.tipo == TipoCartilla.permisoAusentismo ||
            data.tipo == TipoCartilla.desalojoVendedores
        ? ''
        : ' Se procedió con punto martillo en la calle $direccion.';
    final motivo = _v(data, 'motivo');
    final resultado = _v(data, 'resultado');
    final detalle = _v(data, 'detalle');
    final entidad = _v(data, 'entidad');
    final persona = _v(data, 'persona');
    final servidor = _v(data, 'servidor');
    final horaAusentismo = _v(data, 'horaAusentismo');
    final vehiculos = _v(data, 'vehiculos');
    final personas = _v(data, 'personas');
    final casaSalud = _v(data, 'casaSalud');
    final bien = _v(data, 'bien');
    final camara = _v(data, 'camara');

    final body = switch (data.tipo) {
      TipoCartilla.desalojoVendedores => _buildDesalojoBody(data, direccion),
      TipoCartilla.retiroTemporal =>
        'durante el recorrido preventivo en $direccion se realizó el retiro temporal correspondiente${motivo.isEmpty ? '' : ' debido a $motivo'}, manteniendo el trato respetuoso con las personas presentes y precautelando el buen uso del espacio público. ${resultado.isEmpty ? 'La novedad fue atendida y el punto quedó bajo observación preventiva.' : resultado}',
      TipoCartilla.requerimiento =>
        'se atendió un requerimiento ciudadano en $direccion${motivo.isEmpty ? '' : ' relacionado con $motivo'}, verificando la situación en territorio y brindando la colaboración correspondiente dentro de las competencias municipales. ${resultado.isEmpty ? 'La atención se realizó sin novedades adicionales.' : resultado}',
      TipoCartilla.puntoMartillo =>
        'durante el servicio operativo se mantuvo presencia preventiva en el sector asignado. Se procedió con punto martillo en la calle $direccion, con la finalidad de fortalecer la percepción de seguridad, ordenar el espacio público y atender cualquier novedad que pudiera presentarse durante la jornada.',
      TipoCartilla.rondasDisuasivas =>
        'se realizaron rondas disuasivas por el sector de $direccion, manteniendo presencia preventiva y observación permanente en el área asignada${motivo.isEmpty ? '' : ' por motivo de $motivo'}. El recorrido permitió verificar el normal desarrollo de las actividades en el punto.',
      TipoCartilla.presenciaAgenteControl =>
        'se mantuvo presencia de Agente de Control Municipal en $direccion, cumpliendo acciones preventivas, orientación ciudadana y control del orden en el espacio público. ${resultado.isEmpty ? 'Durante el servicio no se reportaron novedades de relevancia.' : resultado}',
      TipoCartilla.operativoConjunto =>
        'se brindó colaboración dentro de un operativo conjunto con ${entidad.isEmpty ? 'la entidad requirente' : entidad} en $direccion${motivo.isEmpty ? '' : ', con motivo de $motivo'}. La intervención se desarrolló de manera coordinada, manteniendo presencia municipal y apoyo operativo hasta finalizar la actividad. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.colaboracionEntidades =>
        'se prestó colaboración a ${entidad.isEmpty ? 'la entidad solicitante' : entidad} en $direccion${motivo.isEmpty ? '' : ', por motivo de $motivo'}. El personal municipal acompañó el procedimiento, mantuvo el orden y brindó apoyo preventivo hasta la culminación de la novedad. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.permisoAusentismo =>
        'el servidor ${servidor.isEmpty ? 'municipal asignado' : servidor} solicitó permiso de ausentismo${horaAusentismo.isEmpty ? '' : ' a las $horaAusentismo'}${motivo.isEmpty ? '' : ' por motivo de $motivo'}, dejando constancia de la novedad para el registro correspondiente y conocimiento de la superioridad.',
      TipoCartilla.accidente =>
        'se tomó conocimiento de un accidente suscitado en $direccion${vehiculos.isEmpty ? '' : ', con vehículos o placas involucradas: $vehiculos'}${personas.isEmpty ? '' : ', y personas involucradas: $personas'}. Se verificó la situación en el punto y se brindó la colaboración correspondiente${casaSalud.isEmpty ? '' : ', registrando traslado o referencia a $casaSalud'}. ${resultado.isEmpty ? 'La novedad quedó registrada para los fines pertinentes.' : resultado}',
      TipoCartilla.roboManoArmada =>
        'se recibió alerta por presunto robo a mano armada en $direccion${persona.isEmpty ? '' : ', donde se encontraba involucrada o afectada la persona $persona'}. Se procedió a verificar la novedad, orientar a la parte afectada y coordinar la atención correspondiente dentro de las competencias municipales. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.perdidaBienInmueble =>
        'se recibió el reporte de pérdida de ${bien.isEmpty ? 'un bien' : bien} en $direccion${persona.isEmpty ? '' : ', comunicado por $persona'}. Se verificó la información proporcionada y se dejó constancia de la novedad para el seguimiento respectivo. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.extorsion =>
        'se tomó conocimiento de una alerta relacionada con presunta extorsión en $direccion${persona.isEmpty ? '' : ', reportada por $persona'}. Se brindó orientación preventiva y se canalizó la novedad conforme al procedimiento correspondiente. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.amenazas =>
        'se atendió una novedad por presuntas amenazas en $direccion${persona.isEmpty ? '' : ', donde la persona involucrada o afectada fue $persona'}. Se verificó la situación, se mantuvo presencia preventiva y se orientó a la parte reportante para el trámite respectivo. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.desaparicionPersona =>
        'se recibió información sobre la desaparición de una persona en el sector de $direccion${persona.isEmpty ? '' : ', identificada como $persona'}. Se tomó conocimiento de los datos proporcionados, se mantuvo colaboración preventiva y se registró la novedad para la coordinación correspondiente. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.agresion =>
        'se atendió una novedad por presunta agresión en $direccion${persona.isEmpty ? '' : ', con participación o afectación de $persona'}. Se verificó el hecho reportado, se mantuvo presencia municipal preventiva y se brindó la orientación correspondiente. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.visualizacionCamaras =>
        'se realizó visualización de cámaras${camara.isEmpty ? '' : ' en $camara'} relacionada con el sector de $direccion${motivo.isEmpty ? '' : ', por motivo de $motivo'}. La revisión permitió registrar la información necesaria para la atención de la novedad. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.colaboracionEventos =>
        'se brindó colaboración durante el evento desarrollado en $direccion${motivo.isEmpty ? '' : ', por motivo de $motivo'}, manteniendo presencia preventiva, apoyo al orden y orientación ciudadana durante el desarrollo de la actividad. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.resguardoPersonal =>
        'se realizó resguardo de personal en $direccion${persona.isEmpty ? '' : ', correspondiente a $persona'}, manteniendo presencia preventiva y acompañamiento durante el desarrollo de la actividad asignada. ${resultado.isEmpty ? '' : resultado}',
      TipoCartilla.colaboracionAtm =>
        'se brindó colaboración a ATM en $direccion${motivo.isEmpty ? '' : ', por motivo de $motivo'}, manteniendo apoyo preventivo y ordenamiento en el punto hasta la culminación del procedimiento. ${resultado.isEmpty ? '' : resultado}',
      _ =>
        'se registra la novedad correspondiente en $direccion${motivo.isEmpty ? '' : ', por motivo de $motivo'}. ${resultado.isEmpty ? 'El procedimiento se atendió sin novedades adicionales.' : resultado}',
    };

    return _compact('$saludo $body$puntoMartillo${detalle.isEmpty ? '' : ' $detalle'}');
  }

  static String _buildDesalojoBody(CrtFormData data, String direccion) {
    final direc = _v(data, '_desa_direccion');
    final esAgresivo = _v(data, '_desa_agresivo');
    final necesitaColab = _v(data, '_desa_colaboracion');

    final calle = direc.isEmpty ? direccion : direc;
    final saludo = _saludoFormal(DateTime.now());

    if (esAgresivo == 'no') {
      return '$saludo, Sr. Maldonado Cabrera Freddy Jefe de Control Municipal muy respetuosamente me permito informarle que a la altura de la calle "$calle" se realizo el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo de manera pacífica y respetando la integridad de los señores comerciantes no regularizados se les indicó que no pueden permanecer en el lugar y que posterior a ello se retiren del sitio, así mismo haciendo cumplir la ordenanza municipal De Uso De Espacio Y Vía Pública se dejó el espacio sin novedad.';
    }

    if (necesitaColab == 'si') {
      return '$saludo, Sr. Maldonado Cabrera Freddy Jefe de Control Municipal muy respetuosamente me permito informarle que a la altura de la calle "$calle" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso a las indicaciones que se les está dando de parte del personal municipal, solicito colaboración con otro móvil para realizar un operativo en el sector mencionado para evitar el asentamiento no regularizado de los comerciantes en el punto.';
    }

    return '$saludo, Sr. Maldonado Cabrera Freddy Jefe de Control Municipal muy respetuosamente me permito informarle que a la altura de la calle "$calle" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso, de tal manera se les indicó que, si mantenían esa actitud y no colaboraban con lo solicitado, se procedería a realizar el retiro temporal de la mercadería, de tal modo una vez indicado el procedimiento que iba a tomar el personal municipal, procedieron a retirarse.';
  }

  static String _ubicacionInstitucional(CrtFormData data, String direccion) {
    if (data.modulo == TipoModuloCartilla.eas && data.eas != null) {
      return '*Distrito:* #5 MODELO\n*Circuito:* ${data.eas!.codigo} ${data.eas!.nombre}\n*Dirección:* $direccion';
    }
    return '*Area:* ${data.modulo.label}\n*Dirección/Punto:* $direccion';
  }

  static String _direccion(CrtFormData data) {
    final customDir = data.values['direccion']?.trim();
    if (customDir != null && customDir.isNotEmpty) return customDir;

    if (data.modulo == TipoModuloCartilla.eas && data.eas != null) {
      return data.eas!.direccion;
    }

    const keys = ['sector', 'punto', 'ruta', 'area', 'lugar', 'cuadrante'];
    for (final key in keys) {
      final value = data.values[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '[direccion]';
  }

  static String _procedimiento(CrtFormData data) {
    if (data.tipo == TipoCartilla.ausentismo) {
      return data.values['novedad']?.trim().isNotEmpty == true
          ? data.values['novedad']!.trim()
          : 'se registra ausentismo conforme a la novedad indicada.';
    }

    final candidates = [
      data.values['novedad'],
      data.values['procedimiento'],
      data.values['actividad'],
      data.values['resultado'],
      data.values['motivo'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (candidates.isEmpty) {
      return 'se registra ${data.tipo.label.toLowerCase()} sin novedades adicionales.';
    }

    return candidates.join('\n\n');
  }

  static String _personal(CrtFormData data) {
    final values = [
      data.values['personal'],
      data.values['agente'],
      data.values['conductor'],
      data.values['jp'],
      data.values['auxiliar'],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toSet();

    if (values.isEmpty) return '*Personal involucrado:*\nNo registra';
    return '*Personal involucrado:*\n${values.join('\n')}';
  }

  static String _bloqueMovil(CrtFormData data) {
    if (data.modulo != TipoModuloCartilla.eas || data.movil == null) {
      final movil = data.values['movil']?.trim();
      if (movil == null || movil.isEmpty) return '';
      return '*Móvil:* $movil\n';
    }

    return '*Móvil ${data.movil}*';
  }

  static String _reporta(CrtFormData data) {
    if (data.modulo == TipoModuloCartilla.eas &&
        data.rolMovil != null &&
        data.dotacion.isNotEmpty) {
      final roles = [
        data.rolMovil!,
        ...RolMovil.values.where((rol) => rol != data.rolMovil),
      ];

      return roles
          .where((rol) => data.dotacion[rol]?.trim().isNotEmpty == true)
          .map((rol) => '${rol.label} ${data.dotacion[rol]!.trim()}')
          .join('\n');
    }

    final reporta = data.values['reporta']?.trim();
    return reporta == null || reporta.isEmpty ? '[persona que reporta]' : reporta;
  }

  static String _saludo(DateTime now) {
    if (now.hour < 12) return 'Buenos dias';
    if (now.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static String _saludoFormal(DateTime now) {
    if (now.hour < 12) return 'Muy buenos días';
    if (now.hour < 19) return 'Muy buenas tardes';
    return 'Muy buenas noches';
  }

  static String _v(CrtFormData data, String key) {
    return data.values[key]?.trim() ?? '';
  }

  static String _compact(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
