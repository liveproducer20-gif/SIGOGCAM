import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/thm/app_thm.dart';
import '../mdl/crt_models.dart';
import '../mdl/crt_special_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';
import '../svc/crt_text_generator.dart';
import 'crt_widgets.dart';

class FormacionForm extends StatefulWidget {
  final TipoFormacion tipoFormacion;
  final AppUser? user;
  final String jefeNombre;
  final ValueChanged<String>? onPreviewChanged;
  final VoidCallback? onGenerate;
  final bool generando;

  const FormacionForm({
    super.key,
    required this.tipoFormacion,
    this.user,
    this.jefeNombre = 'Jefe de Control Municipal',
    this.onPreviewChanged,
    this.onGenerate,
    this.generando = false,
  });

  @override
  State<FormacionForm> createState() => _FormacionFormState();
}

class _FormacionFormState extends State<FormacionForm> {
  final _formKey = GlobalKey<FormState>();
  final _crtApi = CrtApi();

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

  bool get _isEntrante => widget.tipoFormacion == TipoFormacion.entrante;

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
    final direccion = _direccionCtrl.text.isNotEmpty
        ? _direccionCtrl.text
        : '[DIRECCION]';
    final acm = _acmCtrl.text.isNotEmpty ? _acmCtrl.text : '0';
    final saludo = CrtSpecialTextGenerator.saludo(now);

    final String ubicacionLabel;
    final String ubicacionValor;
    if (_needsEasDropdown && _easSeleccionado != null) {
      ubicacionLabel = '*EAS:*';
      ubicacionValor = _easSeleccionado!.nombre;
    } else {
      ubicacionLabel = '*CIRCUITO:*';
      ubicacionValor = _circuitoCtrl.text.isNotEmpty
          ? _circuitoCtrl.text
          : '[CIRCUITO]';
    }

    final personalLabel = _isEntrante ? 'entrante' : 'saliente';
    final accionLabel = _isEntrante ? 'cuenta' : 'conto';
    final causaLabel = widget.tipoFormacion.causa;

    final buf = StringBuffer()
      ..writeln('*CUERPO DE AGENTES DE CONTROL MUNICIPAL*')
      ..writeln()
      ..writeln('*$servicio*')
      ..writeln()
      ..writeln('*DISTRITO:* $distrito')
      ..writeln()
      ..writeln('$ubicacionLabel $ubicacionValor')
      ..writeln()
      ..writeln('*HORARIO:* $horario - $horaSalida')
      ..writeln('*HORA:* $hora')
      ..writeln('*FECHA:* $fecha')
      ..writeln('*DIRECCION:* $direccion')
      ..writeln('*CAUSA:* $causaLabel')
      ..writeln()
      ..writeln('$saludo, permiso Sr. $jefe.')
      ..writeln()
      ..writeln(
        'Muy respetuosamente, me permito informar que se procedio con la formacion del personal $personalLabel'
        '${_needsEasDropdown ? ' del EAS ${_easSeleccionado!.nombre}' : ' asignado al circuito ${_circuitoCtrl.text.isNotEmpty ? _circuitoCtrl.text : "[CIRCUITO]"}'},'
        ' en $direccion.',
      )
      ..writeln()
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

