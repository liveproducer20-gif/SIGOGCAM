import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import '../ins/ins_api.dart';
import '../ins/ins_mdl.dart';
import 'mdl/crt_enums.dart';
import 'mdl/crt_models.dart';
import 'svc/crt_api.dart';
import 'svc/crt_catalog.dart';
import 'svc/crt_text_generator.dart';

class CrtHomeScr extends StatefulWidget {
  final AppUser? user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  const CrtHomeScr({
    super.key,
    this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
  });

  @override
  State<CrtHomeScr> createState() => _CrtHomeScrState();
}

class _CrtHomeScrState extends State<CrtHomeScr> {
  final controllers = <String, TextEditingController>{};
  final formKey = GlobalKey<FormState>();

  TipoModuloCartilla modulo = TipoModuloCartilla.eas;
  TipoCartilla tipo = CrtCatalog.easTypes.first;
  CrtEasStation eas = CrtCatalog.easStations.last;
  String movil = '187';
  RolMovil rolMovil = RolMovil.jp;
  bool guardando = false;

  final crtApi = CrtApi();

  bool _desaCargando = false;
  int _desaStep = 0;
  String _desaJp = '';
  String _desaAux = '';
  String _desaMovil = '';
  String _desaCp = '';
  String _desaCpGuardado = '';
  int? _desaPoliciaId;
  String _desaPoliciaNombre = '';
  String _desaDireccion = '';
  bool _desaAgresivo = false;
  bool _desaColaboracion = false;
  List<Map<String, dynamic>> _servidoresPoliciales = [];
  List<Map<String, dynamic>> _direcciones = [];
  final _desaCpCtrl = TextEditingController();
  final _desaAuxCtrl = TextEditingController();
  final _desaDireccionCtrl = TextEditingController();

  CrtModuleConfig get config => CrtCatalog.configFor(modulo);
  List<CrtFieldConfig> get activeFields => CrtCatalog.fieldsFor(modulo, tipo);

  bool get _isDesalojoFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.desalojoVendedores;

