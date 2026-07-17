import '../mdl/crt_enums.dart';
import '../mdl/crt_models.dart';

class CrtTextGenerator {
  CrtTextGenerator._();

  static String _jefeNombre = '';

  static String get jefeDisplay =>
      _jefeNombre.isEmpty ? 'Jefe de Control Municipal' : '$_jefeNombre Jefe de Control Municipal';

  static String get jefeDisplayCsv =>
      _jefeNombre.isEmpty ? 'Jefe de Control Municipal,' : '$_jefeNombre, Jefe de Control Municipal,';

  static set jefeNombre(String v) => _jefeNombre = v;

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

    final bodyText = novedad.isNotEmpty
        ? 'Muy respetuosamente me permito informar que, a la altura de $direccion, se procede a $novedad.\n\nAsimismo, notifico la presente novedad para los fines correspondientes.'
        : 'Muy respetuosamente me permito informar que, a la altura de $direccion, se procede a atender la novedad reportada.\n\nAsimismo, notifico la presente novedad para los fines correspondientes.';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
*FECHA:* ${data.fecha}
*HORA:* ${data.hora}
*HORARIO:* ${data.horario}
${_ubicacionInstitucional(data, direccion)}
*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$personal
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

    final bodyText = novedad.isNotEmpty
        ? novedad
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE AMBIENTE GOCAM*
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCIÓN:* $direccion

*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$personal
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
    final reporta = _reporta(data);
    final now = DateTime.now();

