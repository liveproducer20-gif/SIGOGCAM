import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/auth/app_user.dart';
import '../../ins/ins_api.dart';
import '../../ins/ins_badge_dlg.dart';
import '../mdl/crt_special_models.dart';
import '../svc/crt_api.dart';
import '../svc/crt_catalog.dart';
import '../svc/crt_special_text_generator.dart';

enum CrtSpecialFormKind { formacion, conductor, otras }

class CrtSpecialForm extends StatefulWidget {
  final CrtSpecialFormKind kind;
  final AppUser? user;
  final String jefe;
  final bool canCreate;
  final TipoFormacion? formationType;
  final bool hidePreview;
  final ValueChanged<String>? onPreviewChanged;

  const CrtSpecialForm({
    super.key,
    required this.kind,
    required this.user,
    required this.jefe,
    required this.canCreate,
    this.formationType,
    this.hidePreview = false,
    this.onPreviewChanged,
  });

  @override
  State<CrtSpecialForm> createState() => _CrtSpecialFormState();
}

class _CrtSpecialFormState extends State<CrtSpecialForm> {
  final _formKey = GlobalKey<FormState>();
  final _api = CrtApi();
  final _controllers = <String, TextEditingController>{};
  List<Map<String, dynamic>> _personal = const [];
  List<Map<String, dynamic>> _moviles = const [];
  List<Map<String, dynamic>> _distritos = const [];
  bool _loadingCatalogs = true;
  bool _saving = false;
  bool _created = false;
  String? _preview;
  DateTime _dateTime = DateTime.now();
  TipoFormacion _tipoFormacion = TipoFormacion.entrante;
  OpcionConductor _opcionConductor = OpcionConductor.entradaPersonal;
  String _jornada = 'Vespertina';
  String _combustible = 'Full';
  int? _conductorId;
  int? _encargadoId;
  int? _movilId;
  bool _movilesActivos = true;

