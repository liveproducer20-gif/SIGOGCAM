import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../mdl/crt_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';

class DesalojoForm extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const DesalojoForm({
    super.key,
    this.user,
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<DesalojoForm> createState() => _DesalojoFormState();
}

class _DesalojoFormState extends State<DesalojoForm> {
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

  TimeOfDay _horaIngreso = TimeOfDay.now();
  final _direccionCtrl = TextEditingController();
  final _direccionDesalojoCtrl = TextEditingController();
  final _circuitoCtrl = TextEditingController();
  final _acmCtrl = TextEditingController(text: '1');
  final _novedadesCtrl = TextEditingController();

  CrtEasStation? _easSeleccionado;
  List<String> _movilesEas = [];
  final Set<String> _movilesSeleccionados = {};
  bool _esAgresivo = false;
  bool _necesitaColaboracion = false;

  bool get _isEas => _servicio == 'EAS';
  bool get _isRadioperador => _servicio == 'RADIOPERADOR';
  bool get _needsEasDropdown => _isEas || _isRadioperador;

  String _previewText = '';
  Timer? _previewDebounce;

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
    _previewDebounce?.cancel();
    _direccionCtrl.dispose();
    _direccionDesalojoCtrl.dispose();
    _circuitoCtrl.dispose();
    _acmCtrl.dispose();
    _novedadesCtrl.dispose();
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

  void _applyAutoShift() {
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute;
    if (totalMinutes >= 1320) {
      _horaIngreso = const TimeOfDay(hour: 22, minute: 0);
    } else if (totalMinutes >= 840) {
      _horaIngreso = const TimeOfDay(hour: 14, minute: 0);
    } else {
      _horaIngreso = const TimeOfDay(hour: 6, minute: 0);
    }
  }

  void _onServicioChanged(String? value) {
    if (value == null) return;
    final prevNeedsEas = _needsEasDropdown;
    setState(() {
      _servicio = value;
      if (prevNeedsEas && !_needsEasDropdown) {
        _easSeleccionado = null;
        _circuitoCtrl.clear();
        _movilesEas = [];
        _movilesSeleccionados.clear();
        _horaIngreso = TimeOfDay.now();
      }
      if (_needsEasDropdown) {
        _applyAutoShift();
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
    final horario = CrtTextGenerator.obtenerHorarioJornada();
    final hora =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final direccion =
        _direccionCtrl.text.isNotEmpty ? _direccionCtrl.text : '[DIRECCION]';
    final acm = _acmCtrl.text.isNotEmpty ? _acmCtrl.text : '0';
    final saludo = CrtSpecialTextGenerator.saludo(now);
    final causa = 'Desalojo de vendedores autónomos no regularizados';

    final circuito = _needsEasDropdown && _easSeleccionado != null
        ? _easSeleccionado!.nombre
        : (_circuitoCtrl.text.isNotEmpty ? _circuitoCtrl.text : '[CIRCUITO]');

    final calleDesalojo =
        _direccionDesalojoCtrl.text.isNotEmpty
            ? _direccionDesalojoCtrl.text
            : direccion;

    final String bodyText;
    if (!_esAgresivo) {
      bodyText =
          '$saludo, Sr. $jefe muy respetuosamente me permito informarle que a la altura de la calle "$calleDesalojo" se realizo el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo de manera pacífica y respetando la integridad de los señores comerciantes no regularizados se les indicó que no pueden permanecer en el lugar y que posterior a ello se retiren del sitio, así mismo haciendo cumplir la ordenanza municipal De Uso De Espacio Y Vía Pública se dejó el espacio sin novedad.';
    } else if (_necesitaColaboracion) {
      bodyText =
          '$saludo, Sr. $jefe muy respetuosamente me permito informarle que a la altura de la calle "$calleDesalojo" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso a las indicaciones que se les está dando de parte del personal municipal, solicito colaboración con otro móvil para realizar un operativo en el sector mencionado para evitar el asentamiento no regularizado de los comerciantes en el punto.';
    } else {
      bodyText =
          '$saludo, Sr. $jefe muy respetuosamente me permito informarle que a la altura de la calle "$calleDesalojo" se procedió a realizar el desalojo de vendedores autónomos no regularizados que se encontraban realizando actividad comercial en los alrededores; asi mismo los señores hacen caso omiso, de tal manera se les indicó que, si mantenían esa actitud y no colaboraban con lo solicitado, se procedería a realizar el retiro temporal de la mercadería, de tal modo una vez indicado el procedimiento que iba a tomar el personal municipal, procedieron a retirarse.';
    }

    final buf = StringBuffer()
      ..writeln('*CUERPO DE AGENTES DE CONTROL MUNICIPAL*')
      ..writeln()
      ..writeln('*${_servicioTitle(_servicio)}*')
      ..writeln('*DISTRITO:* $distrito')
      ..writeln('*CIRCUITO:* $circuito')
      ..writeln('*HORARIO:* $horario')
      ..writeln('*HORA:* $hora')
      ..writeln('*FECHA:* $fecha')
      ..writeln('*DIRECCION:* $direccion')
      ..writeln('*CAUSA:* $causa')
      ..writeln()
      ..writeln(bodyText);

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
    buf.writeln('*$acm ACM*');
    buf.writeln();
    buf.writeln('Sin mas novedades que informar.');
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
          if (_movilesEas.isEmpty)
            Text(
              _easSeleccionado != null
                  ? 'No hay móviles asignados a este EAS'
                  : 'Seleccione un EAS para ver móviles',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          else
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
              Icons.storefront_outlined,
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
                  'DESALOJO DE VENDEDORES',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vendedores autónomos no regularizados',
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
                  isExpanded: true,
                  decoration: _inputDeco(
                    label: 'Tipo de Servicio',
                    icon: Icons.category_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PEDESTRE', child: Text('Pedestre')),
                    DropdownMenuItem(value: 'MOTORIZADO', child: Text('Motorizado')),
                    DropdownMenuItem(value: 'K9', child: Text('K9')),
                    DropdownMenuItem(value: 'EAS', child: Text('EAS')),
                    DropdownMenuItem(value: 'TURISMO', child: Text('Turismo')),
                    DropdownMenuItem(value: 'CICLISTA', child: Text('Ciclista')),
                    DropdownMenuItem(value: 'ADMINISTRATIVO', child: Text('Administrativo')),
                    DropdownMenuItem(value: 'AMBIENTE', child: Text('Ambiente')),
                    DropdownMenuItem(value: 'ENCARGADO', child: Text('Encargado')),
                    DropdownMenuItem(value: 'GESTION DE RIESGOS', child: Text('Gestión de Riesgos')),
                    DropdownMenuItem(value: 'SUPERVISION', child: Text('Supervisión')),
                    DropdownMenuItem(value: 'RADIOPERADOR', child: Text('Radioperador')),
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

          if (!_needsEasDropdown) ...[
            _buildHoraField(),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _direccionCtrl,
            decoration: _inputDeco(
              label: 'Dirección general',
              icon: Icons.location_on_outlined,
            ),
            onChanged: (_) => _schedulePreviewUpdate(),
          ),
          const SizedBox(height: 12),

          if (_needsEasDropdown) ...[
            DropdownButtonFormField<CrtEasStation>(
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
            ),
            if (_easSeleccionado != null && _movilesEas.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMovilesCheckboxes(),
            ],
          ] else ...[
            TextFormField(
              controller: _circuitoCtrl,
              decoration: _inputDeco(
                label: 'Circuito',
                icon: Icons.route_outlined,
              ),
              onChanged: (_) => _schedulePreviewUpdate(),
            ),
          ],
          const SizedBox(height: 12),

          TextFormField(
            controller: _acmCtrl,
            decoration: _inputDeco(
              label: 'Número de ACM',
              icon: Icons.people_outlined,
            ),
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
          _sectionBadge(2, 'DETALLE DEL DESALOJO'),
          const SizedBox(height: 16),

          TextFormField(
            controller: _direccionDesalojoCtrl,
            decoration: _inputDeco(
              label: 'Dirección del desalojo',
              icon: Icons.storefront_outlined,
              hint: 'Calle específica donde se realiza el desalojo',
            ),
            onChanged: (_) => _schedulePreviewUpdate(),
          ),
          const SizedBox(height: 14),

          Container(
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
                  'CONDICIONES DEL DESALOJO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _esAgresivo,
                  onChanged: (v) {
                    setState(() => _esAgresivo = v ?? false);
                    _actualizarPreview();
                  },
                  title: const Text(
                    '¿Los vendedores se muestran agresivos?',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _blueMid,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _necesitaColaboracion,
                  onChanged: (v) {
                    setState(() => _necesitaColaboracion = v ?? false);
                    _actualizarPreview();
                  },
                  title: const Text(
                    '¿Se necesita colaboración de otro móvil?',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: _blueMid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _novedadesCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDeco(
              label: 'Novedades adicionales',
              icon: Icons.notes_outlined,
              hint: 'Información complementaria sobre el desalojo...',
            ).copyWith(
              alignLabelWithHint: true,
            ),
            onChanged: (_) => _schedulePreviewUpdate(),
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