  @override
  void initState() {
    super.initState();
    _syncFields();
    movil = _moviles.first.movil;
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    _desaCpCtrl.dispose();
    _desaAuxCtrl.dispose();
    _desaDireccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1050;
    final preview = _buildText();

    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: TopBarWdg(
        ttl: 'Cartillas',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTtlWdg(
                ttl: 'Generador de cartillas',
                sub: 'Seleccione el modulo operativo y complete solo los campos requeridos.',
              ),
              const SizedBox(height: 26),
              if (_isDesalojoFlow)
                _buildDesalojoContent(isWide, preview)
              else if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _formPanel()),
                    const SizedBox(width: 20),
                    Expanded(child: _previewPanel(preview)),
                  ],
                )
              else
                Column(
                  children: [
                    _formPanel(),
                    const SizedBox(height: 20),
                    _previewPanel(preview),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesalojoContent(bool isWide, String preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDesalojoSelector(),
        const SizedBox(height: 20),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDesalojoWizard()),
              const SizedBox(width: 20),
              Expanded(child: _previewPanel(preview)),
            ],
          )
        else
          Column(
            children: [
              _buildDesalojoWizard(),
              const SizedBox(height: 20),
              _previewPanel(preview),
            ],
          ),
      ],
    );
  }

  Widget _buildDesalojoSelector() {
    return _Panel(
      child: Column(
        children: [
          _Drop<CrtEasStation>(
            value: eas,
            label: 'EAS',
            icon: Icons.location_city_outlined,
            items: CrtCatalog.easStations,
            itemText: (value) => '${value.codigo} - ${value.nombre}',
            onChanged: (value) {
              setState(() {
                eas = value;
                _desaStep = 0;
                _desaMovil = '';
                _desaDireccion = '';
                _direcciones = [];
              });
            },
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.place_outlined,
            text: '${eas.nombre}: ${eas.direccion}',
          ),
        ],
      ),
    );
  }

  Widget _buildDesalojoWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Desalojo de vendedores autónomos no regularizados',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_desaCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDesalojoStepContent(),
          const SizedBox(height: 24),
          _buildDesalojoNavButtons(),
        ],
      ),
    );
  }

  Widget _buildDesalojoStepContent() {
    if (_desaCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_desaStep) {
      case 0:
        return _StepCard(
          step: 1,
          title: 'Datos del personal',
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.user?.nombreCompleto ?? '',
                decoration: const InputDecoration(
                  labelText: 'Nombre del agente JP',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _desaJp = value,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _desaAuxCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aux.: (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _desaAux = value,
              ),
            ],
          ),
        );
      case 1:
        final items = _moviles.map((m) => m.movil).toList();
        final value = _desaMovil.isNotEmpty && items.contains(_desaMovil)
            ? _desaMovil
            : items.first;
        return _StepCard(
          step: 2,
          title: 'Seleccione móvil',
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Móvil asignado',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
            ),
            items: items
                .map((m) => DropdownMenuItem(value: m, child: Text('MOVIL $m')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _desaMovil = value);
            },
          ),
        );
      case 2:
        return _StepCard(
          step: 3,
          title: 'Datos del conductor',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _desaCpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del conductor CP',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _desaCp = value,
              ),
              if (_desaCpGuardado.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Último registro: $_desaCpGuardado',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThm.secClr,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      case 3:
        final items = _servidoresPoliciales;
        final idx = items.indexWhere(
            (s) => s['id'] == _desaPoliciaId);
        final value = idx >= 0 ? items[idx] : items.firstOrNull;
        return _StepCard(
          step: 4,
          title: 'Seleccione servidor policial',
          child: DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servidor policial',
              prefixIcon: Icon(Icons.local_police_outlined),
              border: OutlineInputBorder(),
            ),
            items: items.map((s) {
              final nombre = s['nombre'] as String? ?? '';
              final grado = s['grado'] as String? ?? '';
              final label = grado.isNotEmpty ? '$grado $nombre' : nombre;
              return DropdownMenuItem(
                value: s,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _desaPoliciaId = value['id'] as int?;
                  _desaPoliciaNombre = value['nombre'] as String? ?? '';
                });
              }
            },
          ),
        );
      case 4:
    final items = _direcciones;
    Map<String, dynamic>? value;
    if (items.isNotEmpty && _desaDireccion.isNotEmpty) {
      try {
        value = items.firstWhere((d) => d['direccion'] == _desaDireccion);
      } catch (_) {
        value = null;
      }
    }
    final tieneOtro = _desaDireccion.isNotEmpty &&
        items.isNotEmpty &&
        !items.any((d) => d['direccion'] == _desaDireccion);
    return _StepCard(
      step: 5,
      title: 'Dirección',
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: value,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...items.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d['direccion'] as String? ?? ''),
                      )),
                  const DropdownMenuItem(
                    value: {'id': -1, 'direccion': 'Otro'},
                    child: Text('Otro (agregar nueva)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'] as int?;
                  if (id == -1) {
                    setState(() {
                      _desaDireccion = '';
                      _desaDireccionCtrl.clear();
                    });
                  } else {
                    setState(() {
                      _desaDireccion = value['direccion'] as String? ?? '';
                    });
                  }
                },
              ),
              if (_desaDireccion.isEmpty && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _desaDireccionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _desaDireccion = value,
                  ),
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _desaDireccionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _desaDireccion = value,
                  ),
                ),
              if (tieneOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _desaDireccionCtrl..text = _desaDireccion,
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _desaDireccion = value,
                  ),
                ),
            ],
          ),
        );
      case 5:
        return _StepCard(
          step: 6,
          title: 'Causa',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Desalojo de vendedores autónomos no regularizados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThm.txtClr,
              ),
            ),
          ),
        );
      case 6:
        return _StepCard(
          step: 7,
          title: '¿Los comerciantes se pusieron agresivos?',
          child: Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  selected: _desaAgresivo,
                  label: 'Sí',
                  icon: Icons.warning_amber_rounded,
                  onTap: () => setState(() => _desaAgresivo = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceTile(
                  selected: !_desaAgresivo,
                  label: 'No',
                  icon: Icons.check_circle_outline,
                  onTap: () => setState(() => _desaAgresivo = false),
                ),
              ),
            ],
          ),
        );
      case 7:
        return _StepCard(
          step: 8,
          title: '¿Necesita colaboración para operativo?',
          child: Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  selected: _desaColaboracion,
                  label: 'Sí',
                  icon: Icons.groups_outlined,
                  onTap: () => setState(() => _desaColaboracion = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceTile(
                  selected: !_desaColaboracion,
                  label: 'No',
                  icon: Icons.do_not_disturb_alt_outlined,
                  onTap: () => setState(() => _desaColaboracion = false),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDesalojoNavButtons() {
    final isLast = _desaStep >= _desaLastStep;
    final isFirst = _desaStep == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () => setState(() => _desaStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: guardando ? null : () => _generarDesalojo(),
            icon: guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(guardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _desaIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  int get _easDbId => CrtCatalog.easStations.indexOf(eas) + 1;

  int get _desaLastStep {
    if (_desaAgresivo) return 7;
    return 6;
  }

  void _desaIrSiguiente() {
    if (_desaStep == 2 && _desaCp.trim().isNotEmpty) {
      crtApi.saveCp(_desaCp.trim());
    }
    if (_desaStep == 3 && _desaPoliciaId != null) {
      crtApi.savePolicia(_desaPoliciaId);
    }
    if (_desaStep == 4 && _desaDireccion.isNotEmpty) {
      final exists = _direcciones
          .any((d) => d['direccion'] == _desaDireccion);
      if (!exists) {
        crtApi.crearDireccion(_easDbId, _desaDireccion);
      }
    }
    setState(() => _desaStep++);
  }

  Future<void> _generarDesalojo() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      if (_desaCp.trim().isNotEmpty) {
        await crtApi.saveCp(_desaCp.trim());
      }
      if (_desaPoliciaId != null) {
        await crtApi.savePolicia(_desaPoliciaId);
      }

      final value = _buildText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada. Total: ${result.totalCartillasGeneradas}',
          ),
        ),
      );

      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) await _showBadgeDialog(insignia);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _cargarDatosDesalojo() async {
    setState(() => _desaCargando = true);
    try {
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(),
        _cargarDirecciones(),
      ]);

      final cpGuardado = results[0] as String?;
      final policiaData = results[1] as Map<String, dynamic>?;
      final servidores = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _desaCpGuardado = cpGuardado ?? '';
        if (_desaCpGuardado.isNotEmpty) {
          _desaCpCtrl.text = _desaCpGuardado;
          _desaCp = _desaCpGuardado;
        }
        _servidoresPoliciales = servidores;
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _desaPoliciaId = pid;
          _desaPoliciaNombre =
              policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
      // Silently fail on temp data load
    } finally {
      if (mounted) setState(() => _desaCargando = false);
    }
  }

  Future<List<Map<String, dynamic>>> _cargarDirecciones() async {
    try {
      final easIdx = CrtCatalog.easStations.indexOf(eas);
      final direcciones = await crtApi.getDirecciones(easIdx + 1);
      if (mounted) {
        setState(() => _direcciones = direcciones);
      }
      return direcciones;
    } catch (_) {
      return [];
    }
  }

  Widget _formPanel() {
    return _Panel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelTitle(
              icon: Icons.tune_outlined,
              title: 'Configuración',
            ),
            const SizedBox(height: 18),
            _Drop<TipoModuloCartilla>(
              value: modulo,
              label: 'Modulo de cartilla',
              icon: Icons.dashboard_customize_outlined,
              items: TipoModuloCartilla.values,
              itemText: (value) => value.label,
              onChanged: (value) {
                setState(() {
                  modulo = value;
                  final tipos = CrtCatalog.configFor(modulo).tipos;
                  if (!tipos.contains(tipo)) tipo = tipos.first;
                  if (modulo == TipoModuloCartilla.eas) {
                    movil = _moviles.first.movil;
                  }
                  _syncFields();
                });
              },
            ),
            const SizedBox(height: 14),
            _Drop<TipoCartilla>(
              value: tipo,
              label: 'Tipo de cartilla',
              icon: Icons.description_outlined,
              items: config.tipos,
              itemText: (value) => value.label,
              onChanged: (value) => setState(() {
                tipo = value;
                _syncFields();
              }),
            ),
            if (modulo == TipoModuloCartilla.eas) ...[
              const SizedBox(height: 14),
              _Drop<CrtEasStation>(
                value: eas,
                label: 'EAS',
                icon: Icons.location_city_outlined,
                items: CrtCatalog.easStations,
                itemText: (value) => '${value.codigo} - ${value.nombre}',
                onChanged: (value) {
                  setState(() {
                    eas = value;
                    movil = _moviles.first.movil;
                  });
                },
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.place_outlined,
                text: '${eas.nombre}: ${eas.direccion}',
              ),
              const SizedBox(height: 14),
              _Drop<String>(
                value: movil,
                label: 'Móvil asignado',
                icon: Icons.directions_car_outlined,
                items: _moviles.map((item) => item.movil).toList(),
                itemText: (value) => 'Móvil $value',
                onChanged: (value) => setState(() => movil = value),
              ),
              const SizedBox(height: 14),
              _Drop<RolMovil>(
                value: rolMovil,
                label: 'Que rol cumple usted en el movil',
                icon: Icons.assignment_ind_outlined,
                items: RolMovil.values,
                itemText: (value) => value.label,
                onChanged: (value) => setState(() => rolMovil = value),
              ),
            ],
            const SizedBox(height: 14),
            for (final field in activeFields) ...[
              _Field(
                controller: _controller(field.key),
                label: field.label,
                icon: _iconFor(field.key),
                minLines: field.minLines,
                required: field.required,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
            ],
            _Field(
              controller: _controller('reporta'),
              label: 'Persona que reporta',
              icon: Icons.badge_outlined,
              required: modulo != TipoModuloCartilla.eas,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPanel(String value) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _PanelTitle(
                  icon: Icons.preview_outlined,
                  title: 'Vista previa',
                ),
              ),
              FilledButton.icon(
                onPressed: guardando ? null : () => _generar(value),
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.copy_outlined),
                label: Text(guardando ? 'Guardando' : 'Generar'),
              ),
            ],
          ),
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
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppThm.txtClr,
                height: 1.45,
                fontFamily: 'monospace',
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generar(String value) async {
    if (!formKey.currentState!.validate()) return;
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada. Total: ${result.totalCartillasGeneradas}',
          ),
        ),
      );

      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) await _showBadgeDialog(insignia);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _showBadgeDialog(InsigniaDesbloqueadaMdl insignia) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva insignia desbloqueada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppThm.accClr,
              child: Text(
                insignia.icono.isEmpty ? 'OK' : insignia.icono,
                style: const TextStyle(
                  color: AppThm.priClr,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              insignia.titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppThm.priClr,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(insignia.mensaje, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String _buildText() {
    if (_isDesalojoFlow) {
      return _buildDesalojoText();
    }
    final now = DateTime.now();
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: modulo,
        tipo: tipo,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: modulo == TipoModuloCartilla.eas ? eas : null,
        movil: modulo == TipoModuloCartilla.eas ? movil : null,
        rolMovil: modulo == TipoModuloCartilla.eas ? rolMovil : null,
        dotacion: modulo == TipoModuloCartilla.eas
            ? _dotacionSeleccionada.integrantes
            : const {},
        values: {
          for (final entry in controllers.entries) entry.key: entry.value.text,
        },
      ),
    );
  }

  String _buildDesalojoText() {
    final now = DateTime.now();
    final movilValue = _desaMovil.isNotEmpty ? _desaMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.desalojoVendedores,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        movil: movilValue,
        values: {
          '_desa_jp': _desaJp.isNotEmpty
              ? _desaJp
              : (widget.user?.nombreCompleto ?? ''),
          '_desa_aux': _desaAux,
          '_desa_movil': movilValue,
          '_desa_cp': _desaCp,
          '_desa_policia': _desaPoliciaNombre,
          '_desa_direccion': _desaDireccion,
          '_desa_agresivo': _desaAgresivo ? 'si' : 'no',
          '_desa_colaboracion': _desaColaboracion ? 'si' : 'no',
        },
      ),
    );
  }

  List<CrtMovilDotacion> get _moviles {
    return CrtCatalog.dotacionEas[eas.nombre] ??
        [
          const CrtMovilDotacion(
            movil: 'N/D',
            integrantes: {
              RolMovil.jp: '[JP asignado]',
              RolMovil.conductor: '[Conductor asignado]',
              RolMovil.auxiliar: '[Auxiliar asignado]',
            },
          ),
        ];
  }

  CrtMovilDotacion get _dotacionSeleccionada {
    return _moviles.firstWhere(
      (item) => item.movil == movil,
      orElse: () => _moviles.first,
    );
  }

  void _syncFields() {
    final keys = {
      ...activeFields.map((field) => field.key),
      'reporta',
    };
    for (final key in keys) {
      controllers.putIfAbsent(key, () => TextEditingController());
    }

    if (controllers['reporta']!.text.isEmpty &&
        widget.user?.nombreCompleto.isNotEmpty == true) {
      controllers['reporta']!.text = widget.user!.nombreCompleto;
    }

    if (_isDesalojoFlow) {
      _cargarDatosDesalojo();
    }
  }

  TextEditingController _controller(String key) {
    return controllers.putIfAbsent(key, () => TextEditingController());
  }

  IconData _iconFor(String key) {
    if (key.contains('movil') || key == 'vehiculo') return Icons.directions_car_outlined;
    if (key.contains('personal') || key.contains('agente')) return Icons.groups_outlined;
    if (key.contains('punto') || key.contains('sector') || key.contains('lugar')) {
      return Icons.place_outlined;
    }
    if (key.contains('novedad') || key.contains('procedimiento')) {
      return Icons.notes_outlined;
    }
    return Icons.edit_note_outlined;
  }

  String _fmtHora(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _fmtFecha(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PanelTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppThm.secClr),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppThm.priClr,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppThm.secClr),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppThm.txtClr,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Drop<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final List<T> items;
  final String Function(T value)? itemText;
  final ValueChanged<T> onChanged;

  const _Drop({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemText?.call(item) ?? item.toString()),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int minLines;
  final VoidCallback? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = true,
    this.minLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 8,
      onChanged: (_) => onChanged?.call(),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obligatorio';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppThm.accClr,
              child: Text(
                '$step',
                style: const TextStyle(
                  color: AppThm.priClr,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppThm.priClr,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppThm.accClr : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppThm.secClr : Colors.black26,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? AppThm.priClr : AppThm.txtClr,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppThm.priClr : AppThm.txtClr,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
