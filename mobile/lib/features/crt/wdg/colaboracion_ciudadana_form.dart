import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class ColaboracionCiudadanaForm extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const ColaboracionCiudadanaForm({
    super.key,
    this.user,
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<ColaboracionCiudadanaForm> createState() =>
      _ColaboracionCiudadanaFormState();
}

class _ColaboracionCiudadanaFormState extends State<ColaboracionCiudadanaForm> {
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

  final _nombreCiudadanoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  String _motivo = 'ROBO O HURTO';
  final _otroMotivoCtrl = TextEditingController();
  final _accionCtrl = TextEditingController();
  final _resultadoCtrl = TextEditingController();
  String _estadoFinal = 'SIN NOVEDADES';
  final _novedadCtrl = TextEditingController();

  final _motoCtrl = TextEditingController();
  final _canCtrl = TextEditingController();
  final _movilCtrl = TextEditingController();
  final _bicicletaCtrl = TextEditingController();
  final _videoperadorCtrl = TextEditingController();

  CrtEasStation? _easSeleccionado;
  List<String> _movilesEas = [];
  final Set<String> _movilesSeleccionados = {};

  String _previewText = '';

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
    _nombreCiudadanoCtrl.dispose();
    _cedulaCtrl.dispose();
    _contactoCtrl.dispose();
    _otroMotivoCtrl.dispose();
    _accionCtrl.dispose();
    _resultadoCtrl.dispose();
    _novedadCtrl.dispose();
    _motoCtrl.dispose();
    _canCtrl.dispose();
    _movilCtrl.dispose();
    _bicicletaCtrl.dispose();
    _videoperadorCtrl.dispose();
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
      CrtTextGenerator.jefeNombre =
          ap.isNotEmpty && nm.isNotEmpty ? '$ap $nm' : '';
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
    final direccion =
        _direccionCtrl.text.isNotEmpty ? _direccionCtrl.text : '[DIRECCION]';
    final saludo = CrtSpecialTextGenerator.saludo(now);
    const causa = 'COLABORACION CIUDADANA';

    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final nombreCiudadano = _nombreCiudadanoCtrl.text.trim();
    final cedula = _cedulaCtrl.text.trim();
    final contacto = _contactoCtrl.text.trim();
    final accion = _accionCtrl.text.trim();
    final resultado = _resultadoCtrl.text.trim();
    final novedad = _novedadCtrl.text.trim();

    String motivoTexto;
    if (_motivo == 'OTRO MOTIVO') {
      final otro = _otroMotivoCtrl.text.trim();
      motivoTexto = otro.isNotEmpty ? otro : 'otro motivo';
    } else {
      motivoTexto = _motivo.toLowerCase();
    }

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
        'Muy respetuosamente me permito informar que se procedio a brindar colaboracion ciudadana en el sector de $direccion',
      );

    if (nombreCiudadano.isNotEmpty) {
      String ciudadanoTexto = 'atendiendo el requerimiento realizado por el ciudadano $nombreCiudadano';
      if (cedula.isNotEmpty) {
        ciudadanoTexto += ', portador de la cedula de identidad $cedula';
      }
      if (contacto.isNotEmpty) {
        ciudadanoTexto += ' y numero de contacto $contacto';
      }
      buf.write(', $ciudadanoTexto');
    }

    buf.write(', quien solicito apoyo por motivo de $motivoTexto.');

    if (accion.isNotEmpty) {
      buf.write(
        ' Durante el procedimiento, personal de Agentes de Control Municipal realizo $accion',
      );
      if (resultado.isNotEmpty) {
        buf.write(', permitiendo $resultado');
      }
      buf.write('.');
    }

    if (_estadoFinal == 'SIN NOVEDADES') {
      buf.write(' La colaboracion culmino sin novedades.');
    } else {
      if (novedad.isNotEmpty) {
        buf.write(
          ' La colaboracion culmino con novedades, registrandose $novedad.',
        );
      } else {
        buf.write(' La colaboracion culmino con novedades.');
      }
    }

    if (_isRadioperador && _movilesSeleccionados.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.writeln(
        '*MOVILES EN CIRCULACION:* ${(_movilesSeleccionados.toList()..sort()).join(', ')}',
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
      final asignadas = asignaciones.where((a) {
        final matchEas = a['eas_codigo']?.toString() == eas.codigo;
        final activo = a['activo'] == true;
        return matchEas && activo;
      }).map((a) => a['numero_movil']?.toString() ?? '')
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
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
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
              Icons.handshake_outlined,
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
                  'COLABORACION CIUDADANA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de colaboracion brindada al ciudadano',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (widget.generando)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _blue,
              ),
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
                  decoration: _inputDeco(
                    label: 'Tipo de Servicio',
                    icon: Icons.category_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'PEDESTRE', child: Text('Pedestre')),
                    DropdownMenuItem(
                        value: 'MOTORIZADO', child: Text('Motorizado')),
                    DropdownMenuItem(value: 'K9', child: Text('K9')),
                    DropdownMenuItem(value: 'EAS', child: Text('EAS')),
                    DropdownMenuItem(
                        value: 'TURISMO', child: Text('Turismo')),
                    DropdownMenuItem(
                        value: 'CICLISTA', child: Text('Ciclista')),
                    DropdownMenuItem(
                        value: 'ADMINISTRATIVO',
                        child: Text('Administrativo')),
                    DropdownMenuItem(
                        value: 'AMBIENTE', child: Text('Ambiente')),
                    DropdownMenuItem(
                        value: 'ENCARGADO', child: Text('Encargado')),
                    DropdownMenuItem(
                        value: 'GESTION DE RIESGOS',
                        child: Text('Gestion de Riesgos')),
                    DropdownMenuItem(
                        value: 'SUPERVISION', child: Text('Supervision')),
                    DropdownMenuItem(
                        value: 'RADIOPERADOR', child: Text('Radioperador')),
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
          _sectionBadge(2, 'DATOS DEL CIUDADANO'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nombreCiudadanoCtrl,
            decoration: _inputDeco(
              label: 'Nombre del ciudadano',
              icon: Icons.person_outlined,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cedulaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco(
                    label: 'Numero de cedula',
                    icon: Icons.badge_outlined,
                  ),
                  onChanged: (_) => _actualizarPreview(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _contactoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco(
                    label: 'Numero de contacto',
                    icon: Icons.phone_outlined,
                  ),
                  onChanged: (_) => _actualizarPreview(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionBadge(3, 'DETALLE DE LA COLABORACION'),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _motivo,
            decoration: _inputDeco(
              label: 'Motivo de colaboracion',
              icon: Icons.help_outline,
            ),
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                  value: 'ROBO O HURTO', child: Text('Robo o hurto')),
              DropdownMenuItem(
                  value: 'PERSONA EXTRAVIADA',
                  child: Text('Persona extraviada')),
              DropdownMenuItem(
                  value: 'PERSONA DESORIENTADA',
                  child: Text('Persona desorientada')),
              DropdownMenuItem(
                  value: 'LOCALIZACION DE FAMILIAR',
                  child: Text('Localizacion de familiar')),
              DropdownMenuItem(
                  value: 'ADULTO MAYOR', child: Text('Adulto mayor')),
              DropdownMenuItem(
                  value: 'PERSONA CON DISCAPACIDAD',
                  child: Text('Persona con discapacidad')),
              DropdownMenuItem(
                  value: 'MENOR DE EDAD', child: Text('Menor de edad')),
              DropdownMenuItem(
                  value: 'PERSONA VULNERABLE',
                  child: Text('Persona vulnerable')),
              DropdownMenuItem(
                  value: 'PERSONA EN SITUACION DE CALLE',
                  child: Text('Persona en situacion de calle')),
              DropdownMenuItem(
                  value: 'PERDIDA DE PERTENENCIAS',
                  child: Text('Perdida de pertenencias')),
              DropdownMenuItem(
                  value: 'OBJETO EXTRAVIADO',
                  child: Text('Objeto extraviado')),
              DropdownMenuItem(
                  value: 'CAIDA O ACCIDENTE MENOR',
                  child: Text('Caida o accidente menor')),
              DropdownMenuItem(
                  value: 'PRIMEROS AUXILIOS',
                  child: Text('Primeros auxilios')),
              DropdownMenuItem(
                  value: 'PROBLEMA DE MOVILIDAD',
                  child: Text('Problema de movilidad')),
              DropdownMenuItem(
                  value: 'CONTACTAR A FAMILIARES',
                  child: Text('Contactar a familiares')),
              DropdownMenuItem(
                  value: 'ASISTENCIA A TURISTA',
                  child: Text('Asistencia a turista')),
              DropdownMenuItem(
                  value: 'SITUACION DE RIESGO',
                  child: Text('Situacion de riesgo')),
              DropdownMenuItem(
                  value: 'ACOMPANAMIENTO PREVENTIVO',
                  child: Text('Acompanamiento preventivo')),
              DropdownMenuItem(
                  value: 'TRASLADO A PUNTO SEGURO',
                  child: Text('Traslado a punto seguro')),
              DropdownMenuItem(
                  value: 'VEHICULO AVERIADO',
                  child: Text('Vehiculo averiado')),
              DropdownMenuItem(
                  value: 'CONFLICTO ENTRE CIUDADANOS',
                  child: Text('Conflicto entre ciudadanos')),
              DropdownMenuItem(
                  value: 'CRISIS EMOCIONAL',
                  child: Text('Crisis emocional')),
              DropdownMenuItem(
                  value: 'RECUPERACION DE DOCUMENTOS',
                  child: Text('Recuperacion de documentos')),
              DropdownMenuItem(
                  value: 'SOLICITUD DE AYUDA',
                  child: Text('Solicitud de ayuda')),
              DropdownMenuItem(
                  value: 'OTRO MOTIVO', child: Text('Otro motivo')),
            ],
            onChanged: (v) {
              setState(() => _motivo = v ?? 'ROBO O HURTO');
              _actualizarPreview();
            },
          ),

          if (_motivo == 'OTRO MOTIVO') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _otroMotivoCtrl,
              decoration: _inputDeco(
                label: 'Especifique el motivo',
                icon: Icons.edit_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
          ],

          const SizedBox(height: 12),

          TextFormField(
            controller: _accionCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDeco(
              label: 'Accion realizada',
              icon: Icons.gavel_outlined,
              hint: 'Ej: se realizo la verificacion correspondiente...',
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _resultadoCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDeco(
              label: 'Resultado del procedimiento',
              icon: Icons.check_circle_outline,
              hint: 'Ej: se logro localizar al familiar...',
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
                  value: 'SIN NOVEDADES', child: Text('Sin novedades')),
              DropdownMenuItem(
                  value: 'CON NOVEDADES', child: Text('Con novedades')),
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
          _sectionBadge(4, 'EVIDENCIA FOTOGRAFICA'),
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
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
