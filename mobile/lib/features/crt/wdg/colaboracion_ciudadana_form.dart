import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/colaboracion_ciudadana_text.dart';
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
      ColaboracionCiudadanaFormState();
}

class ColaboracionCiudadanaFormState extends State<ColaboracionCiudadanaForm> {
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
  String _motivo = ColaboracionCiudadanaText.motivos.first;
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
  List<CrtEasStation> _easStations = [];
  bool _cargandoEas = true;
  List<String> _movilesEas = [];
  final Set<String> _movilesSeleccionados = {};

  String _previewText = '';
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _cargarDistritos();
    _cargarEas();
    _cargarJefe();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actualizarPreview();
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
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
      CrtTextGenerator.jefeNombre = ap.isNotEmpty && nm.isNotEmpty
          ? '$ap $nm'
          : '';
    } catch (_) {
      CrtTextGenerator.jefeNombre = '';
    }
    if (mounted) _actualizarPreview();
  }

  Future<void> _cargarEas() async {
    try {
      final rows = await _crtApi.getEasStations();
      if (!mounted) return;
      setState(() {
        _easStations = rows
            .map(
              (json) => CrtEasStation(
                codigo: json['codigo']?.toString().trim() ?? '',
                nombre: json['nombre']?.toString().trim() ?? '',
                direccion: json['direccion']?.toString().trim() ?? '',
              ),
            )
            .where((eas) => eas.codigo.isNotEmpty && eas.nombre.isNotEmpty)
            .toList();
        _cargandoEas = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoEas = false);
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
      'GESTION DE RIESGOS': 'REPORTE DE GESTIÓN DE RIESGOS',
      'SUPERVISION': 'REPORTE DE SUPERVISIÓN',
      'RADIOPERADOR': 'REPORTE DE RADIOPERADOR',
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
    final motivo = _motivo == 'Otro motivo'
        ? _otroMotivoCtrl.text
        : _motivo.toLowerCase();
    final extras = <String, String?>{
      'MOTORIZADO': _motoCtrl.text,
      'K9': _canCtrl.text,
      'EAS': _movilCtrl.text,
      'CICLISTA': _bicicletaCtrl.text,
      'SUPERVISION': _movilCtrl.text,
    };
    _previewText = ColaboracionCiudadanaText.build(
      ColaboracionCiudadanaData(
        servicio: _servicioTitle(_servicio).replaceFirst('REPORTE DE ', ''),
        distrito: _distritoSeleccionado ?? '',
        circuito: _needsEasDropdown
            ? (_easSeleccionado == null
                  ? ''
                  : '${_easSeleccionado!.codigo} ${_easSeleccionado!.nombre}')
            : _circuitoCtrl.text,
        fechaHora: DateTime.now(),
        direccion: _direccionCtrl.text,
        jefe: CrtTextGenerator.jefeDisplay,
        reporta: widget.user?.nombreCompleto ?? '',
        nombreCiudadano: _nombreCiudadanoCtrl.text,
        cedula: _cedulaCtrl.text,
        contacto: _contactoCtrl.text,
        motivo: motivo,
        accion: _accionCtrl.text,
        resultado: _resultadoCtrl.text,
        conNovedades: _estadoFinal == 'CON NOVEDADES',
        detalleNovedad: _novedadCtrl.text,
        moto: _servicio == 'MOTORIZADO' ? extras[_servicio] : null,
        can: _servicio == 'K9' ? extras[_servicio] : null,
        movil: _servicio == 'EAS' || _servicio == 'SUPERVISION'
            ? extras[_servicio]
            : null,
        bicicleta: _servicio == 'CICLISTA' ? extras[_servicio] : null,
        videoperador: _isRadioperador ? _videoperadorCtrl.text : null,
        movilesEnCirculacion: _needsEasDropdown
            ? (_movilesSeleccionados.toList()..sort())
            : const [],
      ),
    );
    widget.onPreviewChanged?.call(_previewText);
  }

  bool validate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete correctamente los campos obligatorios.'),
        ),
      );
    }
    return valid;
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  void _onServicioChanged(String? value) {
    if (value == null) return;
    setState(() {
      _servicio = value;
      _circuitoCtrl.clear();
      _easSeleccionado = null;
      _motoCtrl.clear();
      _canCtrl.clear();
      _movilCtrl.clear();
      _bicicletaCtrl.clear();
      _videoperadorCtrl.clear();
      _movilesSeleccionados.clear();
      _movilesEas = [];
    });
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
            final movilActivo = a['movil_activo']?.toString().toLowerCase();
            return matchEas && (movilActivo == 'true' || movilActivo == '1');
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
        return _buildMovilesCheckboxes();
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
            _buildMovilesCheckboxes(),
            const SizedBox(height: 10),
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
    if (_cargandoEas) return const LinearProgressIndicator();
    return DropdownButtonFormField<CrtEasStation>(
      initialValue: _easSeleccionado,
      isExpanded: true,
      decoration: _inputDeco(
        label: 'Circuito / EAS',
        icon: Icons.location_city_outlined,
      ),
      validator: (value) => value == null ? 'Seleccione un EAS.' : null,
      items: _easStations
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
                  'MÓVIL $movil',
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
                  'COLABORACIÓN CIUDADANA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de colaboración brindada al ciudadano',
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
                  validator: (value) =>
                      value == null ? 'Seleccione el tipo de servicio.' : null,
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
                        validator: (value) =>
                            value == null ? 'Seleccione un distrito.' : null,
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
              onChanged: (_) => _schedulePreviewUpdate(),
              validator: (value) => _required(value, 'Circuito'),
            ),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _direccionCtrl,
            decoration: _inputDeco(
              label: 'Dirección',
              icon: Icons.location_on_outlined,
            ),
            onChanged: (_) => _schedulePreviewUpdate(),
            validator: (value) => _required(value, 'Dirección'),
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
            onChanged: (_) => _schedulePreviewUpdate(),
            validator: (value) => _required(value, 'Nombre del ciudadano'),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cedulaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDeco(
                    label: 'Número de cédula',
                    icon: Icons.badge_outlined,
                  ),
                  onChanged: (_) => _schedulePreviewUpdate(),
                  validator: (value) =>
                      ColaboracionCiudadanaText.cedulaValida(value ?? '')
                      ? null
                      : 'Ingrese una cédula de 10 dígitos.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _contactoCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _inputDeco(
                    label: 'Número de contacto',
                    icon: Icons.phone_outlined,
                  ),
                  onChanged: (_) => _schedulePreviewUpdate(),
                  validator: (value) =>
                      ColaboracionCiudadanaText.telefonoValido(value ?? '')
                      ? null
                      : 'Ingrese un teléfono válido de 10 dígitos.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _sectionBadge(3, 'DETALLE DE LA COLABORACIÓN'),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _motivo,
            decoration: _inputDeco(
              label: 'Motivo de colaboración',
              icon: Icons.help_outline,
            ),
            isExpanded: true,
            items: ColaboracionCiudadanaText.motivos
                .map(
                  (motivo) =>
                      DropdownMenuItem(value: motivo, child: Text(motivo)),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                _motivo = v ?? ColaboracionCiudadanaText.motivos.first;
                if (_motivo != 'Otro motivo') _otroMotivoCtrl.clear();
              });
              _actualizarPreview();
            },
            validator: (value) =>
                value == null ? 'Seleccione el motivo.' : null,
          ),

          if (_motivo == 'Otro motivo') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _otroMotivoCtrl,
              decoration: _inputDeco(
                label: 'Especifique el motivo',
                icon: Icons.edit_outlined,
              ),
              onChanged: (_) => _schedulePreviewUpdate(),
              validator: (value) => _required(value, 'El motivo específico'),
            ),
          ],

          const SizedBox(height: 12),

          TextFormField(
            controller: _accionCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDeco(
              label: 'Acción realizada',
              icon: Icons.gavel_outlined,
              hint: 'Ej: se realizo la verificacion correspondiente...',
            ).copyWith(alignLabelWithHint: true),
            onChanged: (_) => _schedulePreviewUpdate(),
            validator: (value) => _required(value, 'Acción realizada'),
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
            onChanged: (_) => _schedulePreviewUpdate(),
            validator: (value) =>
                _required(value, 'Resultado del procedimiento'),
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
              setState(() {
                _estadoFinal = v ?? 'SIN NOVEDADES';
                if (_estadoFinal != 'CON NOVEDADES') _novedadCtrl.clear();
              });
              _actualizarPreview();
            },
            validator: (value) =>
                value == null ? 'Seleccione el estado final.' : null,
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
              onChanged: (_) => _schedulePreviewUpdate(),
              validator: (value) => _required(value, 'Detalle de la novedad'),
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