  TextEditingController _c(String key, [String value = '']) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: value));

  @override
  void initState() {
    super.initState();
    _tipoFormacion = widget.formationType ?? TipoFormacion.entrante;
    _seedDefaults();
    _loadCatalogs();
  }

  void _seedDefaults() {
    _refreshAutomaticTime();
    _c('distrito', '#5 MODELO');
    _c('circuito', 'EAS 12 CEIBOS');
    _c('direccion', 'Calle 15 ava y Dr Alberto Dacach Saman');
    _c('horario', CrtCatalog.horarioActual(_dateTime));
    _c('causa');
    _c('novedad');
    _c('novedades');
    _c('radiooperadores', '2');
    _c('operativos', '6');
    _c('policias');
    _c('moviles', '187,188,189');
    _c('reportantes', widget.user?.nombreCompleto ?? '');
    _c('conductor', widget.user?.nombreCompleto ?? '');
    final cedula = widget.user?.cedula ?? '';
    _c(
      'cedula4',
      cedula.length >= 4 ? cedula.substring(cedula.length - 4) : '',
    );
    _c('lugar', 'EAS 12 Los Ceibos');
    _c('disco', '189');
    _c('kilometraje');
    _c('servicio', 'EAS 12 Los Ceibos');
    _c('horarioConductor', '14:00-22:30');
    _c('encargado');
    _c('observaciones');
  }

  Future<void> _loadCatalogs() async {
    _loadPersonalMoviles();
    _loadDistritos();
  }

  Future<void> _loadPersonalMoviles() async {
    try {
      final data = await _api.getCatalogosOperativos();
      if (!mounted) return;
      setState(() {
        _personal = (data['personal'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _moviles = (data['moviles'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final currentUserId = widget.user?.id;
        if (currentUserId != null &&
            _personal.any(
              (person) => person['id'].toString() == currentUserId.toString(),
            )) {
          _conductorId = currentUserId;
          final current = _personal.firstWhere(
            (person) => person['id'].toString() == currentUserId.toString(),
          );
          _c('conductor').text = current['nombre_completo']?.toString() ?? '';
        }
        _loadingCatalogs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  Future<void> _loadDistritos() async {
    try {
      final distritos = await _api.getDistritos();
      if (!mounted) return;
      setState(() => _distritos = distritos);
    } catch (_) {
      if (mounted) _distritos = [];
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;

    Widget buildForm() => _panel(
      AbsorbPointer(
        absorbing: !widget.hidePreview && _preview != null,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              switch (widget.kind) {
                CrtSpecialFormKind.formacion => _formationFields(),
                CrtSpecialFormKind.conductor => _conductorFields(),
                CrtSpecialFormKind.otras => _otrasFields(),
              },
              if (widget.hidePreview) ...[
                const SizedBox(height: 24),
                _actionButtons(),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.hidePreview) {
      return buildForm();
    }

    final form = buildForm();
    final preview = _previewPanel();
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: form),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: preview),
            ],
          )
        : Column(children: [form, const SizedBox(height: 20), preview]);
  }

  Widget _formationFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(Icons.groups_outlined, _tipoFormacion.label),
      const SizedBox(height: 18),
      _districtDropdown(),
      _field('circuito', 'Circuito'),
      _field('direccion', 'Dirección'),
      DropdownButtonFormField<String>(
        initialValue: _jornada,
        decoration: _decoration('Jornada', Icons.schedule_outlined),
        items: const [
          'Matutina',
          'Vespertina',
          'Amanecida',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _jornada = value;
            _c('horario').text = switch (value) {
              'Matutina' => '06:00 A 14:30',
              'Vespertina' => '14:00 A 22:30',
              _ => '22:00 A 06:30',
            };
            _invalidate();
          });
        },
      ),
      _field('horario', 'Horario'),
      _field('novedades', 'Novedades', required: false, lines: 4),
      _field('radiooperadores', 'Número de radiooperadores', digits: true),
      _field('operativos', 'Número de ACM operativos', digits: true),
      _field(
        'policias',
        'Personal policial (uno por línea)',
        required: false,
        lines: 3,
      ),
      _movilesSection(),
      _reporterDisplay(),
    ].separatedBy(const SizedBox(height: 14)),
  );

  Widget _conductorFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(Icons.directions_car_outlined, 'REGISTRO VEHICULAR'),
      if (_loadingCatalogs) const LinearProgressIndicator(),
      _personSelector(
        label: 'Nombres del conductor',
        value: _conductorId,
        onChanged: (id, name) {
          _conductorId = id;
          _c('conductor').text = name;
        },
      ),
      _field(
        'cedula4',
        'Cuatro últimos números de la cédula',
        digits: true,
        maxLength: 4,
        validator: (value) => RegExp(r'^\d{4}$').hasMatch(value ?? '')
            ? null
            : 'Ingrese exactamente cuatro dígitos',
      ),
      DropdownButtonFormField<OpcionConductor>(
        initialValue: _opcionConductor,
        decoration: _decoration('Opción a reportar', Icons.rule_outlined),
        items: OpcionConductor.values
            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
            .toList(),
        onChanged: (value) => setState(() {
          _opcionConductor = value!;
          _invalidate();
        }),
      ),
      _field('lugar', 'Lugar de la opción a reportar'),
      _mobileSelector(),
      DropdownButtonFormField<String>(
        initialValue: _combustible,
        decoration: _decoration(
          'Cantidad de combustible',
          Icons.local_gas_station_outlined,
        ),
        items: const [
          'Full',
          '3/4',
          '1/2',
          '1/4',
          'Reserva',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) => setState(() {
          _combustible = value!;
          _invalidate();
        }),
      ),
      _field(
        'kilometraje',
        'Kilometraje del odómetro',
        digits: true,
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          return parsed == null || parsed < 0
              ? 'Ingrese un kilometraje válido'
              : null;
        },
      ),
      _field('servicio', 'Circuito, ruta o servicio asignado'),
      _field('horarioConductor', 'Horario asignado'),
      _personSelector(
        label: 'Jefe de patrulla o encargado',
        value: _encargadoId,
        onChanged: (id, name) {
          _encargadoId = id;
          _c('encargado').text = name;
        },
      ),
      _field(
        'observaciones',
        'Observaciones y novedades',
        required: false,
        lines: 5,
      ),
    ].separatedBy(const SizedBox(height: 14)),
  );

  Widget _otrasFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(Icons.dashboard_customize_outlined, 'Otras cartillas'),
      const SizedBox(height: 18),
      _districtDropdown(),
      _field('circuito', 'Circuito'),
      _field('direccion', 'Dirección'),
      _field('horario', 'Horario'),
      _field('causa', 'Causa'),
      _field('novedad', 'Novedad', lines: 6),
      _reporterDisplay(),
    ].separatedBy(const SizedBox(height: 14)),
  );

  Widget _personSelector({
    required String label,
    required int? value,
    required void Function(int?, String) onChanged,
  }) {
    if (_personal.isEmpty) {
      return _field(
        label == 'Nombres del conductor' ? 'conductor' : 'encargado',
        label,
      );
    }
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label, Icons.person_outline),
      items: _personal.map((person) {
        final id = int.tryParse(person['id'].toString())!;
        final name = person['nombre_completo']?.toString().trim() ?? '';
        return DropdownMenuItem(
          value: id,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      validator: (value) => value == null ? 'Seleccione una opción' : null,
      onChanged: (id) {
        final person = _personal.firstWhere(
          (e) => e['id'].toString() == id.toString(),
        );
        onChanged(id, person['nombre_completo']?.toString() ?? '');
        _invalidate();
      },
    );
  }

  Widget _mobileSelector() {
    if (_moviles.isEmpty) {
      return _field('disco', 'No. de disco del vehículo', digits: true);
    }
    return DropdownButtonFormField<int>(
      initialValue: _movilId,
      decoration: _decoration(
        'No. de disco del vehículo',
        Icons.directions_car_outlined,
      ),
      items: _moviles.map((mobile) {
        final id = int.tryParse(mobile['id'].toString())!;
        final number = mobile['numero_movil']?.toString() ?? '';
        return DropdownMenuItem(value: id, child: Text(number));
      }).toList(),
      validator: (value) => value == null ? 'Seleccione un móvil' : null,
      onChanged: (id) {
        final mobile = _moviles.firstWhere(
          (e) => e['id'].toString() == id.toString(),
        );
        setState(() {
          _movilId = id;
          _c('disco').text = mobile['numero_movil']?.toString() ?? '';
          final km = mobile['kilometraje_actual']?.toString() ?? '';
          if (_c('kilometraje').text.isEmpty) _c('kilometraje').text = km;
          _invalidate();
        });
      },
    );
  }

  Widget _districtDropdown() {
    final items = _distritos
        .map((d) => d['nombre']?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
    final current = _c('distrito').text;
    return DropdownButtonFormField<String>(
      initialValue: items.contains(current) ? current : null,
      isExpanded: true,
      decoration: _decoration('Distrito', Icons.map_outlined),
      items: items
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _c('distrito').text = value;
          _invalidate();
        });
      },
      validator: (v) => v == null || v.isEmpty ? 'Seleccione un distrito' : null,
    );
  }

  Widget _movilesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('¿Móviles en circulación?'),
          value: _movilesActivos,
          onChanged: (v) => setState(() => _movilesActivos = v),
        ),
      ),
      if (_movilesActivos)
        _field('moviles', 'Móviles en circulación (separados por coma)'),
    ],
  );

  Widget _reporterDisplay() => InputDecorator(
    decoration: _decoration(
      'Personal que reporta',
      Icons.badge_outlined,
    ),
    child: Text(
      widget.user?.nombreCompleto.isNotEmpty == true
          ? widget.user!.nombreCompleto
          : '[personal que reporta]',
    ),
  );

  Widget _field(
    String key,
    String label, {
    bool required = true,
    bool digits = false,
    int lines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: _c(key),
    minLines: lines,
    maxLines: lines,
    maxLength: maxLength,
    keyboardType: digits
        ? TextInputType.number
        : (lines > 1 ? TextInputType.multiline : null),
    inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: _decoration(label, Icons.edit_note_outlined),
    validator:
        validator ??
        (required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Campo obligatorio'
                  : null
            : null),
    onChanged: (_) => _invalidate(),
  );

  Widget _actionButtons() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (!_created)
        FilledButton.icon(
          onPressed: _saving
              ? null
              : (_preview == null ? _generatePreview : _create),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _preview == null
                      ? Icons.visibility_outlined
                      : Icons.save_outlined,
                ),
          label: Text(
            _preview == null ? 'Generar vista previa' : 'Crear cartilla',
          ),
        ),
      if (_preview != null)
        OutlinedButton.icon(
          onPressed: () => setState(_invalidate),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Seguir editando'),
        ),
      if (_created) ...[
        OutlinedButton.icon(
          onPressed: _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copiar texto'),
        ),
        OutlinedButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _preview = null;
            _created = false;
            _dateTime = DateTime.now();
          }),
          icon: const Icon(Icons.add_outlined),
          label: const Text('Crear otra cartilla'),
        ),
      ],
    ],
  );

  Widget _previewPanel() => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(Icons.preview_outlined, 'Vista previa'),
        const SizedBox(height: 16),
        _actionButtons(),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 560),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: _preview == null
              ? const Center(
                  child: Text(
                    'Complete el formulario y presione "Generar vista previa"',
                    textAlign: TextAlign.center,
                  ),
                )
              : SelectableText(
                  _preview!,
                  style: const TextStyle(
                    height: 1.45,
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                  ),
                ),
        ),
      ],
    ),
  );

  void _generatePreview() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _refreshAutomaticTime();
      _preview = switch (widget.kind) {
        CrtSpecialFormKind.formacion => CrtSpecialTextGenerator.formacion(
          _formationData(),
        ),
        CrtSpecialFormKind.conductor => CrtSpecialTextGenerator.conductor(
          _conductorData(),
        ),
        CrtSpecialFormKind.otras => CrtSpecialTextGenerator.otras(_otrasData()),
      };
      _created = false;
      widget.onPreviewChanged?.call(_preview!);
    });
  }

  Future<void> _create() async {
    if (!widget.canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tiene permiso para crear cartillas')),
      );
      return;
    }
    final preview = _preview;
    if (preview == null) return;
    setState(() => _saving = true);
    try {
      final formation = widget.kind == CrtSpecialFormKind.formacion;
      final otras = widget.kind == CrtSpecialFormKind.otras;
      final data = switch (widget.kind) {
        CrtSpecialFormKind.formacion => _formationData().toJson(),
        CrtSpecialFormKind.conductor => _conductorData().toJson(),
        CrtSpecialFormKind.otras => _otrasData().toJson(),
      };
      final result = await InsApi().registrarCartilla(
        contenido: preview,
        causa: formation
            ? _tipoFormacion.causa
            : (otras ? _c('causa').text.trim() : 'REGISTRO VEHICULAR'),
        tipo: formation
            ? 'FORMACION'
            : (otras ? 'OTRAS_CARTILLAS' : 'CONDUCTOR'),
        subtipo: formation
            ? _tipoFormacion.name
            : (otras ? 'NOVEDADES_EAS' : _opcionConductor.code),
        datos: data,
      );
      if (!mounted) return;
      setState(() => _created = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(_preview!),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        final nombre = widget.user?.nombreCompleto ?? '';
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => BadgeUnlockDialog(
            insignia: insignia,
            totalCartillas: result.totalCartillasGeneradas,
            nombreUsuario: nombre,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear la cartilla: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  FormacionData _formationData() => FormacionData(
    tipo: _tipoFormacion,
    distrito: _c('distrito').text.trim(),
    circuito: _c('circuito').text.trim(),
    direccion: _c('direccion').text.trim(),
    horario: _c('horario').text.trim(),
    fechaHora: _dateTime,
    novedades: _c('novedades').text,
    radiooperadores: int.tryParse(_c('radiooperadores').text) ?? 0,
    acmOperativos: int.tryParse(_c('operativos').text) ?? 0,
    personalPolicial: _split(_c('policias').text),
    moviles: _movilesActivos ? _split(_c('moviles').text) : [],
    reportantes: [widget.user?.nombreCompleto ?? ''],
    jefe: widget.jefe.isEmpty ? 'Jefe de Control Municipal' : widget.jefe,
  );

  ConductorData _conductorData() => ConductorData(
    conductorId: _conductorId,
    conductor: _c('conductor').text,
    cedulaUltimos4: _c('cedula4').text,
    opcion: _opcionConductor,
    lugar: _c('lugar').text,
    movilId: _movilId,
    disco: _c('disco').text,
    fechaHora: _dateTime,
    combustible: _combustible,
    kilometraje: int.parse(_c('kilometraje').text),
    servicio: _c('servicio').text,
    horario: _c('horarioConductor').text,
    encargadoId: _encargadoId,
    encargado: _c('encargado').text,
    observaciones: _c('observaciones').text,
  );

  OtrasCartillasData _otrasData() => OtrasCartillasData(
    distrito: _c('distrito').text.trim(),
    circuito: _c('circuito').text.trim(),
    direccion: _c('direccion').text.trim(),
    horario: _c('horario').text.trim(),
    fechaHora: _dateTime,
    causa: _c('causa').text.trim(),
    novedad: _c('novedad').text,
    reportantes: [widget.user?.nombreCompleto ?? ''],
    jefe: widget.jefe.isEmpty ? 'Jefe de Control Municipal' : widget.jefe,
  );

  void _refreshAutomaticTime() {
    _dateTime = DateTime.now();
    final jornada = CrtCatalog.jornadaActual(_dateTime);
    _jornada = switch (jornada.name) {
      'matutina' => 'Matutina',
      'vespertina' => 'Vespertina',
      _ => 'Amanecida',
    };
    final horario = CrtCatalog.horarioActual(_dateTime);
    final controller = _controllers['horario'];
    if (controller != null) controller.text = horario;
  }

  List<String> _split(String value) => value
      .split(RegExp(r'[,;\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  void _invalidate() {
    _preview = null;
    _created = false;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _preview!));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Texto copiado')));
    }
  }

  Future<void> _share() => Share.share(_preview!);
  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
  );
  Widget _title(IconData icon, String text) => Row(
    children: [
      Icon(icon, color: const Color(0xFF1D3F73)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D3F73),
          ),
        ),
      ),
    ],
  );
  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

extension _SeparatedWidgets on List<Widget> {
  List<Widget> separatedBy(Widget separator) {
    if (isEmpty) return this;
    return [
      for (var i = 0; i < length; i++) ...[if (i > 0) separator, this[i]],
    ];
  }
}
