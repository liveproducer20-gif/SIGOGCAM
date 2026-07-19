import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../../adm/adm_api.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class AusentismoForm extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const AusentismoForm({
    super.key,
    this.user,
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<AusentismoForm> createState() => _AusentismoFormState();
}

class _AusentismoFormState extends State<AusentismoForm> {
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

  List<Map<String, dynamic>> _personal = [];
  Map<String, dynamic>? _servidorSeleccionado;
  bool _cargandoPersonal = true;

  final _circuitoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _motivoOtroCtrl = TextEditingController();
  final _casaSaludCtrl = TextEditingController();

  String _tipoAusentismo = 'POR HORAS';
  String _motivo = 'EXAMENES MEDICOS';

  TimeOfDay _horaSalida = TimeOfDay.now();
  TimeOfDay _horaRetorno = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 1));

  CrtEasStation? _easSeleccionado;

  String _previewText = '';

  @override
  void initState() {
    super.initState();
    _cargarDistritos();
    _cargarPersonal();
    _cargarJefe();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _actualizarPreview();
    });
  }

  @override
  void dispose() {
    _circuitoCtrl.dispose();
    _direccionCtrl.dispose();
    _motivoOtroCtrl.dispose();
    _casaSaludCtrl.dispose();
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

  Future<void> _cargarPersonal() async {
    try {
      final lista = await AdmApi().getPersonalList();
      if (mounted) {
        setState(() {
          _personal = lista;
          _cargandoPersonal = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoPersonal = false);
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

  String _formatName(Map<String, dynamic> p) {
    final ap = (p['apellidos'] as String? ?? '').trim();
    final nm = (p['nombres'] as String? ?? '').trim();
    if (ap.isEmpty && nm.isEmpty) return 'Sin nombre';
    return '$ap $nm';
  }

  String _formatFecha(DateTime f) {
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  void _actualizarPreview() {
    final now = DateTime.now();
    final jefe = CrtTextGenerator.jefeDisplay;
    final reporta = widget.user?.nombreCompleto ?? 'ACM';
    final distrito = _distritoSeleccionado ?? '';
    final servicio = _servicioTitle(_servicio);
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fecha = _formatFecha(now);
    final direccion =
        _direccionCtrl.text.isNotEmpty ? _direccionCtrl.text : '[DIRECCION]';
    final saludo = CrtSpecialTextGenerator.saludo(now);
    const causa = 'AUSENTISMO';

    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final servidorNombre = _servidorSeleccionado != null
        ? _formatName(_servidorSeleccionado!)
        : '[SERVIDOR]';

    String motivoTexto;
    if (_motivo == 'OTRO') {
      final otro = _motivoOtroCtrl.text.trim();
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
      ..writeln(
        '$saludo, permiso Sr. $jefe Jefe de Control Municipal.',
      )
      ..writeln();

    switch (_tipoAusentismo) {
      case 'POR HORAS':
        final hSalida =
            '${_horaSalida.hour.toString().padLeft(2, '0')}:${_horaSalida.minute.toString().padLeft(2, '0')}';
        final hRetorno =
            '${_horaRetorno.hour.toString().padLeft(2, '0')}:${_horaRetorno.minute.toString().padLeft(2, '0')}';
        buf
          ..writeln(
            'Muy respetuosamente me permito informar que el ACM. $servidorNombre se ausenta de su lugar de servicio por motivo de $motivoTexto.',
          )
          ..writeln()
          ..writeln(
            'La ausencia corresponde desde $hSalida hasta $hRetorno.',
          )
          ..writeln()
          ..writeln(
            'Se deja constancia de la novedad para los fines pertinentes.',
          );
      case 'POR DIAS':
        final fInicio = _formatFecha(_fechaInicio);
        final fFin = _formatFecha(_fechaFin);
        buf
          ..writeln(
            'Muy respetuosamente me permito informar que el ACM. $servidorNombre se ausenta de su lugar de servicio por motivo de $motivoTexto.',
          )
          ..writeln()
          ..writeln(
            'El permiso corresponde desde el $fInicio hasta el $fFin.',
          )
          ..writeln()
          ..writeln(
            'Se deja constancia de la novedad para los fines pertinentes.',
          );
      case 'TRASLADO':
        final casa = _casaSaludCtrl.text.trim();
        final casaSalud = casa.isNotEmpty ? casa : '[CASA DE SALUD]';
        buf.writeln(
          'Muy respetuosamente me permito informar que el ACM. $servidorNombre se ausenta de su lugar de servicio por motivo de $motivoTexto, procediendo a trasladarse a $casaSalud.',
        );
        buf.writeln();
        buf.writeln(
          'Se deja constancia de la novedad para los fines pertinentes.',
        );
    }

    buf.writeln();
    buf.writeln('*REPORTA:*');
    buf.writeln('ACM. $reporta');
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
      if (prevNeedsEas && !_needsEasDropdown) {
        _easSeleccionado = null;
        _circuitoCtrl.clear();
      }
    });
    _actualizarPreview();
  }

  void _onEasChanged(CrtEasStation? value) {
    if (value == null) return;
    setState(() => _easSeleccionado = value);
    _actualizarPreview();
  }

  void _onTipoAusentismoChanged(String? value) {
    if (value == null) return;
    setState(() {
      _tipoAusentismo = value;
      _horaSalida = TimeOfDay.now();
      _horaRetorno = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: TimeOfDay.now().minute,
      );
      _fechaInicio = DateTime.now();
      _fechaFin = DateTime.now().add(const Duration(days: 1));
      _casaSaludCtrl.clear();
    });
    _actualizarPreview();
  }

  void _onMotivoChanged(String? value) {
    if (value == null) return;
    setState(() => _motivo = value);
    _actualizarPreview();
  }

  Future<void> _selectHoraSalida() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSalida,
    );
    if (picked != null) {
      setState(() => _horaSalida = picked);
      _actualizarPreview();
    }
  }

  Future<void> _selectHoraRetorno() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaRetorno,
    );
    if (picked != null) {
      setState(() => _horaRetorno = picked);
      _actualizarPreview();
    }
  }

  Future<void> _selectFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
      if (_fechaFin.isBefore(_fechaInicio)) {
        _fechaFin = _fechaInicio.add(const Duration(days: 1));
      }
      _actualizarPreview();
    }
  }

  Future<void> _selectFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: _fechaInicio,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fechaFin = picked);
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

  Widget _buildTipoAusentismoFields() {
    switch (_tipoAusentismo) {
      case 'POR HORAS':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectHoraSalida,
                    child: InputDecorator(
                      decoration: _inputDeco(
                        label: 'Hora de salida',
                        icon: Icons.access_time,
                      ),
                      child: Text(
                        '${_horaSalida.hour.toString().padLeft(2, '0')}:${_horaSalida.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, color: _blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectHoraRetorno,
                    child: InputDecorator(
                      decoration: _inputDeco(
                        label: 'Hora de retorno',
                        icon: Icons.access_time_filled,
                      ),
                      child: Text(
                        '${_horaRetorno.hour.toString().padLeft(2, '0')}:${_horaRetorno.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, color: _blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'POR DIAS':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectFechaInicio,
                    child: InputDecorator(
                      decoration: _inputDeco(
                        label: 'Fecha de inicio',
                        icon: Icons.calendar_today,
                      ),
                      child: Text(
                        _formatFecha(_fechaInicio),
                        style: const TextStyle(fontSize: 14, color: _blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectFechaFin,
                    child: InputDecorator(
                      decoration: _inputDeco(
                        label: 'Fecha de fin',
                        icon: Icons.calendar_month,
                      ),
                      child: Text(
                        _formatFecha(_fechaFin),
                        style: const TextStyle(fontSize: 14, color: _blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'TRASLADO':
        return TextFormField(
          controller: _casaSaludCtrl,
          decoration: _inputDeco(
            label: 'Casa de salud',
            icon: Icons.local_hospital_outlined,
            hint: 'Ej: Hospital del IESS',
          ),
          onChanged: (_) => _actualizarPreview(),
        );
      default:
        return const SizedBox.shrink();
    }
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
              Icons.person_off_outlined,
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
                  'AUSENTISMO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registro de ausentismo del personal',
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

          _cargandoPersonal
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: _inputDeco(
                    label: 'Servidor / Personal',
                    icon: Icons.person_outlined,
                  ),
                  isExpanded: true,
                  items: _personal
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            _formatName(p),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _servidorSeleccionado = v);
                    _actualizarPreview();
                  },
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
          _sectionBadge(2, 'DETALLE DEL AUSENTISMO'),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _tipoAusentismo,
            decoration: _inputDeco(
              label: 'Tipo de ausentismo',
              icon: Icons.timer_outlined,
            ),
            items: const [
              DropdownMenuItem(
                  value: 'POR HORAS', child: Text('Por Horas')),
              DropdownMenuItem(
                  value: 'POR DIAS', child: Text('Por Dias')),
              DropdownMenuItem(
                  value: 'TRASLADO',
                  child: Text('Traslado a Casa de Salud')),
            ],
            onChanged: _onTipoAusentismoChanged,
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _motivo,
            decoration: _inputDeco(
              label: 'Motivo del ausentismo',
              icon: Icons.help_outline,
            ),
            items: const [
              DropdownMenuItem(
                  value: 'EXAMENES MEDICOS',
                  child: Text('Examenes medicos')),
              DropdownMenuItem(
                  value: 'PERMISO MEDICO',
                  child: Text('Permiso medico')),
              DropdownMenuItem(value: 'NACIMIENTO', child: Text('Nacimiento')),
              DropdownMenuItem(
                  value: 'PATERNIDAD', child: Text('Paternidad')),
              DropdownMenuItem(
                  value: 'MATERNIDAD', child: Text('Maternidad')),
              DropdownMenuItem(value: 'ESTUDIOS', child: Text('Estudios')),
              DropdownMenuItem(
                  value: 'CALAMIDAD DOMESTICA',
                  child: Text('Calamidad domestica')),
              DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
            ],
            onChanged: _onMotivoChanged,
          ),
          const SizedBox(height: 12),

          if (_motivo == 'OTRO') ...[
            TextFormField(
              controller: _motivoOtroCtrl,
              decoration: _inputDeco(
                label: 'Especifique el motivo',
                icon: Icons.edit_outlined,
              ),
              onChanged: (_) => _actualizarPreview(),
            ),
            const SizedBox(height: 12),
          ],

          _buildTipoAusentismoFields(),
        ],
      ),
    );
  }
}
