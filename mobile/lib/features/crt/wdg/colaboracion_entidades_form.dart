import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class ColaboracionEntidadesForm extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const ColaboracionEntidadesForm({
    super.key,
    this.user,
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<ColaboracionEntidadesForm> createState() =>
      _ColaboracionEntidadesFormState();
}

class _ColaboracionEntidadesFormState extends State<ColaboracionEntidadesForm> {
  final _formKey = GlobalKey<FormState>();
  final _crtApi = CrtApi();

  static const _blue = Color(0xFF1D3F73);
  static const _blueLight = Color(0xFFEBF0F9);
  static const _blueMid = Color(0xFF3B68B9);
  static const _blueBorder = Color(0xFFB8CCE4);
  static const _blueFocus = Color(0xFF2956A3);

  String _servicio = 'PEDESTRE';

  List<Map<String, dynamic>> _distritos = [];
  String? _distritoSeleccionado;
  bool _cargandoDistritos = true;

  final _circuitoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  final _motoCtrl = TextEditingController();
  final _canCtrl = TextEditingController();
  final _movilCtrl = TextEditingController();
  final _bicicletaCtrl = TextEditingController();
  final _videoperadorCtrl = TextEditingController();

  CrtEasStation? _easSeleccionado;
  List<String> _movilesEas = [];
  final Set<String> _movilesSeleccionados = {};

  final Set<String> _entidadesSeleccionadas = {};

  final Map<String, TextEditingController> _nombrePersonalControllers = {};
  final Map<String, TextEditingController> _vehiculoControllers = {};
  final Map<String, TextEditingController> _otraEntidadNombreControllers = {};
  final Map<String, TextEditingController> _otraEntidadMotivoControllers = {};
  final Map<String, Set<String>> _procedimientosSeleccionados = {};

  final List<Map<String, dynamic>> _personasInvolucradas = [];

  final _resultadoCtrl = TextEditingController();
  String _estadoFinal = 'SIN NOVEDADES';
  final _novedadCtrl = TextEditingController();

  String _previewText = '';

  static const Map<String, List<String>> _procedimientosPorEntidad = {
    'POLICIA NACIONAL': [
      'Robo o hurto',
      'Robo o asalto a mano armada',
      'Custodia de bienes',
      'Detencion de presunto delincuente',
      'Persona en actitud sospechosa',
      'Resguardo a ciudadano',
      'Denuncia policial',
      'Persona fallecida en espacio o via publica',
      'Accidente de transito',
      'Rina o alteracion del orden publico',
      'Violencia intrafamiliar',
      'Consumo de sustancias sujetas a fiscalizacion',
      'Tenencia de sustancias sujetas a fiscalizacion',
      'Porte o tenencia de arma',
      'Apoyo en procedimiento policial',
      'Persecucion de presunto infractor',
      'Localizacion de persona requerida',
      'Persona desaparecida o extraviada',
      'Recuperacion de bienes',
      'Recuperacion de vehiculo',
      'Control de personas en espacio publico',
      'Control de aglomeraciones',
      'Desalojo preventivo',
      'Resguardo de escena',
      'Presunto delito en flagrancia',
      'Danos a bienes publicos',
      'Danos a propiedad privada',
      'Amenazas o intimidacion',
      'Escandalo en espacio o via publica',
      'Otro procedimiento policial',
    ],
    'CUERPO DE BOMBEROS': [
      'Orden en espacio y via publica',
      'Accidente de transito',
      'Primeros auxilios',
      'Atencion paramedica',
      'Incendio estructural',
      'Incendio vehicular',
      'Incendio forestal',
      'Conato de incendio',
      'Fuga de gas',
      'Derrame de combustible',
      'Materiales peligrosos',
      'Rescate de persona',
      'Rescate vehicular',
      'Rescate en altura',
      'Persona atrapada',
      'Inundacion',
      'Caida de arbol',
      'Colapso estructural',
      'Inspeccion preventiva',
      'Evacuacion preventiva',
      'Apoyo para habilitacion de perimetro de seguridad',
      'Control de acceso al area de emergencia',
      'Apoyo para despeje de via publica',
      'Emergencia medica',
      'Traslado o asistencia de persona herida',
      'Otro procedimiento de emergencia',
    ],
    'ATM': [
      'Accidente de transito',
      'Siniestro vial con personas heridas',
      'Siniestro vial con persona fallecida',
      'Vehiculo obstaculizando la via publica',
      'Control vehicular',
      'Regulacion del transito',
      'Cierre temporal de via',
      'Desvio vehicular',
      'Vehiculo abandonado',
      'Retiro de vehiculo',
      'Congestionamiento vehicular',
      'Apoyo en evento publico',
      'Control de estacionamiento indebido',
      'Danos a infraestructura vial',
      'Semaforo fuera de servicio',
      'Senalizacion vial afectada',
      'Otro procedimiento de transito',
    ],
    'SEGURA EP': [
      'Coordinacion de emergencia',
      'Activacion de recursos operativos',
      'Videovigilancia',
      'Seguimiento mediante camaras',
      'Reporte de incidente',
      'Solicitud de apoyo interinstitucional',
      'Coordinacion de unidades en territorio',
      'Alerta ciudadana',
      'Localizacion de persona mediante camaras',
      'Seguimiento de vehiculo',
      'Apoyo en procedimiento operativo',
      'Verificacion de novedad',
      'Otro procedimiento de coordinacion',
    ],
    'DIRECCION DE JUSTICIA Y VIGILANCIA': [
      'Control de comercio no regularizado',
      'Uso indebido del espacio publico',
      'Ocupacion no autorizada de via publica',
      'Retiro temporal',
      'Verificacion de permisos',
      'Control de publicidad no autorizada',
      'Retiro de estructuras no autorizadas',
      'Inspeccion de establecimiento',
      'Notificacion administrativa',
      'Incumplimiento de ordenanza municipal',
      'Otro procedimiento administrativo',
    ],
    'GESTION DE RIESGOS': [
      'Evaluacion de zona de riesgo',
      'Inundacion',
      'Deslizamiento',
      'Colapso estructural',
      'Arbol en riesgo de caida',
      'Vivienda en situacion de riesgo',
      'Evacuacion preventiva',
      'Inspeccion tecnica',
      'Evento natural',
      'Danos por lluvias',
      'Afectacion de infraestructura',
      'Cierre preventivo de area',
      'Delimitacion de zona de riesgo',
      'Apoyo a personas afectadas',
      'Otro procedimiento de gestion de riesgos',
    ],
    'MINISTERIO DE SALUD': [
      'Primeros auxilios',
      'Persona inconsciente',
      'Persona herida',
      'Emergencia medica',
      'Persona con aparente alteracion mental',
      'Crisis de salud',
      'Intoxicacion',
      'Control sanitario',
      'Inspeccion sanitaria',
      'Otro procedimiento de salud',
    ],
    'FUERZAS ARMADAS': [
      'Control de seguridad',
      'Control de armas',
      'Control de personas',
      'Operativo interinstitucional',
      'Resguardo de instalaciones',
      'Resguardo de bienes estrategicos',
      'Control territorial',
      'Apoyo en estado de excepcion',
      'Control de accesos',
      'Registro preventivo',
      'Apoyo en emergencia',
      'Otro procedimiento militar',
    ],
  };

  @override
  void initState() {
    super.initState();
    _cargarDistritos();
    _cargarJefe();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actualizarPreview();
    });
  }

  @override
  void dispose() {
    _circuitoCtrl.dispose();
    _direccionCtrl.dispose();
    _motoCtrl.dispose();
    _canCtrl.dispose();
    _movilCtrl.dispose();
    _bicicletaCtrl.dispose();
    _videoperadorCtrl.dispose();
    _resultadoCtrl.dispose();
    _novedadCtrl.dispose();
    for (final c in _nombrePersonalControllers.values) {
      c.dispose();
    }
    for (final c in _vehiculoControllers.values) {
      c.dispose();
    }
    for (final c in _otraEntidadNombreControllers.values) {
      c.dispose();
    }
    for (final c in _otraEntidadMotivoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDistritos() async {
    try {
      final distritos = await _crtApi.getDistritos();
      if (mounted) {
        setState(() {
          _distritos = distritos;
          _cargandoDistritos = false;
          if (_distritos.isNotEmpty) {
            _distritoSeleccionado = _distritos.first['nombre'] as String?;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _actualizarPreview();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoDistritos = false);
    }
  }

  Future<void> _cargarJefe() async {
    try {
      final jefe = await _crtApi.getJefeControlMunicipal();
      if (!mounted) return;
      final ap = (jefe?['apellidos'] as String? ?? '').trim();
      final nm = (jefe?['nombres'] as String? ?? '').trim();
      CrtTextGenerator.jefeNombre = ap.isNotEmpty && nm.isNotEmpty
          ? '$ap $nm'
          : '';
    } catch (_) {
      CrtTextGenerator.jefeNombre = '';
    }
  }

  bool get _isEas => _servicio == 'EAS';
  bool get _isRadioperador => _servicio == 'RADIOPERADOR';
  bool get _needsEasDropdown => _isEas || _isRadioperador;

  String _servicioTitle(String servicio) {
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
      'GESTION DE RIESGOS': 'REPORTE DE GESTION DE RIESGOS',
      'SUPERVISION': 'REPORTE DE SUPERVISION',
      'RADIOPERADOR': 'REPORTE DE RADIOOPERADOR',
    };
    return titles[servicio] ?? 'REPORTE DE $servicio';
  }

  void _toggleEntidad(String entidad) {
    setState(() {
      if (_entidadesSeleccionadas.contains(entidad)) {
        _entidadesSeleccionadas.remove(entidad);
        _nombrePersonalControllers[entidad]?.clear();
        _vehiculoControllers[entidad]?.clear();
        _procedimientosSeleccionados[entidad]?.clear();
        _otraEntidadNombreControllers[entidad]?.clear();
        _otraEntidadMotivoControllers[entidad]?.clear();
      } else {
        _entidadesSeleccionadas.add(entidad);
        _nombrePersonalControllers[entidad] ??= TextEditingController();
        _vehiculoControllers[entidad] ??= TextEditingController();
        _procedimientosSeleccionados[entidad] ??= {};
        if (entidad == 'OTRA ENTIDAD') {
          _otraEntidadNombreControllers[entidad] ??= TextEditingController();
          _otraEntidadMotivoControllers[entidad] ??= TextEditingController();
        }
      }
    });
    _actualizarPreview();
  }

  void _toggleProcedimiento(String entidad, String procedimiento) {
    setState(() {
      final set = _procedimientosSeleccionados[entidad];
      if (set == null) return;
      if (set.contains(procedimiento)) {
        set.remove(procedimiento);
      } else {
        set.add(procedimiento);
      }
    });
    _actualizarPreview();
  }

  void _agregarPersona() {
    setState(() {
      _personasInvolucradas.add({
        'nombreCtrl': TextEditingController(),
        'condicion': 'Persona sospechosa',
        'detalleCtrl': TextEditingController(),
        'accionCtrl': TextEditingController(),
        'trasladado': false,
        'casaSaludCtrl': TextEditingController(),
      });
    });
  }

  void _eliminarPersona(int index) {
    final p = _personasInvolucradas[index];
    (p['nombreCtrl'] as TextEditingController).dispose();
    (p['detalleCtrl'] as TextEditingController).dispose();
    (p['accionCtrl'] as TextEditingController).dispose();
    (p['casaSaludCtrl'] as TextEditingController).dispose();
    setState(() => _personasInvolucradas.removeAt(index));
    _actualizarPreview();
  }

  String _obtenerProcedimientosNarrativo() {
    final todos = <String>[];
    for (final entidad in _entidadesSeleccionadas) {
      if (entidad == 'OTRA ENTIDAD') continue;
      final procs = _procedimientosSeleccionados[entidad];
      if (procs != null && procs.isNotEmpty) {
        todos.addAll(procs);
      }
    }
    if (todos.isEmpty) return '';
    if (todos.length == 1) return todos.first.toLowerCase();
    if (todos.length == 2) {
      return '${todos.first.toLowerCase()} y ${todos.last.toLowerCase()}';
    }
    final resto = todos
        .sublist(0, todos.length - 1)
        .map((e) => e.toLowerCase())
        .join(', ');
    return '$resto y ${todos.last.toLowerCase()}';
  }

  String _obtenerEntidadesNarrativo() {
    final partes = <String>[];
    for (final entidad in _entidadesSeleccionadas) {
      if (entidad == 'OTRA ENTIDAD') {
        final nombreEntidad = _otraEntidadNombreControllers[entidad]?.text
            .trim();
        final motivo = _otraEntidadMotivoControllers[entidad]?.text.trim();
        if (nombreEntidad != null && nombreEntidad.isNotEmpty) {
          String parte = nombreEntidad;
          if (motivo != null && motivo.isNotEmpty) {
            parte += ', $motivo';
          }
          partes.add(parte);
        }
        continue;
      }
      final nombre = _nombrePersonalControllers[entidad]?.text.trim() ?? '';
      final vehiculo = _vehiculoControllers[entidad]?.text.trim() ?? '';
      if (nombre.isNotEmpty) {
        String parte = 'personal de $entidad, $nombre';
        if (vehiculo.isNotEmpty) {
          parte += ', movilizado en $vehiculo';
        }
        partes.add(parte);
      }
    }
    if (partes.isEmpty) return '';
    if (partes.length == 1) {
      return 'contando con la presencia de ${partes.first}';
    }
    if (partes.length == 2) {
      return 'contando con la presencia de ${partes.first} y ${partes.last}';
    }
    final ultimo = partes.last;
    final resto = partes.sublist(0, partes.length - 1).join('; ');
    return 'contando con la presencia de $resto; y $ultimo';
  }

  String _obtenerPersonasNarrativo() {
    final partes = <String>[];
    for (final persona in _personasInvolucradas) {
      final nombre = (persona['nombreCtrl'] as TextEditingController).text
          .trim();
      final condicion = persona['condicion'] as String? ?? '';
      final detalle = (persona['detalleCtrl'] as TextEditingController).text
          .trim();
      final accion = (persona['accionCtrl'] as TextEditingController).text
          .trim();
      final trasladado = persona['trasladado'] as bool? ?? false;
      final casaSalud = (persona['casaSaludCtrl'] as TextEditingController).text
          .trim();

      if (nombre.isEmpty && condicion.isEmpty) continue;

      String parte = '';
      final nombreUsado = nombre.isNotEmpty ? nombre : 'una persona';
      if (nombre.isNotEmpty) {
        parte = 'al ciudadano $nombreUsado';
      } else {
        parte = 'a una persona';
      }

      if (condicion.isNotEmpty) {
        parte +=
            ', quien result${nombre.isNotEmpty ? 'o' : 'a'} ${condicion.toLowerCase()}';
      }
      if (detalle.isNotEmpty) {
        parte += ' y presentaba $detalle';
      }
      if (accion.isNotEmpty) {
        parte += '; $accion';
      }
      if (trasladado && casaSalud.isNotEmpty) {
        parte +=
            ' y posteriormente trasladado al $casaSalud para recibir atencion medica';
      }
      partes.add(parte);
    }
    if (partes.isEmpty) return '';
    if (partes.length == 1) {
      return 'Durante el procedimiento se identifico ${partes.first}.';
    }
    final primera = partes.first;
    final resto = partes
        .sublist(1)
        .map((p) => 'Asimismo, se identifico $p')
        .join('. ');
    return 'Durante el procedimiento se identifico $primera. $resto.';
  }

  void _actualizarPreview() {
    final now = DateTime.now();
    final jefe = CrtTextGenerator.jefeDisplay;
    final reporta = widget.user?.nombreCompleto ?? 'ACM';
    final distrito = _distritoSeleccionado ?? '';
    final servicio = _servicioTitle(_servicio);
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final direccion = _direccionCtrl.text.isNotEmpty
        ? _direccionCtrl.text
        : '[DIRECCION]';
    final saludo = CrtSpecialTextGenerator.saludo(now);
    const causa = 'COLABORACION CON OTRAS ENTIDADES';

    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final entidadesNarrativo = _obtenerEntidadesNarrativo();
    final procedimientos = _obtenerProcedimientosNarrativo();
    final personasNarrativo = _obtenerPersonasNarrativo();
    final resultado = _resultadoCtrl.text.trim();
    final novedad = _novedadCtrl.text.trim();

    final buf = StringBuffer()
      ..writeln('*CUERPO DE AGENTES DE CONTROL MUNICIPAL*')
      ..writeln()
      ..writeln('*$servicio*')
      ..writeln('*DISTRITO:* $distrito')
      ..writeln('*CIRCUITO:* $ubicacionValor')
      ..writeln('*HORA:* $hora')
      ..writeln('*FECHA:* $fecha')
      ..writeln('*DIRECCION:* $direccion')
      ..writeln('*CAUSA:* $causa')
      ..writeln()
      ..writeln('$saludo, permiso Sr. $jefe Jefe de Control Municipal.')
      ..writeln()
      ..write(
        'Muy respetuosamente me permito informar que se procedio a brindar colaboracion interinstitucional en el sector de $direccion',
      );

    if (entidadesNarrativo.isNotEmpty) {
      buf.write(', $entidadesNarrativo');
    }
    buf.write('.');

    if (procedimientos.isNotEmpty) {
      buf.write(' La intervencion se realizo debido a $procedimientos.');
    }

    if (personasNarrativo.isNotEmpty) {
      buf.write(' $personasNarrativo');
    }

    if (resultado.isNotEmpty) {
      buf.write(
        ' Las instituciones participantes realizaron las acciones correspondientes de manera coordinada, $resultado',
      );
    } else {
      buf.write(
        ' Las instituciones participantes realizaron las acciones correspondientes de manera coordinada',
      );
    }

    if (_estadoFinal == 'SIN NOVEDADES') {
      buf.write(', manteniendo el orden y la seguridad en el sector');
      buf.write('. La colaboracion culmino sin novedades.');
    } else {
      buf.write(', manteniendo el orden y la seguridad en el sector');
      if (novedad.isNotEmpty) {
        buf.write(
          '. La colaboracion culmino con novedades, registrandose $novedad.',
        );
      } else {
        buf.write('. La colaboracion culmino con novedades.');
      }
    }

    if (_isRadioperador && _movilesSeleccionados.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln(
        '*MOVILES EN CIRCULACION:* ${_movilesSeleccionados.toList()..sort((a, b) => a.compareTo(b))}',
      );
    }

    buf.writeln();
    buf.writeln();
    buf.writeln('*REPORTA:*');
    buf.writeln('ACM. $reporta');

    switch (_servicio) {
      case 'MOTORIZADO':
        if (_motoCtrl.text.isNotEmpty) {
          buf.writeln('*MOTO:* ${_motoCtrl.text}');
        }
      case 'K9':
        if (_canCtrl.text.isNotEmpty) {
          buf.writeln('*CAN:* ${_canCtrl.text}');
        }
      case 'EAS':
        if (_movilCtrl.text.isNotEmpty) {
          buf.writeln('*MOVIL:* ${_movilCtrl.text}');
        }
      case 'CICLISTA':
        if (_bicicletaCtrl.text.isNotEmpty) {
          buf.writeln('*BICICLETA:* ${_bicicletaCtrl.text}');
        }
      case 'SUPERVISION':
        if (_movilCtrl.text.isNotEmpty) {
          buf.writeln('*MOVIL:* ${_movilCtrl.text}');
        }
      case 'RADIOPERADOR':
        if (_videoperadorCtrl.text.isNotEmpty) {
          buf.writeln('*VIDEOPERADOR:* ${_videoperadorCtrl.text}');
        }
    }

    buf.writeln();
    buf.writeln('"LEALTAD, VALOR Y ORDEN"');
    buf.writeln();
    buf.writeln('*ADJUNTO FOTOGRAFIA:*');

    _previewText = buf.toString();
    widget.onPreviewChanged?.call(_previewText);
  }

  void _onServicioChanged(String? value) {
    if (value == null) return;
    final prevNeedsEas = _needsEasDropdown;
    setState(() {
      _servicio = value;
      _motoCtrl.clear();
      _canCtrl.clear();
      _movilCtrl.clear();
      _bicicletaCtrl.clear();
      _videoperadorCtrl.clear();
      _movilesSeleccionados.clear();
      _movilesEas = [];
      if (prevNeedsEas && !_needsEasDropdown) {
        _easSeleccionado = null;
        _circuitoCtrl.clear();
      }
    });
    if (_needsEasDropdown && _easSeleccionado != null) {
      _actualizarMovilesEas(_easSeleccionado!);
    }
    _actualizarPreview();
  }

  void _onEasChanged(CrtEasStation? value) {
    if (value == null) return;
    setState(() {
      _easSeleccionado = value;
      _movilesSeleccionados.clear();
      _movilesEas = [];
    });
    _actualizarMovilesEas(value);
    _actualizarPreview();
  }

  Future<void> _actualizarMovilesEas(CrtEasStation eas) async {
    try {
      final asignaciones = await _crtApi.getAsignacionesMoviles();
      final asignadas = asignaciones
          .where((a) {
            final matchEas = a['eas_codigo']?.toString() == eas.codigo;
            final activo = a['activo'] == true;
            return matchEas && activo;
          })
          .map((a) => a['numero_movil']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() => _movilesEas = asignadas);
      }
    } catch (_) {
      if (mounted) setState(() => _movilesEas = []);
    }
  }

  void _toggleMovil(String movil) {
    setState(() {
      if (_movilesSeleccionados.contains(movil)) {
        _movilesSeleccionados.remove(movil);
      } else {
        _movilesSeleccionados.add(movil);
      }
    });
    _actualizarPreview();
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: _blueMid),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: _blueMid, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blueBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blueBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blueFocus, width: 1.5),
      ),
    );
  }

  Widget _sectionBadge(int number, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFields() {
    switch (_servicio) {
      case 'MOTORIZADO':
        return TextFormField(
          controller: _motoCtrl,
          decoration: _inputDeco(
            label: 'Numero de moto',
            icon: Icons.two_wheeler_outlined,
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      case 'K9':
        return TextFormField(
          controller: _canCtrl,
          decoration: _inputDeco(
            label: 'Nombre del Can',
            icon: Icons.pets_outlined,
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      case 'EAS':
        return Column(
          children: [
            TextFormField(
              controller: _movilCtrl,
              decoration: _inputDeco(
                label: 'Numero de movil',
                icon: Icons.directions_car_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
            if (_easSeleccionado != null && _movilesEas.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMovilesCheckboxes(),
            ],
          ],
        );
      case 'CICLISTA':
        return TextFormField(
          controller: _bicicletaCtrl,
          decoration: _inputDeco(
            label: 'Numero de bicicleta',
            icon: Icons.pedal_bike_outlined,
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      case 'SUPERVISION':
        return TextFormField(
          controller: _movilCtrl,
          decoration: _inputDeco(
            label: 'Numero de movil',
            icon: Icons.directions_car_outlined,
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      case 'RADIOPERADOR':
        return Column(
          children: [
            if (_easSeleccionado != null && _movilesEas.isNotEmpty) ...[
              _buildMovilesCheckboxes(),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _videoperadorCtrl,
              decoration: _inputDeco(
                label: 'Nombre del videoperador',
                icon: Icons.videocam_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEasDropdown() {
    return DropdownButtonFormField<CrtEasStation>(
      initialValue: _easSeleccionado,
      isExpanded: true,
      decoration: _inputDeco(
        label: 'Circuito / EAS',
        icon: Icons.location_city_outlined,
      ),
      items: CrtCatalog.easStations
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                '${e.codigo} - ${e.nombre}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _onEasChanged,
    );
  }

  Widget _buildMovilesCheckboxes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MOVILES EN CIRCULACION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _movilesEas.map((movil) {
              final selected = _movilesSeleccionados.contains(movil);
              return FilterChip(
                label: Text(
                  'MOVIL $movil',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? _blue : Colors.grey[700],
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: selected,
                onSelected: (_) => _toggleMovil(movil),
                selectedColor: _blueLight,
                side: BorderSide(
                  color: selected ? _blueMid : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntidadBlock(String entidad) {
    final esOtraEntidad = entidad == 'OTRA ENTIDAD';
    final procedimientos = _procedimientosPorEntidad[entidad] ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entidad,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _blue,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          if (esOtraEntidad) ...[
            TextFormField(
              controller: _otraEntidadNombreControllers[entidad],
              decoration: _inputDeco(
                label: 'Nombre de la entidad',
                icon: Icons.business_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _nombrePersonalControllers[entidad],
            decoration: _inputDeco(
              label: 'Nombre del personal',
              icon: Icons.person_outlined,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 8),
          if (!esOtraEntidad) ...[
            TextFormField(
              controller: _vehiculoControllers[entidad],
              decoration: _inputDeco(
                label: 'Vehiculo / Unidad',
                icon: Icons.directions_car_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],
          if (esOtraEntidad) ...[
            TextFormField(
              controller: _vehiculoControllers[entidad],
              decoration: _inputDeco(
                label: 'Vehiculo / Unidad',
                icon: Icons.directions_car_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otraEntidadMotivoControllers[entidad],
              minLines: 2,
              maxLines: 3,
              decoration: _inputDeco(
                label: 'Motivo / procedimiento',
                icon: Icons.description_outlined,
              ).copyWith(alignLabelWithHint: true),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],
          if (procedimientos.isNotEmpty && !esOtraEntidad) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: procedimientos.map((proc) {
                final selected =
                    _procedimientosSeleccionados[entidad]?.contains(proc) ??
                    false;
                return FilterChip(
                  label: Text(
                    proc,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? _blue : Colors.grey[700],
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => _toggleProcedimiento(entidad, proc),
                  selectedColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _blueMid : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaBlock(int index) {
    final persona = _personasInvolucradas[index];
    final trasladado = persona['trasladado'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Persona ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _eliminarPersona(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: persona['nombreCtrl'] as TextEditingController,
            decoration: _inputDeco(
              label: 'Nombre completo',
              icon: Icons.person_outlined,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: persona['condicion'] as String?,
            decoration: _inputDeco(
              label: 'Condicion / relacion',
              icon: Icons.assignment_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Persona sospechosa',
                child: Text('Persona sospechosa'),
              ),
              DropdownMenuItem(
                value: 'Presunto delincuente',
                child: Text('Presunto delincuente'),
              ),
              DropdownMenuItem(value: 'Victima', child: Text('Victima')),
              DropdownMenuItem(
                value: 'Persona herida',
                child: Text('Persona herida'),
              ),
              DropdownMenuItem(
                value: 'Persona inconsciente',
                child: Text('Persona inconsciente'),
              ),
              DropdownMenuItem(value: 'Conductor', child: Text('Conductor')),
              DropdownMenuItem(value: 'Peaton', child: Text('Peaton')),
              DropdownMenuItem(
                value: 'Ciudadano resguardado',
                child: Text('Ciudadano resguardado'),
              ),
              DropdownMenuItem(
                value: 'Persona fallecida',
                child: Text('Persona fallecida'),
              ),
              DropdownMenuItem(value: 'Testigo', child: Text('Testigo')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => persona['condicion'] = v);
                _actualizarPreview();
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: persona['detalleCtrl'] as TextEditingController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDeco(
              label: 'Detalle del estado o novedad',
              icon: Icons.notes_outlined,
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: persona['accionCtrl'] as TextEditingController,
            minLines: 2,
            maxLines: 3,
            decoration: _inputDeco(
              label: 'Accion realizada',
              icon: Icons.gavel_outlined,
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: trasladado,
            onChanged: (v) {
              setState(() => persona['trasladado'] = v ?? false);
              _actualizarPreview();
            },
            title: const Text(
              'Fue trasladado a una casa de salud?',
              style: TextStyle(fontSize: 13),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: _blueMid,
          ),
          if (trasladado) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: persona['casaSaludCtrl'] as TextEditingController,
              decoration: _inputDeco(
                label: 'Casa de salud',
                icon: Icons.local_hospital_outlined,
                hint: 'Ej: Hospital de Los Ceibos',
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSection1(),
            const SizedBox(height: 16),
            _buildSection2(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blueBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COLABORACION CON OTRAS ENTIDADES',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de colaboracion interinstitucional',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (widget.generando)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
            ),
        ],
      ),
    );
  }

  Widget _buildSection1() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blueBorder),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionBadge(1, 'INFORMACION DEL SERVICIO'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _servicio,
                  isExpanded: true,
                  decoration: _inputDeco(
                    label: 'Tipo de Servicio',
                    icon: Icons.category_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PEDESTRE',
                      child: Text('Pedestre'),
                    ),
                    DropdownMenuItem(
                      value: 'MOTORIZADO',
                      child: Text('Motorizado'),
                    ),
                    DropdownMenuItem(value: 'K9', child: Text('K9')),
                    DropdownMenuItem(value: 'EAS', child: Text('EAS')),
                    DropdownMenuItem(value: 'TURISMO', child: Text('Turismo')),
                    DropdownMenuItem(
                      value: 'CICLISTA',
                      child: Text('Ciclista'),
                    ),
                    DropdownMenuItem(
                      value: 'ADMINISTRATIVO',
                      child: Text('Administrativo'),
                    ),
                    DropdownMenuItem(
                      value: 'AMBIENTE',
                      child: Text('Ambiente'),
                    ),
                    DropdownMenuItem(
                      value: 'ENCARGADO',
                      child: Text('Encargado'),
                    ),
                    DropdownMenuItem(
                      value: 'GESTION DE RIESGOS',
                      child: Text('Gestion de Riesgos'),
                    ),
                    DropdownMenuItem(
                      value: 'SUPERVISION',
                      child: Text('Supervision'),
                    ),
                    DropdownMenuItem(
                      value: 'RADIOPERADOR',
                      child: Text('Radioperador'),
                    ),
                  ],
                  onChanged: _onServicioChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cargandoDistritos
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        initialValue: _distritoSeleccionado,
                        decoration: _inputDeco(
                          label: 'Distrito',
                          icon: Icons.map_outlined,
                        ),
                        isExpanded: true,
                        items: _distritos
                            .map(
                              (d) => DropdownMenuItem(
                                value: d['nombre'] as String?,
                                child: Text(
                                  d['nombre'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _distritoSeleccionado = v);
                          _actualizarPreview();
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_needsEasDropdown) ...[
            _buildEasDropdown(),
            const SizedBox(height: 12),
          ],

          if (!_needsEasDropdown) ...[
            TextFormField(
              controller: _circuitoCtrl,
              decoration: _inputDeco(
                label: 'Circuito',
                icon: Icons.route_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _direccionCtrl,
            decoration: _inputDeco(
              label: 'Direccion',
              icon: Icons.location_on_outlined,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 12),

          _buildServiceFields(),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blueBorder),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionBadge(2, 'ENTIDADES PARTICIPANTES'),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                [
                  'POLICIA NACIONAL',
                  'CUERPO DE BOMBEROS',
                  'ATM',
                  'SEGURA EP',
                  'DIRECCION DE JUSTICIA Y VIGILANCIA',
                  'GESTION DE RIESGOS',
                  'MINISTERIO DE SALUD',
                  'FUERZAS ARMADAS',
                  'OTRA ENTIDAD',
                ].map((entidad) {
                  final selected = _entidadesSeleccionadas.contains(entidad);
                  return FilterChip(
                    label: Text(
                      entidad,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? _blue : Colors.grey[700],
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => _toggleEntidad(entidad),
                    selectedColor: _blueLight,
                    side: BorderSide(
                      color: selected ? _blueMid : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
          ),

          for (final entidad in _entidadesSeleccionadas)
            _buildEntidadBlock(entidad),

          const SizedBox(height: 16),
          _sectionBadge(3, 'PERSONAS INVOLUCRADAS'),
          const SizedBox(height: 10),

          for (int i = 0; i < _personasInvolucradas.length; i++)
            _buildPersonaBlock(i),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _agregarPersona,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Agregar persona involucrada'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _blueMid,
              side: const BorderSide(color: _blueMid),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionBadge(4, 'RESULTADO Y ESTADO'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _resultadoCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDeco(
              label: 'Resultado del procedimiento',
              icon: Icons.check_circle_outline,
              hint: 'Ej: se logro controlar la situacion...',
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _estadoFinal,
            decoration: _inputDeco(
              label: 'Estado final',
              icon: Icons.flag_outlined,
            ),
            items: const [
              DropdownMenuItem(
                value: 'SIN NOVEDADES',
                child: Text('Sin novedades'),
              ),
              DropdownMenuItem(
                value: 'CON NOVEDADES',
                child: Text('Con novedades'),
              ),
            ],
            onChanged: (v) {
              setState(() => _estadoFinal = v ?? 'SIN NOVEDADES');
              _actualizarPreview();
            },
          ),

          if (_estadoFinal == 'CON NOVEDADES') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _novedadCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: _inputDeco(
                label: 'Detalle de la novedad',
                icon: Icons.warning_amber_outlined,
              ).copyWith(alignLabelWithHint: true),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],

          const SizedBox(height: 16),
          _buildSection3(),
        ],
      ),
    );
  }

  Widget _buildSection3() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionBadge(5, 'EVIDENCIA FOTOGRAFICA'),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad disponible proximamente'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _blueMid,
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: _blueMid,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AGREGAR FOTOGRAFIA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _blueMid,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formatos: JPG, PNG (Max. 5MB)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
