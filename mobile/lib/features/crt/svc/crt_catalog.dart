import '../mdl/crt_enums.dart';
import '../mdl/crt_models.dart';

class CrtCatalog {
  CrtCatalog._();

  static const commonTypes = [
    TipoCartilla.ingreso,
    TipoCartilla.salida,
    TipoCartilla.novedades,
    TipoCartilla.ausentismo,
    TipoCartilla.incidencia,
    TipoCartilla.procedimiento,
    TipoCartilla.apoyo,
    TipoCartilla.operativo,
    TipoCartilla.retiroTemporal,
  ];

  static const easTypes = [
    TipoCartilla.desalojoVendedores,
    TipoCartilla.retiroTemporal,
    TipoCartilla.requerimiento,
    TipoCartilla.puntoMartillo,
    TipoCartilla.rondasDisuasivas,
    TipoCartilla.presenciaAgenteControl,
    TipoCartilla.operativoConjunto,
    TipoCartilla.colaboracionEntidades,
    TipoCartilla.permisoAusentismo,
    TipoCartilla.accidente,
    TipoCartilla.roboManoArmada,
    TipoCartilla.perdidaBienInmueble,
    TipoCartilla.extorsion,
    TipoCartilla.amenazas,
    TipoCartilla.desaparicionPersona,
    TipoCartilla.agresion,
    TipoCartilla.visualizacionCamaras,
    TipoCartilla.colaboracionEventos,
    TipoCartilla.resguardoPersonal,
    TipoCartilla.colaboracionAtm,
  ];

  static const radioperadorTypes = [
    TipoCartilla.ingreso,
    TipoCartilla.salida,
    TipoCartilla.novedades,
    TipoCartilla.incidencia,
    TipoCartilla.retiroTemporal,
  ];

