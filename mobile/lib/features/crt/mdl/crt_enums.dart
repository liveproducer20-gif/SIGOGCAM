enum TipoModuloCartilla {
  eas,
  motorizado,
  k9,
  ambiente,
  filaPedestre,
  administrativo,
  ciclista,
  conductor,
  palacio,
  cuadrante,
  apoyoSeguridadCiudadana,
  radioperador,
}

enum TipoCartilla {
  ingreso,
  salida,
  novedades,
  ausentismo,
  incidencia,
  procedimiento,
  apoyo,
  operativo,
  desalojoVendedores,
  retiroTemporal,
  requerimiento,
  puntoMartillo,
  rondasDisuasivas,
  presenciaAgenteControl,
  operativoConjunto,
  colaboracionEntidades,
  permisoAusentismo,
  accidente,
  roboManoArmada,
  perdidaBienInmueble,
  extorsion,
  amenazas,
  desaparicionPersona,
  agresion,
  visualizacionCamaras,
  colaboracionEventos,
  resguardoPersonal,
  colaboracionAtm,
}

enum Jornada {
  matutina,
  vespertina,
  amanecida,
}

enum RolMovil {
  jp,
  conductor,
  auxiliar,
}

extension TipoModuloCartillaX on TipoModuloCartilla {
  String get label {
    switch (this) {
      case TipoModuloCartilla.eas:
        return 'EAS';
      case TipoModuloCartilla.motorizado:
        return 'Motorizado';
      case TipoModuloCartilla.k9:
        return 'K9';
      case TipoModuloCartilla.ambiente:
        return 'Ambiente';
      case TipoModuloCartilla.filaPedestre:
        return 'Fila/Pedestre';
      case TipoModuloCartilla.administrativo:
        return 'Administrativo';
      case TipoModuloCartilla.ciclista:
        return 'Ciclista';
      case TipoModuloCartilla.conductor:
        return 'Conductor';
      case TipoModuloCartilla.palacio:
        return 'Palacio';
      case TipoModuloCartilla.cuadrante:
        return 'Cuadrante';
      case TipoModuloCartilla.apoyoSeguridadCiudadana:
        return 'Apoyo a la Seguridad Ciudadana';
      case TipoModuloCartilla.radioperador:
        return 'Radioperador';
    }
  }
}

extension TipoCartillaX on TipoCartilla {
  String get label {
    switch (this) {
      case TipoCartilla.ingreso:
        return 'Ingreso';
      case TipoCartilla.salida:
        return 'Salida';
      case TipoCartilla.novedades:
        return 'Novedades';
      case TipoCartilla.ausentismo:
        return 'Ausentismo';
      case TipoCartilla.incidencia:
        return 'Incidencia';
      case TipoCartilla.procedimiento:
        return 'Procedimiento';
      case TipoCartilla.apoyo:
        return 'Apoyo';
      case TipoCartilla.operativo:
        return 'Operativo';
      case TipoCartilla.desalojoVendedores:
        return 'Desalojo de vendedores';
      case TipoCartilla.retiroTemporal:
        return 'Retiro temporal';
      case TipoCartilla.requerimiento:
        return 'Requerimiento';
      case TipoCartilla.puntoMartillo:
        return 'Punto Martillo';
      case TipoCartilla.rondasDisuasivas:
        return 'Rondas disuasivas';
      case TipoCartilla.presenciaAgenteControl:
        return 'Presencia de Agente de Control';
      case TipoCartilla.operativoConjunto:
        return 'Operativo conjunto';
      case TipoCartilla.colaboracionEntidades:
        return 'Colaboración con otras entidades';
      case TipoCartilla.permisoAusentismo:
        return 'Permiso de ausentismo';
      case TipoCartilla.accidente:
        return 'Accidente';
      case TipoCartilla.roboManoArmada:
        return 'Robo a mano armada';
      case TipoCartilla.perdidaBienInmueble:
        return 'Pérdida de bien inmueble';
      case TipoCartilla.extorsion:
        return 'Extorsión';
      case TipoCartilla.amenazas:
        return 'Amenazas';
      case TipoCartilla.desaparicionPersona:
        return 'Desaparición de persona';
      case TipoCartilla.agresion:
        return 'Agresión';
      case TipoCartilla.visualizacionCamaras:
        return 'Visualización de cámaras';
      case TipoCartilla.colaboracionEventos:
        return 'Colaboración en eventos';
      case TipoCartilla.resguardoPersonal:
        return 'Resguardo de personal';
      case TipoCartilla.colaboracionAtm:
        return 'Colaboración ATM';
    }
  }
}

extension JornadaX on Jornada {
  String get label {
    switch (this) {
      case Jornada.matutina:
        return 'Matutina';
      case Jornada.vespertina:
        return 'Vespertina';
      case Jornada.amanecida:
        return 'Amanecida';
    }
  }
}

extension RolMovilX on RolMovil {
  String get label {
    switch (this) {
      case RolMovil.jp:
        return 'JP';
      case RolMovil.conductor:
        return 'Conductor';
      case RolMovil.auxiliar:
        return 'Auxiliar';
    }
  }
}