    if (_isRadioperador && _movilesSeleccionados.isNotEmpty) {
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
        if (_easSeleccionado != null) {
          _actualizarMovilesEas(_easSeleccionado!);
        }
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

  Widget _buildServiceFields() {
    switch (_servicio) {
      case 'MOTORIZADO':
        return _buildField(
          'Numero de moto',
          _motoCtrl,
          Icons.two_wheeler_outlined,
        );
      case 'K9':
        return _buildField('Nombre del Can', _canCtrl, Icons.pets_outlined);
      case 'EAS':
        return Column(
          children: [
            _buildEasDropdown(),
            const SizedBox(height: 12),
            _buildField(
              'Numero de movil',
              _movilCtrl,
              Icons.directions_car_outlined,
            ),
          ],
        );
      case 'CICLISTA':
        return _buildField(
          'Numero de bicicleta',
          _bicicletaCtrl,
          Icons.pedal_bike_outlined,
        );
      case 'SUPERVISION':
        return _buildField(
          'Numero de movil',
          _movilCtrl,
          Icons.directions_car_outlined,
        );
      case 'RADIOPERADOR':
        return Column(
          children: [
            _buildEasDropdown(),
            const SizedBox(height: 12),
            _buildField(
              'Videoperador',
              _videoperadorCtrl,
              Icons.videocam_outlined,
            ),
            if (_easSeleccionado != null && _movilesEas.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMovilesCheckboxes(),
            ],
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEasDropdown() {
    return DropdownButtonFormField<CrtEasStation>(
      initialValue: _easSeleccionado,
      decoration: InputDecoration(
        labelText: 'EAS',
        prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: CrtCatalog.easStations
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text('${e.codigo} - ${e.nombre}'),
            ),
          )
          .toList(),
      onChanged: _onEasChanged,
    );
  }

  Widget _buildMovilesCheckboxes() {
    return CrtSectionCard(
      icon: Icons.directions_car_outlined,
      title: 'MOVILES EN CIRCULACION',
      headerColor: CrtSectionColors.datosGenerales,
      backgroundColor: CrtSectionColors.datosGeneralesBg,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _movilesEas.map((movil) {
            final selected = _movilesSeleccionados.contains(movil);
            return FilterChip(
              label: Text('MOVIL $movil'),
              selected: selected,
              onSelected: (_) => _toggleMovil(movil),
              selectedColor: AppThm.priClr.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? AppThm.priClr : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppThm.priClr : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    int minLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines > 1 ? 5 : 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _actualizarPreview(),
    );
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('INFORMACION DEL SERVICIO'),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _servicio,
              decoration: InputDecoration(
                labelText: 'Tipo de Servicio',
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'PEDESTRE', child: Text('Pedestre')),
                DropdownMenuItem(
                  value: 'MOTORIZADO',
                  child: Text('Motorizado'),
                ),
                DropdownMenuItem(value: 'K9', child: Text('K9')),
                DropdownMenuItem(value: 'EAS', child: Text('EAS')),
                DropdownMenuItem(value: 'TURISMO', child: Text('Turismo')),
                DropdownMenuItem(value: 'CICLISTA', child: Text('Ciclista')),
                DropdownMenuItem(
                  value: 'ADMINISTRATIVO',
                  child: Text('Administrativo'),
                ),
                DropdownMenuItem(value: 'AMBIENTE', child: Text('Ambiente')),
                DropdownMenuItem(value: 'ENCARGADO', child: Text('Encargado')),
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
            const SizedBox(height: 12),

            _cargandoDistritos
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    initialValue: _distritoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Distrito',
                      prefixIcon: const Icon(Icons.map_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _distritos
                        .map(
                          (d) => DropdownMenuItem(
                            value: d['nombre'] as String?,
                            child: Text(d['nombre'] as String? ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _distritoSeleccionado = v);
                      _actualizarPreview();
                    },
                  ),
            const SizedBox(height: 12),

            if (!_needsEasDropdown)
              _buildField('Circuito', _circuitoCtrl, Icons.route_outlined),
            if (!_needsEasDropdown) const SizedBox(height: 12),

            _buildHoraField(),
            const SizedBox(height: 12),

            _buildField(
              'Direccion',
              _direccionCtrl,
              Icons.location_on_outlined,
              isRequired: true,
            ),
            const SizedBox(height: 12),

            _buildField('Numero de ACM', _acmCtrl, Icons.people_outlined),
            const SizedBox(height: 16),

            _buildServiceFields(),
            const SizedBox(height: 16),

            _buildField(
              'Detalle del personal y/o novedades',
              _novedadesCtrl,
              Icons.notes_outlined,
              minLines: 3,
            ),
            const SizedBox(height: 16),

            _buildPhotoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppThm.priClr,
        letterSpacing: 0.5,
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
              decoration: InputDecoration(
                labelText: 'Hora de Ingreso',
                prefixIcon: const Icon(Icons.access_time, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Text(horaStr, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Hora de Salida (auto)',
              prefixIcon: const Icon(Icons.access_time_filled, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Text(
              horaSalidaStr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton() {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funcionalidad disponible proximamente'),
          ),
        );
      },
      icon: const Icon(Icons.camera_alt_outlined, size: 20),
      label: const Text('AGREGAR FOTO'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[600],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
