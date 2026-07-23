import '../mdl/crt_enums.dart';
import '../mdl/crt_models.dart';

class CrtTextGenerator {
  CrtTextGenerator._();

  static String _jefeNombre = '';

  static String get jefeDisplay => _jefeNombre.isEmpty
      ? 'Jefe de Control Municipal'
      : '$_jefeNombre Jefe de Control Municipal';

  static String get jefeDisplayCsv => _jefeNombre.isEmpty
      ? 'Jefe de Control Municipal,'
      : '$_jefeNombre, Jefe de Control Municipal,';

  static set jefeNombre(String v) => _jefeNombre = v;

  static String obtenerHorarioJornada() {
    final now = DateTime.now();
    final horaInicio =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    String horaFin;
    if (now.hour >= 6 && now.hour < 14) {
      horaFin = '14:30';
    } else if (now.hour >= 14 && now.hour < 22) {
      horaFin = '22:30';
    } else {
      horaFin = '06:30';
    }

    return '$horaInicio - $horaFin';
  }

  static String build(CrtFormData data) {
    if (data.modulo == TipoModuloCartilla.eas) {
      return _buildEas(data);
    }
    if (data.modulo == TipoModuloCartilla.motorizado) {
      return _buildPatrulla(data, vehicleKey: 'vehiculo');
    }
    if (data.modulo == TipoModuloCartilla.k9) {
      return _buildPatrulla(data, vehicleKey: 'can');
    }
    if (data.modulo == TipoModuloCartilla.ambiente) {
      return _buildAmbiente(data);
    }
    if (data.modulo == TipoModuloCartilla.conductor) {
      return _buildConductor(data);
    }
    if (data.modulo == TipoModuloCartilla.radioperador) {
      return _buildRadioperador(data);
    }
    if (_isOtrasCartillas(data.modulo)) {
      return _buildOtras(data);
    }

    final direccion = _direccion(data);
    final procedimiento = _procedimiento(data);
    final puntoMartillo = data.tipo == TipoCartilla.ausentismo
        ? ''
        : '\n\nEn la calle $direccion.';

    final causa = data.values['causa']?.trim() ?? '';
    final personal = _personal(data);
    final movilBlock = _bloqueMovil(data);
    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
*FECHA:* ${data.fecha}
*HORA:* ${data.hora}
*HORARIO:* ${data.horario}
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

${_saludo(DateTime.now())}, permiso Sr. $jefeDisplay.

Muy respetuosamente me permito informar que $procedimiento$puntoMartillo

$personal
$movilBlock
*REPORTA:*
${_reporta(data)}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildPatrulla(CrtFormData data, {required String vehicleKey}) {
    final causa = data.values['causa']?.trim() ?? '';
    final direccion = _direccion(data);
    final novedad = data.values['novedad']?.trim() ?? '';
    final personal = _personalPatrulla(data);
    final reporta = _reportaPatrulla(data, vehicleKey);
    final now = DateTime.now();
    final isRt = data.tipo == TipoCartilla.retiroTemporal;

    final bodyText = novedad.isNotEmpty
        ? 'Muy respetuosamente me permito informar que, a la altura de $direccion, se procede a $novedad.\n\nAsimismo, notifico la presente novedad para los fines correspondientes.'
        : 'Muy respetuosamente me permito informar que, a la altura de $direccion, se procede a atender la novedad reportada.\n\nAsimismo, notifico la presente novedad para los fines correspondientes.';

    final rtSection = isRt ? _rtSectionText(data) : '';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
*FECHA:* ${data.fecha}
*HORA:* ${data.hora}
*HORARIO:* ${data.horario}
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$rtSection$personal
*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildAmbiente(CrtFormData data) {
    final direccion = _direccion(data);
    final novedad = data.values['novedad']?.trim() ?? '';
    final personal = _personalAmbiente(data);
    final reporta = _reporta(data);
    final now = DateTime.now();
    final causa = data.tipo.label;
    final isRt = data.tipo == TipoCartilla.retiroTemporal;

    final bodyText = novedad.isNotEmpty
        ? novedad
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.';

    final rtSection = isRt ? _rtSectionText(data) : '';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE AMBIENTE GOCAM*
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCIÓN:* $direccion
*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$rtSection$personal
*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static bool _isOtrasCartillas(TipoModuloCartilla modulo) {
    return const {
      TipoModuloCartilla.filaPedestre,
      TipoModuloCartilla.administrativo,
      TipoModuloCartilla.ciclista,
      TipoModuloCartilla.palacio,
      TipoModuloCartilla.cuadrante,
      TipoModuloCartilla.apoyoSeguridadCiudadana,
      TipoModuloCartilla.supervision,
    }.contains(modulo);
  }

  static String _buildOtras(CrtFormData data) {
    final direccion = _direccion(data);
    final causa = data.values['causa']?.trim() ?? '';
    final novedad = data.values['novedad']?.trim() ?? '';
    final personal = _personalOtras(data);
    final reporta = _reportaOtras(data);
    final now = DateTime.now();
    final isRt = data.tipo == TipoCartilla.retiroTemporal;

    final bodyText = novedad.isNotEmpty
        ? '$novedad\n\nAsí mismo, notifico novedades para fines pertinentes.'
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.\n\nAsí mismo, notifico novedades para fines pertinentes.';

    final extraLines = _extraFieldsOtras(data);
    final rtSection = isRt ? _rtSectionText(data) : '';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$rtSection$extraLines$personal
*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _rtSectionText(CrtFormData data) {
    final actividad = data.values['actividad']?.trim() ?? '';
    final elementos = data.values['elementos']?.trim() ?? '';
    final cantidad = data.values['cantidad']?.trim() ?? '';
    if (actividad.isEmpty && elementos.isEmpty && cantidad.isEmpty) return '';
    final lines = <String>['*RETIRO TEMPORAL:*'];
    if (actividad.isNotEmpty) lines.add('Actividad comercial: $actividad');
    if (elementos.isNotEmpty) lines.add('Elementos retirados: $elementos');
    if (cantidad.isNotEmpty) lines.add('Cantidad aproximada: $cantidad');
    return '${lines.join('\n')}\n\n';
  }

  static String _extraFieldsOtras(CrtFormData data) {
    if (data.modulo == TipoModuloCartilla.supervision) {
      final movil = data.values['movil']?.trim() ?? '';
      final conductor = data.values['conductor']?.trim() ?? '';
      final auxiliar1 = data.values['auxiliar1']?.trim() ?? '';
      final auxiliar2 = data.values['auxiliar2']?.trim() ?? '';
      final lines = <String>[];
      if (movil.isNotEmpty) lines.add('*MÓVIL:* $movil');
      if (conductor.isNotEmpty) lines.add('*CONDUCTOR:* $conductor');
      if (auxiliar1.isNotEmpty) lines.add('*AUXILIAR 1:* $auxiliar1');
      if (auxiliar2.isNotEmpty) lines.add('*AUXILIAR 2:* $auxiliar2');
      return lines.isEmpty ? '' : '${lines.join('\n')}\n';
    }
    return '';
  }

  static String _buildConductor(CrtFormData data) {
    final direccion = _direccion(data);
    final causa = data.values['causa']?.trim() ?? '';
    final novedad = data.values['novedad']?.trim() ?? '';
    final movil = data.values['movil']?.trim() ?? '';
    final conductor = data.values['conductor']?.trim() ?? '';
    final ruta = data.values['ruta']?.trim() ?? '';
    final jp = data.values['jp']?.trim() ?? '';
    final auxiliar = data.values['auxiliar']?.trim() ?? '';
    final reporta = _reporta(data);
    final now = DateTime.now();
    final isRt = data.tipo == TipoCartilla.retiroTemporal;

    final personalLines = <String>[];
    if (conductor.isNotEmpty) personalLines.add(conductor);
    if (jp.isNotEmpty) personalLines.add('JP: $jp');
    if (auxiliar.isNotEmpty) personalLines.add('Auxiliar: $auxiliar');
    final personalBlock = personalLines.isEmpty
        ? ''
        : '*PERSONAL ASIGNADO:*\n${personalLines.join('\n')}';

    final bodyText = novedad.isNotEmpty
        ? '$novedad\n\nAsí mismo, notifico novedades para fines pertinentes.'
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.\n\nAsí mismo, notifico novedades para fines pertinentes.';

    final movilLine = movil.isNotEmpty ? '*MÓVIL:* $movil\n' : '';
    final rutaLine = ruta.isNotEmpty ? '*RUTA/CIRCUITO:* $ruta\n' : '';
    final rtSection = isRt ? _rtSectionText(data) : '';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE CONDUCTOR*
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$rtSection$movilLine$rutaLine$personalBlock
*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildRadioperador(CrtFormData data) {
    final direccion = _direccion(data);
    final causa = data.values['causa']?.trim() ?? '';
    final personal = data.values['personal']?.trim() ?? '';
    final moviles = data.values['moviles']?.trim() ?? '';
    final policias = data.values['policias']?.trim() ?? '';
    final novedadPersonal = data.values['novedadPersonal']?.trim() ?? '';
    final novedadMovil = data.values['novedadMovil']?.trim() ?? '';
    final reporta = _reporta(data);
    final now = DateTime.now();
    final horario = _horarioEas(now);
    final isRt = data.tipo == TipoCartilla.retiroTemporal;

    final bodyLines = <String>[
      'Muy respetuosamente me permito informar que se realizó el cambio de personal del EAS, reportando lo siguiente:',
    ];

    final novedadBlock = <String>[];
    if (novedadPersonal.isNotEmpty) {
      novedadBlock.add('*NOVEDADES DE PERSONAL:*\n$novedadPersonal');
    }
    if (novedadMovil.isNotEmpty) {
      novedadBlock.add('*NOVEDADES DE MÓVIL:*\n$novedadMovil');
    }
    final novedadText = novedadBlock.isEmpty
        ? ''
        : '\n\n${novedadBlock.join('\n\n')}';

    final personalLine = personal.isNotEmpty ? '*PERSONAL:*\n$personal\n' : '';
    final movilesLine = moviles.isNotEmpty
        ? '*MÓVILES OPERATIVOS:*\n$moviles\n'
        : '';
    final policiasLine = policias.isNotEmpty ? '*POLICÍAS:*\n$policias\n' : '';
    final rtSection = isRt ? _rtSectionText(data) : '';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE RADIOOPERADORES EAS*
*HORARIO:* $horario
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

${bodyLines.join(' ')}$novedadText

$rtSection$personalLine$movilesLine$policiasLine*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _horarioEas(DateTime now) {
    final h = now.hour;
    if (h >= 6 && h < 14) return '06:00 A 14:30';
    if (h >= 14 && h < 22) return '14:00 A 22:30';
    return '22:00 A 06:30';
  }

  static const _unifiedEasTypes = {
    TipoCartilla.desalojoVendedores,
    TipoCartilla.puntoMartillo,
    TipoCartilla.rondasDisuasivas,
    TipoCartilla.retiroTemporal,
    TipoCartilla.requerimiento,
    TipoCartilla.colaboracionEntidades,
    TipoCartilla.colaboracionEventos,
  };

  static String _buildEas(CrtFormData data) {
    final eas = data.eas;
    final direccion = _direccion(data);
    final circuito = eas == null
        ? 'EAS'
        : '${eas.codigo.replaceFirst('ECO', 'EAS')} - ${eas.nombre}';
    final causa = data.tipo.label;

    if (_unifiedEasTypes.contains(data.tipo)) {
      return _buildEasUnified(data, circuito, causa, direccion);
    }
    if (data.tipo == TipoCartilla.permisoAusentismo) {
      return _buildEasAusentismo(data, circuito, causa, direccion);
    }
    if (_isGenericWizardTipo(data.tipo)) {
      return _buildEasDefaultWizard(data, circuito, causa, direccion);
    }
    if (_isCardTipo(data.tipo)) {
      return _buildEasGeneric(data, circuito, causa, direccion);
    }

    final movil = data.movil == null || data.movil!.trim().isEmpty
        ? 'Móvil'
        : 'Móvil ${data.movil}';
    final cp = data.dotacion[RolMovil.conductor]?.trim();
    final jp = data.dotacion[RolMovil.jp]?.trim();
    final policia = _v(data, 'policia');
    final procedimiento = _procedimientoEas(data, direccion);

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

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasUnified(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final now = DateTime.now();
    final novedad = data.values['novedad']?.trim() ?? '';
    final accion = causa;

    final body = StringBuffer();
    body.write('${_saludo(now)}, permiso Sr. $jefeDisplay.');
    body.writeln();
    body.writeln();
    body.write(
      'Muy respetuosamente me permito informar que, a la altura de $direccion, se procedió a realizar $accion.',
    );
    if (novedad.isNotEmpty) {
      body.writeln();
      body.writeln();
      body.write(novedad);
    }
    body.writeln();
    body.writeln();
    body.write(
      'Asimismo, notifico la presente novedad para los fines correspondientes.',
    );

    return body.toString();
  }

  static bool _isCardTipo(TipoCartilla tipo) {
    return [TipoCartilla.permisoAusentismo].contains(tipo);
  }

  static String _buildEasGeneric(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_ez_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_ez_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_ez_jp');
    final cp = _v(data, '_ez_cp');
    final aux = _v(data, '_ez_aux');
    final policia = _v(data, '_ez_policia');
    final saludo = _saludoFormal(DateTime.now());

    final accion = switch (data.tipo) {
      TipoCartilla.retiroTemporal =>
        'retiro temporal, manteniendo el orden y la seguridad ciudadana',
      TipoCartilla.requerimiento =>
        'requerimiento ciudadano, brindando la atención necesaria',
      TipoCartilla.colaboracionEntidades =>
        'colaboración con otras entidades, apoyando en las actividades planificadas',
      TipoCartilla.colaboracionEventos =>
        'colaboración ciudadana, apoyando en las actividades del sector',
      TipoCartilla.permisoAusentismo =>
        'permiso de ausentismo, dejando constancia para conocimiento de la superioridad',
      _ => 'la novedad reportada, dando atención conforme al procedimiento',
    };

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
$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" se procedió con $accion.
Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString()}

*"LEALTAD, VALOR Y ORDEN"*
*ADJUNTO FOTOGRAFÍA:*''';
  }

  static bool _isGenericWizardTipo(TipoCartilla tipo) {
    return [
      TipoCartilla.presenciaAgenteControl,
      TipoCartilla.operativoConjunto,
      TipoCartilla.roboManoArmada,
      TipoCartilla.perdidaBienInmueble,
      TipoCartilla.extorsion,
      TipoCartilla.amenazas,
      TipoCartilla.desaparicionPersona,
      TipoCartilla.agresion,
      TipoCartilla.visualizacionCamaras,
      TipoCartilla.resguardoPersonal,
      TipoCartilla.colaboracionAtm,
    ].contains(tipo);
  }

  static String _buildEasAusentismo(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_aus_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_aus_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_aus_jp');
    final cp = _v(data, '_aus_cp');
    final aux1 = _v(data, '_aus_aux1');
    final aux2 = _v(data, '_aus_aux2');
    final policia = _v(data, '_aus_policia');
    final tipoPermiso = _v(data, '_aus_tipoPermiso');
    final horaSalida = _v(data, '_aus_horaSalida');
    final horaRetorno = _v(data, '_aus_horaRetorno');
    final fechaInicio = _v(data, '_aus_fechaInicio');
    final fechaFin = _v(data, '_aus_fechaFin');
    final motivo = _v(data, '_aus_motivo');
    final lugar = _v(data, '_aus_lugar');
    final detalle = _v(data, '_aus_detalle');
    final infoAdicional = _v(data, '_aus_infoAdicional');

    final saludo = _saludoFormal(DateTime.now());

    final procedimiento = StringBuffer();
    if (tipoPermiso == 'Permiso por horas') {
      procedimiento.write(
        '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" me retiro temporalmente de mis funciones por motivo de $motivo, desde las $horaSalida hasta las $horaRetorno.',
      );
    } else {
      procedimiento.write(
        '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" me ausentaré temporalmente de mis funciones por motivo de $motivo, desde el día $fechaInicio hasta el día $fechaFin.',
      );
    }

    if (lugar.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write(
        'Durante este ${tipoPermiso == 'Permiso por horas' ? 'tiempo' : 'período'} me trasladaré hacia $lugar para cumplir con la diligencia correspondiente.',
      );
    }

    if (detalle.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.writeln('El motivo específico del permiso corresponde a:');
      procedimiento.writeln();
      procedimiento.write(detalle);
    }

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final un = _v(data, '_aus_userNombre');
      if (un.isNotEmpty) auxNames.add(un);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) auxNames.add(jp);
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uAux = auxNames.toSet().toList();

    final rp = StringBuffer();
    rp.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      rp.writeln('*JP:* $policia');
    } else {
      rp.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final a in uAux) {
      rp.writeln('*Aux.:* $a');
    }

    final adicional = infoAdicional.isEmpty ? '' : '\n$infoAdicional\n';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:* MODELO
*CIRCUITO:* $circuito
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCION:* $dir

*CAUSA:* $causa

*PROCEDIMIENTO*:
${procedimiento.toString()}$adicional
Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${rp.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*
*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasDefaultWizard(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_ez_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_ez_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_ez_jp');
    final cp = _v(data, '_ez_cp');
    final aux1 = _v(data, '_ez_aux1');
    final aux2 = _v(data, '_ez_aux2');
    final policia = _v(data, '_ez_policia');

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final userNombre = _v(data, '_ez_userNombre');
      if (userNombre.isNotEmpty) auxNames.add(userNombre);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) {
      auxNames.add(jp);
    }
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uniqueAux = auxNames.toSet().toList();

    final rp = StringBuffer();
    rp.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      rp.writeln('*JP:* $policia');
    } else {
      rp.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final a in uniqueAux) {
      rp.writeln('*Aux.:* $a');
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

${_procedimientoEas(data, dir)}

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${rp.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _procedimientoEas(CrtFormData data, String direccion) {
    final saludo =
        '${_saludoFormal(DateTime.now())}, Sr. $jefeDisplayCsv muy respetuosamente me permito informarle que';
    final puntoMartillo =
        data.tipo == TipoCartilla.permisoAusentismo ||
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

    return _compact(
      '$saludo $body$puntoMartillo${detalle.isEmpty ? '' : ' $detalle'}',
    );
  }

  static String _buildDesalojoBody(CrtFormData data, String direccion) {
    final direc = _v(data, '_desa_direccion');
    final esAgresivo = _v(data, '_desa_agresivo');
    final necesitaColab = _v(data, '_desa_colaboracion');

    final calle = direc.isEmpty ? direccion : direc;
    final saludo = _saludoFormal(DateTime.now());

    if (esAgresivo == 'no') {
      return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$calle" se realizo el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo de manera pacífica y respetando la integridad de los señores comerciantes no regularizados se les indicó que no pueden permanecer en el lugar y que posterior a ello se retiren del sitio, así mismo haciendo cumplir la ordenanza municipal De Uso De Espacio Y Vía Pública se dejó el espacio sin novedad.';
    }

    if (necesitaColab == 'si') {
      return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$calle" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso a las indicaciones que se les está dando de parte del personal municipal, solicito colaboración con otro móvil para realizar un operativo en el sector mencionado para evitar el asentamiento no regularizado de los comerciantes en el punto.';
    }

    return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$calle" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso, de tal manera se les indicó que, si mantenían esa actitud y no colaboraban con lo solicitado, se procedería a realizar el retiro temporal de la mercadería, de tal modo una vez indicado el procedimiento que iba a tomar el personal municipal, procedieron a retirarse.';
  }

  static String _ubicacionInstitucional(CrtFormData data, String direccion) {
    if (data.modulo == TipoModuloCartilla.eas && data.eas != null) {
      return '*DISTRITO:* #5 MODELO\n*CIRCUITO:* ${data.eas!.codigo} ${data.eas!.nombre}\n*DIRECCIÓN:* $direccion';
    }
    if (data.modulo == TipoModuloCartilla.motorizado) {
      final distrito = data.values['distrito']?.trim() ?? '';
      if (distrito.isNotEmpty) {
        return '*DISTRITO:* $distrito\n*DIRECCIÓN/PUNTO:* $direccion';
      }
      return '*DIRECCIÓN/PUNTO:* $direccion';
    }
    if (data.modulo == TipoModuloCartilla.conductor) {
      final movil = data.values['movil']?.trim() ?? '';
      final movilLine = movil.isNotEmpty ? '*MÓVIL:* $movil\n' : '';
      final distrito = data.values['distrito']?.trim() ?? '';
      final distritoLine = distrito.isNotEmpty ? '*DISTRITO:* $distrito\n' : '';
      return '$distritoLine$movilLine*DIRECCIÓN/PUNTO:* $direccion';
    }
    if (data.modulo == TipoModuloCartilla.cuadrante) {
      final cuadrante = data.values['cuadrante']?.trim() ?? '';
      final movil = data.values['movil']?.trim() ?? '';
      final motorizado = data.values['motorizado']?.trim() ?? '';
      final distrito = data.values['distrito']?.trim() ?? '';
      final lines = <String>[];
      if (distrito.isNotEmpty) lines.add('*DISTRITO:* $distrito');
      if (cuadrante.isNotEmpty) lines.add('*CUADRANTE:* $cuadrante');
      if (movil.isNotEmpty) lines.add('*MÓVIL:* $movil');
      if (motorizado.isNotEmpty) lines.add('*MOTORIZADO:* $motorizado');
      lines.add('*DIRECCIÓN/PUNTO:* $direccion');
      return lines.join('\n');
    }
    if (_isOtrasCartillas(data.modulo)) {
      final distrito = data.values['distrito']?.trim() ?? '';
      if (distrito.isNotEmpty) {
        return '*DISTRITO:* $distrito\n*DIRECCIÓN:* $direccion';
      }
      return '*DIRECCIÓN:* $direccion';
    }
    return '*DIRECCIÓN/PUNTO:* $direccion';
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

    if (values.isEmpty) return '';
    return '*PERSONAL INVOLUCRADO:*\n${values.join('\n')}';
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
    return reporta == null || reporta.isEmpty
        ? '[persona que reporta]'
        : reporta;
  }

  static String _reportaOtras(CrtFormData data) {
    final reporta = data.values['reporta']?.trim() ?? '';
    final name = reporta.isEmpty ? '[persona que reporta]' : reporta;
    if (data.modulo == TipoModuloCartilla.ciclista) {
      final bicicleta = data.values['bicicleta']?.trim() ?? '';
      if (bicicleta.isNotEmpty) {
        return 'Bicicleta $bicicleta - $name';
      }
    }
    return name;
  }

  static String _saludo(DateTime now) {
    if (now.hour >= 5 && now.hour < 12) return 'Buenos días';
    if (now.hour >= 12 && now.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static String _saludoFormal(DateTime now) {
    if (now.hour < 12) return 'Muy buenos días';
    if (now.hour < 19) return 'Muy buenas tardes';
    return 'Muy buenas noches';
  }

  static String _saludoPatrulla(DateTime now) {
    if (now.hour >= 5 && now.hour < 12) return 'Buenos días';
    if (now.hour >= 12 && now.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static String _personalPatrulla(CrtFormData data) {
    final personal = data.values['personal']?.trim() ?? '';
    if (personal.isEmpty) return '';
    return '*PERSONAL MOTORIZADO:*\n$personal';
  }

  static String _personalAmbiente(CrtFormData data) {
    final personal = data.values['personal']?.trim() ?? '';
    if (personal.isEmpty) return '';
    return '*PERSONAL ASIGNADO:*\n$personal';
  }

  static String _personalOtras(CrtFormData data) {
    final personal = data.values['personal']?.trim() ?? '';
    if (personal.isEmpty) return '';
    return '*PERSONAL ASIGNADO:*\n$personal';
  }

  static String _reportaPatrulla(CrtFormData data, String vehicleKey) {
    final reporta = data.values['reporta']?.trim() ?? '';
    final vehicle = data.values[vehicleKey]?.trim() ?? '';
    final name = reporta.isEmpty ? '[persona que reporta]' : reporta;
    if (vehicle.isNotEmpty) {
      return '$vehicle $name';
    }
    return name;
  }

  static String _v(CrtFormData data, String key) {
    return data.values[key]?.trim() ?? '';
  }

  static String _compact(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
