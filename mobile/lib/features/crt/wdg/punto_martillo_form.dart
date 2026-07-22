import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class PuntoMartilloForm extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const PuntoMartilloForm({
    super.key,
    this.user,
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<PuntoMartilloForm> createState() => _PuntoMartilloFormState();
}

class _PuntoMartilloFormState extends State<PuntoMartilloForm> {
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

  List<CrtEasStation> _easFromApi = [];

  final _circuitoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
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
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _cargarDistritos();
    _cargarJefe();
    _cargarEas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actualizarPreview();
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _circuitoCtrl.dispose();
    _direccionCtrl.dispose();
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
      CrtTextGenerator.jefeNombre = ap.isNotEmpty && nm.isNotEmpty
          ? '$ap $nm'
          : '';
    } catch (_) {
      CrtTextGenerator.jefeNombre = '';
    }
  }

  Future<void> _cargarEas() async {
    try {
      final easList = await _crtApi.getEasStations();
      if (mounted) {
        setState(() {
          _easFromApi = easList
              .where((e) => e['activo'] == true)
              .map(
                (e) => CrtEasStation(
                  codigo: e['codigo']?.toString() ?? '',
                  nombre: e['nombre']?.toString() ?? '',
                  direccion: e['direccion']?.toString() ?? '',
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
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

  void _schedulePreviewUpdate() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _actualizarPreview();
    });
  }

  void _actualizarPreview() {
    final now = DateTime.now();
    final jefe = CrtTextGenerator.jefeDisplay;
    final reporta = widget.user?.nombreCompleto ?? 'ACM';
    final distrito = _distritoSeleccionado ?? '';
    final servicio = _servicioTitle(_servicio);
    final horario =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final horaSalidaCalc = TimeOfDay(
      hour: (now.hour + 8) % 24,
      minute: (now.minute + 30) % 60,
    );
    final horaSalida =
        '${horaSalidaCalc.hour.toString().padLeft(2, '0')}:${horaSalidaCalc.minute.toString().padLeft(2, '0')}';
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final direccion = _direccionCtrl.text.isNotEmpty
        ? _direccionCtrl.text
        : '[DIRECCION]';
    final saludo = CrtSpecialTextGenerator.saludo(now);
    const causa = 'PUNTO MARTILLO';

    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final buf = StringBuffer()
      ..writeln('*CUERPO DE AGENTES DE CONTROL MUNICIPAL*')
      ..writeln()
      ..writeln('*$servicio*')
      ..writeln('*DISTRITO:* $distrito')
      ..writeln('*CIRCUITO:* $ubicacionValor')
      ..writeln('*HORARIO:* $horario - $horaSalida')
      ..writeln('*HORA:* $hora')
      ..writeln('*FECHA:* $fecha')
      ..writeln('*DIRECCION:* $direccion')
      ..writeln('*CAUSA:* $causa')
      ..writeln()
      ..writeln('$saludo, permiso Sr. $jefe.')
      ..writeln(
        'Muy respetuosamente me permito informar que se procedio con punto martillo en la calle $direccion, con la finalidad de mantener presencia preventiva y efectuar el control correspondiente en el sector.',
      )
      ..writeln(
        'Durante el procedimiento se realizaron recorridos y permanencia en el punto establecido, manteniendo presencia de los Agentes de Control Municipal.',
      );

    final novedades = _novedadesCtrl.text.trim();
    if (novedades.isNotEmpty) {
      buf.writeln();
      buf.writeln(novedades);
    }

    if (_isRadioperador && _movilesSeleccionados.isNotEmpty) {
      buf.writeln();
      buf.writeln('*MOVILES EN CIRCULACION:*');
      final sorted = _movilesSeleccionados.toList()..sort();
      for (final m in sorted) {
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
      final codigoLower = eas.codigo.toLowerCase();
      final nombreLower = eas.nombre.toLowerCase();
      final asignadas = asignaciones
          .where((a) {
            final easCodigo = a['eas_codigo']?.toString().toLowerCase() ?? '';
            final easNombre = a['eas']?.toString().toLowerCase() ?? '';
            return easCodigo == codigoLower || easNombre == nombreLower;
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
            label: 'Número de moto',
            icon: Icons.two_wheeler_outlined,
          ),
          onChanged: (_) => _schedulePreviewUpdate(),
        );
      case 'K9':
        return TextFormField(
          controller: _canCtrl,
          decoration: _inputDeco(
            label: 'Nombre del Can',
            icon: Icons.pets_outlined,
          ),
          onChanged: (_) => _schedulePreviewUpdate(),
        );
      case 'EAS':
        return Column(
          children: [
            TextFormField(
              controller: _movilCtrl,
              decoration: _inputDeco(
                label: 'Número de móvil',
                icon: Icons.directions_car_outlined,
              ),
              onChanged: (_) => _schedulePreviewUpdate(),
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
            label: 'Número de bicicleta',
            icon: Icons.pedal_bike_outlined,
          ),
          onChanged: (_) => _schedulePreviewUpdate(),
        );
      case 'SUPERVISION':
        return TextFormField(
          controller: _movilCtrl,
          decoration: _inputDeco(
            label: 'Número de móvil',
            icon: Icons.directions_car_outlined,
          ),
          onChanged: (_) => _schedulePreviewUpdate(),
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
              onChanged: (_) => _schedulePreviewUpdate(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEasDropdown() {
    final easList = _easFromApi.isNotEmpty
        ? _easFromApi
        : CrtCatalog.easStations;
    return DropdownButtonFormField<CrtEasStation>(
      initialValue: _easSeleccionado,
      isExpanded: true,
      decoration: _inputDeco(
        label: 'Circuito / EAS',
        icon: Icons.location_city_outlined,
      ),
      items: easList
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
                  movil,
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
              Icons.gavel_outlined,
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
                  'PUNTO MARTILLO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de punto martillo del servicio',
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
          _sectionBadge(1, 'INFORMACIÓN DEL SERVICIO'),
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
                      child: Text('Gestión de Riesgos'),
                    ),
                    DropdownMenuItem(
                      value: 'SUPERVISION',
                      child: Text('Supervisión'),
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
                        decoration:
                            _inputDeco(
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

          TextFormField(
            controller: _direccionCtrl,
            decoration: _inputDeco(
              label: 'Dirección',
              icon: Icons.location_on_outlined,
            ),
            onChanged: (_) => _schedulePreviewUpdate(),
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
              onChanged: (_) => _schedulePreviewUpdate(),
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
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _schedulePreviewUpdate(),
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