    final bodyText = novedad.isNotEmpty
        ? novedad
        : 'Muy respetuosamente me permito informar que se atendió la novedad reportada en $direccion.';

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE ${data.modulo.label.toUpperCase()}*
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCIÓN:* $direccion

*CAUSA:* $causa

${_saludoPatrulla(now)}, permiso Sr. $jefeDisplay.

$bodyText

$personal
*REPORTA:*
$reporta

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
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
    if (data.tipo == TipoCartilla.rondasDisuasivas) {
      return _buildEasRondasDisuasivas(data, circuito, causa, direccion);
    }
    if (data.tipo == TipoCartilla.retiroTemporal) {
      return _buildEasRetiroTemporal(data, circuito, causa, direccion);
    }
    if (data.tipo == TipoCartilla.colaboracionEntidades) {
      if (_v(data, '_col_subtype') == 'accidente') {
        return _buildEasColaboracionAccidente(data, circuito, causa, direccion);
      }
      return _buildEasColaboracionEntidad(data, circuito, causa, direccion);
    }
    if (data.tipo == TipoCartilla.requerimiento) {
      return _buildEasRequerimiento(data, circuito, causa, direccion);
    }
    if (data.tipo == TipoCartilla.colaboracionEventos) {
      return _buildEasColaboracionCiudadana(data, circuito, causa, direccion);
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

*REPORTA:*
${reporta.toString()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
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

$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" se procedió con Punto martillo, dando apoyo a la seguridad ciudadana y presencia disuasiva.

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasRondasDisuasivas(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_rd_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_rd_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_rd_jp');
    final cp = _v(data, '_rd_cp');
    final aux = _v(data, '_rd_aux');
    final policia = _v(data, '_rd_policia');
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

$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" se procedió con Rondas disuasivas, dando apoyo a la seguridad ciudadana y presencia disuasiva.

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasRetiroTemporal(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_rt_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_rt_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_rt_jp');
    final cp = _v(data, '_rt_cp');
    final aux1 = _v(data, '_rt_aux1');
    final aux2 = _v(data, '_rt_aux2');
    final policia = _v(data, '_rt_policia');
    final actividad = _v(data, '_rt_actividad');
    final elementos = _v(data, '_rt_elementos');
    final cantidad = _v(data, '_rt_cantidad');
    final saludo = _saludoFormal(DateTime.now());

    final procedimiento = StringBuffer()
      ..write('$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" mediante operativo conjunto con móviles que se encontraban realizando recorridos dentro del circuito $circuito, se procedió a ejecutar acciones de control sobre vendedores autónomos no regularizados que se encontraban ocupando el espacio público.');
    if (actividad.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('Durante el procedimiento se identificó a un comerciante dedicado a la actividad de "$actividad", quien se negaba a retirarse voluntariamente del lugar pese a las indicaciones emitidas por el personal operativo.');
    }
    if (elementos.isNotEmpty || cantidad.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('En cumplimiento de las ordenanzas municipales referentes al uso adecuado del espacio y la vía pública, se procedió a realizar el retiro temporal de mercadería, detallándose los siguientes elementos:');
      if (elementos.isNotEmpty) {
        procedimiento.writeln();
        procedimiento.writeln();
        procedimiento.write(elementos);
      }
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('Cantidad aproximada de elementos retirados temporalmente: ${cantidad.isEmpty ? "no determinada" : cantidad}.');
    }

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final userNombre = _v(data, '_rt_userNombre');
      if (userNombre.isNotEmpty) auxNames.add(userNombre);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) {
      auxNames.add(jp);
    }
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uniqueAux = auxNames.toSet().toList();

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.writeln('*JP:* $policia');
    } else {
      reporta.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final aux in uniqueAux) {
      reporta.writeln('*Aux.:* $aux');
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

${procedimiento.toString()}

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasColaboracionEntidad(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final entidad = _v(data, '_col_entidad');
    final motivo = _v(data, '_col_motivo');
    final direcValue = _v(data, '_col_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_col_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_col_jp');
    final cp = _v(data, '_col_cp');
    final aux1 = _v(data, '_col_aux1');
    final aux2 = _v(data, '_col_aux2');
    final policia = _v(data, '_col_policia');
    final saludo = _saludoFormal(DateTime.now());

    final procedimiento = '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" se procedió con la colaboración a los señores de $entidad${motivo.isEmpty ? "." : " debido a $motivo."}';

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final userNombre = _v(data, '_col_userNombre');
      if (userNombre.isNotEmpty) auxNames.add(userNombre);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) {
      auxNames.add(jp);
    }
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uniqueAux = auxNames.toSet().toList();

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.writeln('*JP:* $policia');
    } else {
      reporta.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final aux in uniqueAux) {
      reporta.writeln('*Aux.:* $aux');
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

$procedimiento

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasColaboracionAccidente(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_col_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_col_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_col_jp');
    final cp = _v(data, '_col_cp');
    final aux1 = _v(data, '_col_aux1');
    final aux2 = _v(data, '_col_aux2');
    final policia = _v(data, '_col_policia');
    final saludo = _saludoFormal(DateTime.now());

    final tipoAcc = _v(data, '_col_tipoAccidente');
    final numHeridos = _v(data, '_col_numHeridos');
    final nombresHeridos = _v(data, '_col_nombresHeridos');
    final huboFallecidos = _v(data, '_col_huboFallecidos');
    final numFallecidos = _v(data, '_col_numFallecidos');
    final nombresFallecidos = _v(data, '_col_nombresFallecidos');
    final criminalistica = _v(data, '_col_criminalistica');
    final criminalisticaNombre = _v(data, '_col_criminalisticaNombre');
    final atm = _v(data, '_col_atm');
    final atmNombre = _v(data, '_col_atmNombre');
    final atmMovil = _v(data, '_col_atmMovil');
    final ambulancia = _v(data, '_col_ambulancia');
    final ambulanciaNombre = _v(data, '_col_ambulanciaNombre');
    final placas = _v(data, '_col_placas');
    final conductores = _v(data, '_col_conductores');
    final danios = _v(data, '_col_danios');
    final cierreVial = _v(data, '_col_cierreVial');
    final cierreVialDesc = _v(data, '_col_cierreVialDesc');
    final traslado = _v(data, '_col_traslado');
    final casaSalud = _v(data, '_col_casaSalud');

    final heridosStr = '$numHeridos herido(s)${nombresHeridos.isEmpty ? '' : ': $nombresHeridos'}';
    final fallecidosStr = huboFallecidos == 'si'
        ? '$numFallecidos fallecido(s)${nombresFallecidos.isEmpty ? '' : ': $nombresFallecidos'}'
        : '0 fallecidos';

    final colaboracionStr = StringBuffer();
    colaboracionStr.write(criminalistica == 'Presente'
        ? 'Criminalística: $criminalisticaNombre'
        : 'Criminalística: No intervino');
    colaboracionStr.write('; ');
    colaboracionStr.write(atm == 'Presente'
        ? 'ATM: $atmNombre${atmMovil.isEmpty ? '' : ' ($atmMovil)'}'
        : 'ATM: No intervino');
    colaboracionStr.write('; ');
    colaboracionStr.write(ambulancia == 'Presente'
        ? 'Ambulancia: $ambulanciaNombre'
        : 'Ambulancia: No intervino');

    final cierreStr = cierreVial == 'si'
        ? cierreVialDesc
        : 'No hubo cierre vial.';

    final trasladoStr = traslado == 'si' && casaSalud.isNotEmpty
        ? '\n\nDebido a las lesiones presentadas, se efectuó el traslado de la persona afectada hacia $casaSalud para su respectiva valoración y atención médica.'
        : '';

    final procedimiento = StringBuffer()
      ..write('$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" me permito informar que se registró un $tipoAcc en el sector asignado.')
      ..writeln();
    if (numHeridos.isNotEmpty || huboFallecidos.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.write('Como resultado del incidente se reportó $heridosStr y $fallecidosStr.');
    }
    procedimiento.writeln();
    procedimiento.writeln();
    procedimiento.write('Durante la atención de la emergencia se contó con la siguiente colaboración institucional: $colaboracionStr.');
    if (placas.isNotEmpty || conductores.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('Los vehículos involucrados corresponden a las placas $placas, siendo sus conductores $conductores.');
    }
    if (danios.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('Entre los daños observados se registró: $danios.');
    }
    procedimiento.writeln();
    procedimiento.writeln();
    procedimiento.write('Así mismo, $cierreStr.');
    if (trasladoStr.isNotEmpty) {
      procedimiento.write(trasladoStr);
    }

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final userNombre = _v(data, '_col_userNombre');
      if (userNombre.isNotEmpty) auxNames.add(userNombre);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) {
      auxNames.add(jp);
    }
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uniqueAux = auxNames.toSet().toList();

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.writeln('*JP:* $policia');
    } else {
      reporta.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final aux in uniqueAux) {
      reporta.writeln('*Aux.:* $aux');
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

${procedimiento.toString()}

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasRequerimiento(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final direcValue = _v(data, '_req_direccion');
    final dir = direcValue.isNotEmpty ? direcValue : direccion;
    final movilStr = _v(data, '_req_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_req_jp');
    final cp = _v(data, '_req_cp');
    final aux1 = _v(data, '_req_aux1');
    final aux2 = _v(data, '_req_aux2');
    final policia = _v(data, '_req_policia');
    final solicitante = _v(data, '_req_solicitante');
    final tipoReq = _v(data, '_req_tipo');
    final infoAdicional = _v(data, '_req_infoAdicional');
    final saludo = _saludoFormal(DateTime.now());

    final accion = switch (tipoReq) {
      'Requerimiento' => 'atender requerimiento en el sector de "$dir" para apoyo a la seguridad ciudadana',
      'Punto martillo' => 'ejecutar punto martillo en "$dir" para control del espacio público y apoyo a la seguridad ciudadana',
      'Ronda disuasiva' => 'realizar ronda disuasiva a lo largo de "$dir" para apoyo a la seguridad ciudadana',
      'Presencia de Agente de Control' => 'brindar presencia de Agente de Control en "$dir" para apoyo a la seguridad ciudadana',
      'Operativo en conjunto' => 'ejecutar operativo en conjunto en "$dir" para control del espacio público y apoyo a la seguridad ciudadana',
      _ => 'atender requerimiento en el sector de "$dir" para apoyo a la seguridad ciudadana',
    };

    final procedimiento = StringBuffer()
      ..write('$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir", por órdenes de $solicitante, se procede a $accion.');
    if (infoAdicional.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write(infoAdicional);
    }

    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final userNombre = _v(data, '_req_userNombre');
      if (userNombre.isNotEmpty) auxNames.add(userNombre);
    }
    if (policia.isNotEmpty && jp.isNotEmpty) {
      auxNames.add(jp);
    }
    if (aux1.isNotEmpty) auxNames.add(aux1);
    if (aux2.isNotEmpty) auxNames.add(aux2);
    final uniqueAux = auxNames.toSet().toList();

    final reporta = StringBuffer();
    reporta.writeln('*CP:* ${cp.isEmpty ? "[CP asignado]" : cp}');
    if (policia.isNotEmpty) {
      reporta.writeln('*JP:* $policia');
    } else {
      reporta.writeln('*JP:* ${jp.isEmpty ? "[JP asignado]" : jp}');
    }
    for (final aux in uniqueAux) {
      reporta.writeln('*Aux.:* $aux');
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

${procedimiento.toString()}

Notifico novedades para fines correspondientes.

$movil

*REPORTA:*
${reporta.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildEasColaboracionCiudadana(
    CrtFormData data,
    String circuito,
    String causa,
    String direccion,
  ) {
    final dir = _v(data, '_ciu_direccion');
    final direccionFinal = dir.isNotEmpty ? dir : direccion;
    final movilStr = _v(data, '_ciu_movil');
    final movil = movilStr.isEmpty ? 'Móvil' : 'MOVIL $movilStr';
    final jp = _v(data, '_ciu_jp');
    final cp = _v(data, '_ciu_cp');
    final aux1 = _v(data, '_ciu_aux1');
    final aux2 = _v(data, '_ciu_aux2');
    final policia = _v(data, '_ciu_policia');
    final tipoGeneral = _v(data, '_ciu_tipoGeneral');
    final tipoEsp = _v(data, '_ciu_tipoEspecifico');
    final nombre = _v(data, '_ciu_nombreCiudadano');
    final cedula = _v(data, '_ciu_cedula');
    final celular = _v(data, '_ciu_celular');
    final lugar = _v(data, '_ciu_lugar');
    final saludo = _saludoFormal(DateTime.now());

    String procedimiento;
    if (tipoGeneral == 'denuncia') {
      procedimiento = _buildCiuDenuncia(saludo, nombre, cedula, celular, lugar, tipoEsp, data);
    } else {
      procedimiento = _buildCiuRequerimiento(saludo, nombre, cedula, celular, lugar, tipoEsp, data);
    }

    final causaLabel = 'Colaboración ciudadana - $tipoEsp';
    final auxNames = <String>[];
    if (data.rolMovil == RolMovil.auxiliar) {
      final un = _v(data, '_ciu_userNombre');
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

    return '''*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:* MODELO
*CIRCUITO:* $circuito
*HORARIO:* ${data.horario}
*HORA:* ${data.hora}
*FECHA:* ${data.fecha}
*DIRECCION:* $direccionFinal

*CAUSA:* $causaLabel

*PROCEDIMIENTO*:

$procedimiento

Así mismo, se le informó a la Central para que registre la novedad.

Información puesta en conocimiento para los fines pertinentes.

$movil

*REPORTA:*
${rp.toString().trimRight()}

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*''';
  }

  static String _buildCiuDenuncia(
    String saludo, String nombre, String cedula, String celular, String lugar,
    String tipo, CrtFormData data,
  ) {
    switch (tipo) {
      case 'Robo a mano armada':
        final bienes = _v(data, '_ciu_bienesRobados');
        final valor = _v(data, '_ciu_valorRobado');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a un caso de robo a mano armada suscitado en $lugar.\n\nEl ciudadano manifiesta que le fueron sustraídos los siguientes bienes: $bienes. Asimismo, indica que el valor aproximado de los bienes robados asciende a $valor.';
      case 'Pérdida de bien inmueble':
        final bienes = _v(data, '_ciu_bienesPerdidos');
        final valor = _v(data, '_ciu_valorPerdido');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a la pérdida de bienes ocurrida en $lugar.\n\nEl ciudadano manifiesta haber extraviado los siguientes bienes: $bienes. Asimismo, indica que el valor aproximado de los bienes perdidos asciende a $valor.';
      case 'Extorsión a local':
        final local = _v(data, '_ciu_nombreLocal');
        final ref = _v(data, '_ciu_referenciaLocal');
        final motivo = _v(data, '_ciu_motivoExtorsion');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a una presunta extorsión a local comercial, suscitada en $lugar.\n\nEl ciudadano manifiesta que el local comercial denominado $local, ubicado como referencia en $ref, estaría siendo objeto de presunta extorsión por el siguiente motivo: $motivo.';
      case 'Amenazas':
        final nA = _v(data, '_ciu_nombreAmenazante');
        final cA = _v(data, '_ciu_cedulaAmenazante');
        final tA = _v(data, '_ciu_textoAmenaza');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a una presunta amenaza suscitada en $lugar.\n\nEl ciudadano manifiesta estar siendo víctima de amenazas por parte de $nA, portador de la cédula de ciudadanía No. $cA, quien presuntamente habría expresado el siguiente texto o frase intimidatoria:\n\n"$tA"\n\nPor lo expuesto, el ciudadano solicita que se deje constancia de lo manifestado para los fines correspondientes.';
      case 'Desaparición de persona':
        final nD = _v(data, '_ciu_nombreDesaparecido');
        final uU = _v(data, '_ciu_ultimaUbicacion');
        final cD = _v(data, '_ciu_cedulaDesaparecido');
        final vest = _v(data, '_ciu_vestimenta');
        final ant = _v(data, '_ciu_antecedente');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a la desaparición de una persona.\n\nEl ciudadano manifiesta que la persona desaparecida responde a los nombres de $nD, con cédula de ciudadanía No. $cD, quien fue vista por última vez en $uU. Asimismo, indica que al momento de su desaparición vestía o portaba lo siguiente: $vest.\n\nRespecto a antecedentes de amenazas anteriores, el ciudadano indica: $ant.';
      case 'Sector o nicho conflictivo':
        final mC = _v(data, '_ciu_motivoConflictivo');
        final rC = _v(data, '_ciu_requerimientoCiudadano');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS para informar una novedad relacionada con un sector conflictivo ubicado en $lugar.\n\nEl ciudadano manifiesta que el sector presenta la siguiente problemática: $mC.\n\nAsimismo, solicita lo siguiente por parte de las autoridades competentes: $rC.';
      case 'Agresión':
        final nAg = _v(data, '_ciu_nombreAgresor');
        final obj = _v(data, '_ciu_objetoAgresion');
        final det = _v(data, '_ciu_detalleHerida');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS debido a una presunta agresión suscitada en $lugar.\n\nEl ciudadano manifiesta que fue agredido por $nAg, quien habría utilizado $obj para ocasionar la lesión.\n\nDe acuerdo con lo manifestado, la agresión se produjo de la siguiente manera: $det.';
      default:
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS para reportar una novedad en $lugar.';
    }
  }

  static String _buildCiuRequerimiento(
    String saludo, String nombre, String cedula, String celular, String lugar,
    String tipo, CrtFormData data,
  ) {
    switch (tipo) {
      case 'Visualizar cámaras':
        final motivo = _v(data, '_ciu_motivoCamaras');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS solicitando la visualización de cámaras por una novedad suscitada en $lugar.\n\nEl ciudadano manifiesta que requiere la revisión del sistema de videovigilancia debido a lo siguiente: $motivo.';
      case 'Colaboración en evento':
        final nEv = _v(data, '_ciu_nombreEvento');
        final hEv = _v(data, '_ciu_horaEvento');
        final fEv = _v(data, '_ciu_fechaEvento');
        final mEv = _v(data, '_ciu_motivoEvento');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS solicitando colaboración institucional para un evento a desarrollarse en $lugar.\n\nEl ciudadano informa que el evento denominado $nEv se llevará a cabo el día $fEv a las $hEv, indicando que la colaboración es requerida debido a: $mEv.';
      case 'Resguardo de personal':
        final motivo = _v(data, '_ciu_motivoResguardo');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS solicitando resguardo de personal en $lugar.\n\nEl ciudadano manifiesta que requiere el acompañamiento o resguardo respectivo debido a: $motivo.';
      case 'Colaboración de ATM':
        final motivo = _v(data, '_ciu_motivoAtm');
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS solicitando colaboración de ATM en $lugar.\n\nEl ciudadano manifiesta que requiere la presencia de personal de ATM debido a: $motivo.';
      default:
        return '$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que al momento se acerca el ciudadano $nombre, con cédula de ciudadanía No. $cedula y número de celular $celular, a la base EAS CEIBOS para solicitar un requerimiento en $lugar.';
    }
  }

  static bool _isCardTipo(TipoCartilla tipo) {
    return [
      TipoCartilla.permisoAusentismo,
    ].contains(tipo);
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
      procedimiento.write('$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" me retiro temporalmente de mis funciones por motivo de $motivo, desde las $horaSalida hasta las $horaRetorno.');
    } else {
      procedimiento.write('$saludo, Sr. $jefeDisplay muy respetuosamente me permito informarle que a la altura de la calle "$dir" me ausentaré temporalmente de mis funciones por motivo de $motivo, desde el día $fechaInicio hasta el día $fechaFin.');
    }

    if (lugar.isNotEmpty) {
      procedimiento.writeln();
      procedimiento.writeln();
      procedimiento.write('Durante este ${tipoPermiso == 'Permiso por horas' ? 'tiempo' : 'período'} me trasladaré hacia $lugar para cumplir con la diligencia correspondiente.');
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
    if (data.modulo == TipoModuloCartilla.ambiente) {
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
    return reporta == null || reporta.isEmpty ? '[persona que reporta]' : reporta;
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