  static final modules = [
    CrtModuleConfig(
      modulo: TipoModuloCartilla.eas,
      tipos: easTypes,
      fields: easBaseFields,
      showPolicia: true,
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.motorizado,
      tipos: [
        TipoCartilla.ingreso,
        TipoCartilla.salida,
        TipoCartilla.novedades,
        TipoCartilla.ausentismo,
        TipoCartilla.incidencia,
        TipoCartilla.procedimiento,
        TipoCartilla.apoyo,
        TipoCartilla.operativo,
        TipoCartilla.retiroTemporal,
      ],
      fields: [
        CrtFieldConfig(
          key: 'personal',
          label: 'Personal motorizado',
          required: false,
        ),
        CrtFieldConfig(
          key: 'vehiculo',
          label: 'Nombre de moto',
          required: false,
        ),
        CrtFieldConfig(
          key: 'novedad',
          label: 'Novedad o apoyo realizado',
          minLines: 4,
        ),
      ],
      vehicleFieldKey: 'vehiculo',
      vehicleFieldLabel: 'Nombre de moto',
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.k9,
      tipos: [
        TipoCartilla.ingreso,
        TipoCartilla.salida,
        TipoCartilla.novedades,
        TipoCartilla.ausentismo,
        TipoCartilla.incidencia,
        TipoCartilla.procedimiento,
        TipoCartilla.apoyo,
        TipoCartilla.operativo,
        TipoCartilla.retiroTemporal,
      ],
      fields: [
        CrtFieldConfig(key: 'can', label: 'Nombre del can'),
        CrtFieldConfig(
          key: 'novedad',
          label: 'Novedad o apoyo realizado',
          minLines: 4,
        ),
      ],
      vehicleFieldKey: 'can',
      vehicleFieldLabel: 'Nombre del can',
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.ambiente,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(
          key: 'novedad',
          label: 'Descripción de la novedad',
          minLines: 4,
        ),
      ],
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.filaPedestre,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.administrativo,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.ciclista,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'bicicleta', label: 'Nombre de bicicleta'),
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
      vehicleFieldKey: 'bicicleta',
      vehicleFieldLabel: 'Nombre de bicicleta',
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.conductor,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'movil', label: 'Número de móvil'),
        CrtFieldConfig(key: 'conductor', label: 'Conductor'),
        CrtFieldConfig(key: 'jp', label: 'JP', required: false),
        CrtFieldConfig(key: 'auxiliar', label: 'Auxiliar', required: false),
        CrtFieldConfig(key: 'ruta', label: 'Ruta o circuito'),
        CrtFieldConfig(
          key: 'novedad',
          label: 'Novedad o procedimiento',
          minLines: 4,
        ),
      ],
      showPolicia: true,
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.palacio,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.cuadrante,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'movil', label: 'Número de móvil'),
        CrtFieldConfig(key: 'cuadrante', label: 'Nombre del cuadrante'),
        CrtFieldConfig(
          key: 'motorizado',
          label: 'Motorizado a cargo',
          required: false,
        ),
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.apoyoSeguridadCiudadana,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
      showPolicia: true,
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.radioperador,
      tipos: radioperadorTypes,
      fields: [
        CrtFieldConfig(key: 'personal', label: 'Personal entrante o saliente'),
        CrtFieldConfig(key: 'moviles', label: 'Móviles operativos'),
        CrtFieldConfig(key: 'policias', label: 'Policías', required: false),
        CrtFieldConfig(
          key: 'novedadPersonal',
          label: 'Novedades de personal',
          minLines: 3,
        ),
        CrtFieldConfig(
          key: 'novedadMovil',
          label: 'Novedades de móvil',
          minLines: 3,
        ),
      ],
      showPolicia: true,
    ),
    CrtModuleConfig(
      modulo: TipoModuloCartilla.supervision,
      tipos: commonTypes,
      fields: [
        CrtFieldConfig(key: 'movil', label: 'Número de móvil'),
        CrtFieldConfig(key: 'conductor', label: 'Nombre del conductor'),
        CrtFieldConfig(key: 'auxiliar1', label: 'Auxiliar 1', required: false),
        CrtFieldConfig(key: 'auxiliar2', label: 'Auxiliar 2', required: false),
        CrtFieldConfig(key: 'personal', label: 'Personal asignado'),
        CrtFieldConfig(key: 'novedad', label: 'Procedimiento', minLines: 4),
      ],
    ),
  ];

  static const easBaseFields = [
    CrtFieldConfig(
      key: 'detalle',
      label: 'Detalle complementario',
      required: false,
      minLines: 3,
    ),
    CrtFieldConfig(key: 'policia', label: 'Servidor policial', required: false),
  ];

  static const easStations = [
    CrtEasStation(
      codigo: 'ECO 1',
      nombre: 'URDESA',
      direccion: 'AV. VICTOR EMILIO ESTRADA Y CIRCUNVALACIÓN SUR',
    ),
    CrtEasStation(
      codigo: 'ECO 2',
      nombre: 'LOMAS DE URDESA',
      direccion: 'AV. CERROS Y LOMAS DE URDESA',
    ),
    CrtEasStation(
      codigo: 'ECO 3',
      nombre: 'KENNEDY VIEJA',
      direccion: 'AV. FRANCISCO URBINA Y AV. DEL PERIODISTA',
    ),
    CrtEasStation(
      codigo: 'ECO 4',
      nombre: 'KENNEDY NUEVA',
      direccion: 'AV. JOSE SANTIAGO CASTILLO Y VICTOR HUGO',
    ),
    CrtEasStation(
      codigo: 'ECO 5',
      nombre: 'FAE/ATARAZANA',
      direccion: 'AV. AL RAUL COUSIN Y CRNL LUIS LOPES',
    ),
    CrtEasStation(
      codigo: 'ECO 6',
      nombre: 'PUERTO SANTA ANA',
      direccion: 'PUERTO SANTA ANA',
    ),
    CrtEasStation(
      codigo: 'ECO 7',
      nombre: 'SAMANES',
      direccion: 'AV. TEODORO ALVARADO OLEAS',
    ),
    CrtEasStation(
      codigo: 'ECO 8',
      nombre: 'PARQUE CENTENARIO',
      direccion: 'CALLE LORENZO DE GARAICOA Y VELEZ',
    ),
    CrtEasStation(
      codigo: 'ECO 9',
      nombre: 'PLAZA SAN FRANCISCO',
      direccion: 'AV. 9 DE OCTUBRE Y PEDRO CARBO',
    ),
    CrtEasStation(
      codigo: 'ECO 10',
      nombre: 'VIA A LA COSTA',
      direccion: 'CDLA. TERRANOSTRA',
    ),
    CrtEasStation(
      codigo: 'ECO 11',
      nombre: 'BARRIO CENTENARIO',
      direccion: 'AV. DOLORES SUCRE Y MARACAIBO',
    ),
    CrtEasStation(
      codigo: 'ECO 12',
      nombre: 'CEIBOS',
      direccion: 'DR ALBERTO DACACH Y AV 15AVA NO',
    ),
  ];

  static const dotacionEas = {
    'URDESA': [
      CrtMovilDotacion(
        movil: '101',
        integrantes: {
          RolMovil.jp: 'JP Urdesa',
          RolMovil.conductor: 'CP Urdesa',
          RolMovil.auxiliar: 'Auxiliar Urdesa',
        },
      ),
    ],
    'LOMAS DE URDESA': [
      CrtMovilDotacion(
        movil: '102',
        integrantes: {
          RolMovil.jp: 'JP Lomas de Urdesa',
          RolMovil.conductor: 'CP Lomas de Urdesa',
          RolMovil.auxiliar: 'Auxiliar Lomas de Urdesa',
        },
      ),
    ],
    'KENNEDY VIEJA': [
      CrtMovilDotacion(
        movil: '103',
        integrantes: {
          RolMovil.jp: 'JP Kennedy Vieja',
          RolMovil.conductor: 'CP Kennedy Vieja',
          RolMovil.auxiliar: 'Auxiliar Kennedy Vieja',
        },
      ),
    ],
    'KENNEDY NUEVA': [
      CrtMovilDotacion(
        movil: '104',
        integrantes: {
          RolMovil.jp: 'JP Kennedy Nueva',
          RolMovil.conductor: 'CP Kennedy Nueva',
          RolMovil.auxiliar: 'Auxiliar Kennedy Nueva',
        },
      ),
    ],
    'FAE/ATARAZANA': [
      CrtMovilDotacion(
        movil: '105',
        integrantes: {
          RolMovil.jp: 'JP FAE Atarazana',
          RolMovil.conductor: 'CP FAE Atarazana',
          RolMovil.auxiliar: 'Auxiliar FAE Atarazana',
        },
      ),
    ],
    'PUERTO SANTA ANA': [
      CrtMovilDotacion(
        movil: '106',
        integrantes: {
          RolMovil.jp: 'JP Puerto Santa Ana',
          RolMovil.conductor: 'CP Puerto Santa Ana',
          RolMovil.auxiliar: 'Auxiliar Puerto Santa Ana',
        },
      ),
    ],
    'SAMANES': [
      CrtMovilDotacion(
        movil: '107',
        integrantes: {
          RolMovil.jp: 'JP Samanes',
          RolMovil.conductor: 'CP Samanes',
          RolMovil.auxiliar: 'Auxiliar Samanes',
        },
      ),
    ],
    'PARQUE CENTENARIO': [
      CrtMovilDotacion(
        movil: '108',
        integrantes: {
          RolMovil.jp: 'JP Parque Centenario',
          RolMovil.conductor: 'CP Parque Centenario',
          RolMovil.auxiliar: 'Auxiliar Parque Centenario',
        },
      ),
    ],
    'PLAZA SAN FRANCISCO': [
      CrtMovilDotacion(
        movil: '109',
        integrantes: {
          RolMovil.jp: 'JP Plaza San Francisco',
          RolMovil.conductor: 'CP Plaza San Francisco',
          RolMovil.auxiliar: 'Auxiliar Plaza San Francisco',
        },
      ),
    ],
    'VIA A LA COSTA': [
      CrtMovilDotacion(
        movil: '110',
        integrantes: {
          RolMovil.jp: 'JP Via a la Costa',
          RolMovil.conductor: 'CP Via a la Costa',
          RolMovil.auxiliar: 'Auxiliar Via a la Costa',
        },
      ),
    ],
    'BARRIO CENTENARIO': [
      CrtMovilDotacion(
        movil: '111',
        integrantes: {
          RolMovil.jp: 'JP Barrio Centenario',
          RolMovil.conductor: 'CP Barrio Centenario',
          RolMovil.auxiliar: 'Auxiliar Barrio Centenario',
        },
      ),
    ],
    'CEIBOS': [
      CrtMovilDotacion(
        movil: '187',
        integrantes: {
          RolMovil.jp: 'Juan Perez',
          RolMovil.conductor: 'Carlos Andrade',
          RolMovil.auxiliar: 'Luis Zambrano',
        },
      ),
      CrtMovilDotacion(
        movil: '188',
        integrantes: {
          RolMovil.jp: 'Juan Perez',
          RolMovil.conductor: 'Carlos Andrade',
          RolMovil.auxiliar: 'Luis Zambrano',
        },
      ),
      CrtMovilDotacion(
        movil: '189',
        integrantes: {
          RolMovil.jp: 'Marco Salazar',
          RolMovil.conductor: 'Diego Molina',
          RolMovil.auxiliar: 'Pedro Cedeno',
        },
      ),
    ],
  };

  static List<CrtFieldConfig> fieldsFor(
    TipoModuloCartilla modulo,
    TipoCartilla tipo,
  ) {
    if (modulo != TipoModuloCartilla.eas) return configFor(modulo).fields;

    return [..._easSpecificFields(tipo), ...easBaseFields];
  }

  static List<CrtFieldConfig> _easSpecificFields(TipoCartilla tipo) {
    switch (tipo) {
      case TipoCartilla.desalojoVendedores:
      case TipoCartilla.puntoMartillo:
      case TipoCartilla.rondasDisuasivas:
      case TipoCartilla.retiroTemporal:
      case TipoCartilla.requerimiento:
      case TipoCartilla.colaboracionEventos:
        return const [
          CrtFieldConfig(key: 'direccion', label: 'Dirección'),
          CrtFieldConfig(
            key: 'novedad',
            label: 'Descripción de la novedad',
            required: false,
            minLines: 3,
          ),
        ];
      case TipoCartilla.accidente:
        return const [
          CrtFieldConfig(
            key: 'vehiculos',
            label: 'Vehículos o placas involucradas',
          ),
          CrtFieldConfig(key: 'personas', label: 'Personas involucradas'),
          CrtFieldConfig(
            key: 'casaSalud',
            label: 'Casa de salud',
            required: false,
          ),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Resultado del siniestro',
            minLines: 3,
          ),
        ];
      case TipoCartilla.permisoAusentismo:
        return const [
          CrtFieldConfig(key: 'servidor', label: 'Servidor municipal'),
          CrtFieldConfig(key: 'horaAusentismo', label: 'Hora del permiso'),
          CrtFieldConfig(key: 'motivo', label: 'Tipo o motivo de ausentismo'),
        ];
      case TipoCartilla.colaboracionEntidades:
        return const [
          CrtFieldConfig(key: 'direccion', label: 'Dirección'),
          CrtFieldConfig(
            key: 'novedad',
            label: 'Descripción de la novedad',
            required: false,
            minLines: 3,
          ),
        ];
      case TipoCartilla.operativoConjunto:
      case TipoCartilla.colaboracionAtm:
        return const [
          CrtFieldConfig(key: 'entidad', label: 'Entidad apoyada'),
          CrtFieldConfig(key: 'motivo', label: 'Motivo del apoyo'),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Resultado del procedimiento',
            minLines: 3,
          ),
        ];
      case TipoCartilla.roboManoArmada:
      case TipoCartilla.extorsion:
      case TipoCartilla.amenazas:
      case TipoCartilla.agresion:
      case TipoCartilla.desaparicionPersona:
        return const [
          CrtFieldConfig(
            key: 'persona',
            label: 'Persona involucrada o afectada',
          ),
          CrtFieldConfig(key: 'motivo', label: 'Motivo o alerta recibida'),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Acciones realizadas',
            minLines: 3,
          ),
        ];
      case TipoCartilla.perdidaBienInmueble:
        return const [
          CrtFieldConfig(key: 'bien', label: 'Bien reportado'),
          CrtFieldConfig(key: 'persona', label: 'Persona que reporta'),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Acciones realizadas',
            minLines: 3,
          ),
        ];
      case TipoCartilla.visualizacionCamaras:
        return const [
          CrtFieldConfig(key: 'camara', label: 'Cámara o punto visualizado'),
          CrtFieldConfig(key: 'motivo', label: 'Motivo de revisión'),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Resultado de la visualización',
            minLines: 3,
          ),
        ];
      default:
        return const [
          CrtFieldConfig(
            key: 'motivo',
            label: 'Motivo del procedimiento',
            required: false,
          ),
          CrtFieldConfig(
            key: 'resultado',
            label: 'Resultado o novedad',
            minLines: 3,
          ),
        ];
    }
  }

  static CrtModuleConfig configFor(TipoModuloCartilla modulo) {
    return modules.firstWhere((item) => item.modulo == modulo);
  }

  static Jornada jornadaActual(DateTime now) {
    if (now.hour >= 6 && now.hour < 14) return Jornada.matutina;
    if (now.hour >= 14 && now.hour < 22) return Jornada.vespertina;
    return Jornada.amanecida;
  }

  static String horarioActual(DateTime now) {
    if (now.hour >= 6 && now.hour < 14) return '06:00 A 14:00';
    if (now.hour >= 14 && now.hour < 22) return '14:00 A 22:00';
    return '22:00 A 06:00';
  }
}
