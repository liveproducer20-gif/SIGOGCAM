import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../mdl/crt_special_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class FormacionEntranteRedesign extends StatefulWidget {
  final AppUser? user;
  final String jefeNombre;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const FormacionEntranteRedesign({
    super.key,
    this.user,
    this.jefeNombre = 'Jefe de Control Municipal',
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<FormacionEntranteRedesign> createState() =>
      _FormacionEntranteRedesignState();
}

class _FormacionEntranteRedesignState extends State<FormacionEntranteRedesign> {
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
  TimeOfDay _horaIngreso = TimeOfDay.now();
  final _direccionCtrl = TextEditingController();
  final _acmCtrl = TextEditingController(text: '1');
  final _novedadesCtrl = TextEditingController();

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
    _acmCtrl.dispose();
    _novedadesCtrl.dispose();
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
    final horario =
        '${_horaIngreso.hour.toString().padLeft(2, '0')}:${_horaIngreso.minute.toString().padLeft(2, '0')}';
    final horaSalidaCalc = TimeOfDay(
      hour: (_horaIngreso.hour + 8) % 24,
      minute: (_horaIngreso.minute + 30) % 60,
    );
    final horaSalida =
        '${horaSalidaCalc.hour.toString().padLeft(2, '0')}:${horaSalidaCalc.minute.toString().padLeft(2, '0')}';
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final direccion =
        _direccionCtrl.text.isNotEmpty ? _direccionCtrl.text : '[DIRECCION]';
    final acm = _acmCtrl.text.isNotEmpty ? _acmCtrl.text : '0';
    final saludo = CrtSpecialTextGenerator.saludo(now);

    final String ubicacionLabel;
    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionLabel = '*CIRCUITO:*';
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionLabel = '*CIRCUITO:*';
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final personalLabel = 'entrante';
    final accionLabel = 'cuenta';
    final causaLabel = TipoFormacion.entrante.causa;

    final buf = StringBuffer()
      ..writeln('*CUERPO DE AGENTES DE CONTROL MUNICIPAL*')
      ..writeln()
      ..writeln('*$servicio*')
      ..writeln('*DISTRITO:* $distrito')
      ..writeln('$ubicacionLabel $ubicacionValor')
      ..writeln('*HORARIO:* $horario - $horaSalida')
      ..writeln('*HORA:* $hora')
      ..writeln('*FECHA:* $fecha')
      ..writeln('*DIRECCION:* $direccion')
      ..writeln('*CAUSA:* $causaLabel')
      ..writeln()
      ..writeln('$saludo, permiso Sr. $jefe.')
      ..writeln(
        'Muy respetuosamente, me permito informar que se procedio con la formacion del personal $personalLabel'
        '${_needsEasDropdown ? ' del EAS ${_easSeleccionado?.nombre ?? '[EAS]'}' : ' asignado al circuito ${_circuitoCtrl.text.isNotEmpty ? _circuitoCtrl.text : "[CIRCUITO]"}'},'
        ' en $direccion.',
      )
      ..writeln(
        'Asimismo, se informa que para el cumplimiento de las actividades operativas correspondientes se $accionLabel con el siguiente personal asignado:',
      )
      ..writeln()
      ..writeln('*$acm ACM*');

    final novedades = _novedadesCtrl.text.trim();
    if (novedades.isNotEmpty) {
      buf.writeln();
      buf.writeln(novedades);
    }

    if (_isRadioperador && _videoperadorCtrl.text.isNotEmpty) {
      buf.writeln();
      buf.writeln('*VIDEOPERADOR:* ${_videoperadorCtrl.text}');
    }

    if (_needsEasDropdown && _movilesSeleccionados.isNotEmpty) {
      buf.writeln();
      buf.writeln('*MOVILES EN CIRCULACION:*');
      for (final m in _movilesSeleccionados) {
        buf.writeln('MOVIL $m');
      }
    }

    buf.writeln();
    buf.writeln('Sin mas novedades que informar.');
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
    setState(() {
      _servicio = value;
      _motoCtrl.clear();
      _canCtrl.clear();
      _movilCtrl.clear();
      _bicicletaCtrl.clear();
      _videoperadorCtrl.clear();
      _movilesSeleccionados.clear();
      if (_needsEasDropdown) {
        _circuitoCtrl.clear();
        if (_easSeleccionado != null) _actualizarMovilesEas(_easSeleccionado!);
      }
    });
    _actualizarPreview();
  }

  void _onEasChanged(CrtEasStation? value) {
    if (value == null) return;
    setState(() {
      _easSeleccionado = value;
      _movilesSeleccionados.clear();
      _actualizarMovilesEas(value);
    });
    _actualizarPreview();
  }

  void _actualizarMovilesEas(CrtEasStation eas) {
    final dotacion = CrtCatalog.dotacionEas[eas.nombre];
    _movilesEas = dotacion?.map((d) => d.movil).toList() ?? [];
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

  Future<void> _selectHoraIngreso() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaIngreso,
    );
    if (picked != null) {
      setState(() => _horaIngreso = picked);
      _actualizarPreview();
    }
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _blue,
            letterSpacing: 0.3,
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
            label: 'Número de moto',
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
        if (_easSeleccionado != null && _movilesEas.isNotEmpty) {
          return _buildMovilesCheckboxes();
        }
        return const SizedBox.shrink();
      case 'CICLISTA':
        return TextFormField(
          controller: _bicicletaCtrl,
          decoration: _inputDeco(
            label: 'Número de bicicleta',
            icon: Icons.pedal_bike_outlined,
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      case 'SUPERVISION':
        return TextFormField(
          controller: _movilCtrl,
          decoration: _inputDeco(
            label: 'Número de móvil',
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
                label: 'Videoperador',
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
        label: 'EAS',
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
            'MÓVILES EN CIRCULACIÓN',
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
              Icons.login_outlined,
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
                  'FORMACIÓN ENTRANTE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registre la información de la formación entrante del servicio',
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
          _sectionBadge(1, 'INFORMACIÓN DEL SERVICIO'),
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
                        child: Text('Gestión de Riesgos')),
                    DropdownMenuItem(
                        value: 'SUPERVISION', child: Text('Supervisión')),
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
                        ).copyWith(
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            maxWidth: 32,
                          ),
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

          _buildHoraField(),
          const SizedBox(height: 12),

          TextFormField(
            controller: _direccionCtrl,
            decoration: _inputDeco(
              label: 'Dirección',
              icon: Icons.location_on_outlined,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _acmCtrl,
                  decoration: _inputDeco(
                    label: 'Número de ACM',
                    icon: Icons.people_outlined,
                  ),
                  onChanged: (_) => _actualizarPreview(),
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

          _buildServiceFields(),
          const SizedBox(height: 12),

          TextFormField(
            controller: _novedadesCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDeco(
              label: 'Detalle del personal y/o novedades',
              icon: Icons.notes_outlined,
              hint: 'Describa el personal asignado y/o novedades relevantes...',
            ).copyWith(
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _actualizarPreview(),
          ),
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
          _sectionBadge(2, 'EVIDENCIA FOTOGRÁFICA'),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad disponible próximamente'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _blueLight,
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
                    'AGREGAR FOTOGRAFÍA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _blueMid,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formatos: JPG, PNG (Máx. 5MB)',
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

  Widget _buildHoraField() {
    final horaStr =
        '${_horaIngreso.hour.toString().padLeft(2, '0')}:${_horaIngreso.minute.toString().padLeft(2, '0')}';
    final horaSalidaCalc = TimeOfDay(
      hour: (_horaIngreso.hour + 8) % 24,
      minute: (_horaIngreso.minute + 30) % 60,
    );
    final horaSalidaStr =
        '${horaSalidaCalc.hour.toString().padLeft(2, '0')}:${horaSalidaCalc.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectHoraIngreso,
            child: InputDecorator(
              decoration: _inputDeco(
                label: 'Hora de Ingreso',
                icon: Icons.access_time,
              ),
              child: Text(
                horaStr,
                style: const TextStyle(fontSize: 14, color: _blue),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InputDecorator(
            decoration: _inputDeco(
              label: 'Hora de Salida (auto)',
              icon: Icons.access_time_filled,
            ),
            child: Text(
              horaSalidaStr,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }
}
