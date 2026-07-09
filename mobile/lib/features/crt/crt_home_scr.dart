import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import '../ins/ins_api.dart';
import '../ins/ins_badge_dlg.dart';
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
  TipoCartilla tipo = TipoCartilla.puntoMartillo;
  CrtEasStation eas = CrtCatalog.easStations.last;
  String movil = '187';
  RolMovil rolMovil = RolMovil.jp;
  bool guardando = false;

  final crtApi = CrtApi();

  bool _desaCargando = false;
  int _desaSection = 0;
  String _desaJp = '';
  String _desaAux = '';
  bool get _hasPolicia =>
      _desaPoliciaOtro || _desaPoliciaId != null;
  String _desaMovil = '';
  String _desaCp = '';
  String _desaCpGuardado = '';
  int? _desaPoliciaId;
  String _desaPoliciaNombre = '';
  bool _desaPoliciaOtro = false;
  final _desaPoliciaCtrl = TextEditingController();
  final _desaJpCtrl = TextEditingController();
  String _desaDireccion = '';
  bool _desaDireccionOtro = false;
  bool _desaAgresivo = false;
  bool _desaColaboracion = false;
  List<Map<String, dynamic>> _servidoresPoliciales = [];
  List<Map<String, dynamic>> _direcciones = [];
  final _desaCpCtrl = TextEditingController();
  final _desaAuxCtrl = TextEditingController();
  final _desaDireccionCtrl = TextEditingController();
  final _ezDetalleCtrl = TextEditingController();

  bool _rtCargando = false;
  int _rtSection = 0;
  String _rtJp = '';
  String _rtMovil = '';
  String _rtCp = '';
  String _rtCpGuardado = '';
  int? _rtPoliciaId;
  String _rtPoliciaNombre = '';
  bool _rtPoliciaOtro = false;
  final _rtPoliciaCtrl = TextEditingController();
  final _rtJpCtrl = TextEditingController();
  final _rtCpCtrl = TextEditingController();
  String _rtDireccion = '';
  bool _rtDireccionOtro = false;
  List<Map<String, dynamic>> _rtServidoresPoliciales = [];
  List<Map<String, dynamic>> _rtDirecciones = [];
  String _rtAux1 = '';
  final _rtAux1Ctrl = TextEditingController();
  String _rtAux2 = '';
  final _rtAux2Ctrl = TextEditingController();
  String _rtActividad = '';
  final _rtActividadCtrl = TextEditingController();
  String _rtElementos = '';
  final _rtElementosCtrl = TextEditingController();
  String _rtCantidad = '';
  final _rtCantidadCtrl = TextEditingController();
  bool _rtGuardando = false;

  bool _colCargando = false;
  int _colSection = 0;
  String _colJp = '';
  String _colMovil = '';
  String _colCp = '';
  String _colCpGuardado = '';
  int? _colPoliciaId;
  String _colPoliciaNombre = '';
  bool _colPoliciaOtro = false;
  final _colPoliciaCtrl = TextEditingController();
  final _colJpCtrl = TextEditingController();
  final _colCpCtrl = TextEditingController();
  String _colDireccion = '';
  bool _colDireccionOtro = false;
  List<Map<String, dynamic>> _colServidoresPoliciales = [];
  List<Map<String, dynamic>> _colDirecciones = [];
  String _colAux1 = '';
  final _colAux1Ctrl = TextEditingController();
  String _colAux2 = '';
  final _colAux2Ctrl = TextEditingController();
  String _colSubtype = 'entidad';
  String _colEntidad = '';
  String _colMotivo = '';
  String _colTipoAccidente = '';
  String _colNumHeridos = '';
  String _colNombresHeridos = '';
  bool _colHuboFallecidos = false;
  String _colNumFallecidos = '';
  String _colNombresFallecidos = '';
  String _colCriminalistica = 'No intervino';
  String _colCriminalisticaNombre = '';
  String _colAtm = 'No estuvo presente';
  String _colAtmNombre = '';
  String _colAtmMovil = '';
  String _colAmbulancia = 'No estuvo presente';
  String _colAmbulanciaNombre = '';
  String _colPlacas = '';
  String _colConductores = '';
  String _colDanios = '';
  bool _colCierreVial = false;
  String _colCierreVialDesc = '';
  bool _colTraslado = false;
  String _colCasaSalud = '';
  bool _colGuardando = false;

  CrtModuleConfig get config => CrtCatalog.configFor(modulo);
  List<CrtFieldConfig> get activeFields => CrtCatalog.fieldsFor(modulo, tipo);

  bool get _isDesalojoFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.desalojoVendedores;

  bool get _isPuntoMartilloFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.puntoMartillo;

  bool get _isRondasDisuasivasFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.rondasDisuasivas;

  bool get _isRetiroTemporalFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.retiroTemporal;

  bool get _isColaboracionFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.colaboracionEntidades;

  bool get _isEasCustomCardFlow {
    if (modulo != TipoModuloCartilla.eas) return false;
    return [
      TipoCartilla.requerimiento,
      TipoCartilla.colaboracionEventos,
      TipoCartilla.permisoAusentismo,
    ].contains(tipo);
  }

  @override
  void initState() {
    super.initState();
    _syncFields();
    movil = _moviles.first.movil;
    _autoFillByRole();
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    _desaCpCtrl.dispose();
    _desaAuxCtrl.dispose();
    _desaJpCtrl.dispose();
    _desaPoliciaCtrl.dispose();
    _desaDireccionCtrl.dispose();
    _ezDetalleCtrl.dispose();
    _rtPoliciaCtrl.dispose();
    _rtJpCtrl.dispose();
    _rtCpCtrl.dispose();
    _rtAux1Ctrl.dispose();
    _rtAux2Ctrl.dispose();
    _rtActividadCtrl.dispose();
    _rtElementosCtrl.dispose();
    _rtCantidadCtrl.dispose();
    _colPoliciaCtrl.dispose();
    _colJpCtrl.dispose();
    _colCpCtrl.dispose();
    _colAux1Ctrl.dispose();
    _colAux2Ctrl.dispose();
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
              if (modulo == TipoModuloCartilla.eas)
                _buildEasLayout(isWide, preview)
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

  Widget _buildEasLayout(bool isWide, String preview) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEasConfigPanel(),
        const SizedBox(height: 20),
        if (_isDesalojoFlow) _buildDesalojoWizard()
        else if (_isPuntoMartilloFlow) _buildPuntoMartilloForm()
        else if (_isRondasDisuasivasFlow) _buildRondasDisuasivasForm()
        else if (_isRetiroTemporalFlow) _buildRetiroTemporalWizard()
        else if (_isColaboracionFlow) _buildColaboracionWizard()
        else if (_isEasCustomCardFlow) _buildEasCustomForm()
        else _formPanel(),
      ],
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          const SizedBox(height: 20),
          _previewPanel(preview),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 20),
        Expanded(child: _previewPanel(preview)),
      ],
    );
  }

  Widget _buildEasConfigPanel() {
    return _Panel(
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
          _buildEasTypeButtons(),
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
                _desaSection = 0;
                _desaMovil = '';
                _desaDireccion = '';
                _desaDireccionOtro = false;
                _direcciones = [];
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
            onChanged: (value) {
              setState(() {
                rolMovil = value;
                _autoFillByRole();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEasTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de cartilla:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppThm.priClr,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _EasTypeCard(
              icon: Icons.storefront_outlined,
              title: 'Desalojo de vendedores\nautónomos no regularizados',
              selected: tipo == TipoCartilla.desalojoVendedores,
              onTap: () => setState(() {
                tipo = TipoCartilla.desalojoVendedores;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.gavel_outlined,
              title: 'Punto martillo',
              selected: tipo == TipoCartilla.puntoMartillo,
              onTap: () => setState(() {
                tipo = TipoCartilla.puntoMartillo;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.directions_walk_outlined,
              title: 'Rondas disuasivas',
              selected: tipo == TipoCartilla.rondasDisuasivas,
              onTap: () => setState(() {
                tipo = TipoCartilla.rondasDisuasivas;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.backup_outlined,
              title: 'Retiro temporal',
              selected: tipo == TipoCartilla.retiroTemporal,
              onTap: () => setState(() {
                tipo = TipoCartilla.retiroTemporal;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.receipt_long_outlined,
              title: 'Requerimiento',
              selected: tipo == TipoCartilla.requerimiento,
              onTap: () => setState(() {
                tipo = TipoCartilla.requerimiento;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.groups_outlined,
              title: 'Colaboración con\notras entidades',
              selected: tipo == TipoCartilla.colaboracionEntidades,
              onTap: () => setState(() {
                tipo = TipoCartilla.colaboracionEntidades;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.people_outlined,
              title: 'Colaboración\nciudadana',
              selected: tipo == TipoCartilla.colaboracionEventos,
              onTap: () => setState(() {
                tipo = TipoCartilla.colaboracionEventos;
                _syncFields();
              }),
            ),
            _EasTypeCard(
              icon: Icons.logout_outlined,
              title: 'Permiso de\nausentismo',
              selected: tipo == TipoCartilla.permisoAusentismo,
              onTap: () => setState(() {
                tipo = TipoCartilla.permisoAusentismo;
                _syncFields();
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPuntoMartilloForm() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_outlined, color: AppThm.secClr),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Punto martillo',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _desaCpCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del conductor CP',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaCp = value;
              setState(() {});
            },
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _desaJpCtrl,
            decoration: InputDecoration(
              labelText: _hasPolicia ? 'Aux.:' : 'Nombre del agente JP',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaJp = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desaDireccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaDireccion = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          _buildPoliciaSection(),
          if (_hasPolicia) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _desaAuxCtrl,
              decoration: const InputDecoration(
                labelText: 'Aux.: (opcional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _desaAux = value;
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRondasDisuasivasForm() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk_outlined, color: AppThm.secClr),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rondas disuasivas',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _desaCpCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del conductor CP',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaCp = value;
              setState(() {});
            },
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _desaJpCtrl,
            decoration: InputDecoration(
              labelText: _hasPolicia ? 'Aux.:' : 'Nombre del agente JP',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaJp = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desaDireccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaDireccion = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          _buildPoliciaSection(),
          if (_hasPolicia) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _desaAuxCtrl,
              decoration: const InputDecoration(
                labelText: 'Aux.: (opcional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _desaAux = value;
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEasCustomForm() {
    final titulo = switch (tipo) {
      TipoCartilla.retiroTemporal => 'Retiro temporal',
      TipoCartilla.requerimiento => 'Requerimiento',
      TipoCartilla.colaboracionEntidades => 'Colaboración con otras entidades',
      TipoCartilla.colaboracionEventos => 'Colaboración ciudadana',
      TipoCartilla.permisoAusentismo => 'Permiso de ausentismo',
      _ => '',
    };
    final icono = switch (tipo) {
      TipoCartilla.retiroTemporal => Icons.backup_outlined,
      TipoCartilla.requerimiento => Icons.receipt_long_outlined,
      TipoCartilla.colaboracionEntidades => Icons.groups_outlined,
      TipoCartilla.colaboracionEventos => Icons.people_outlined,
      TipoCartilla.permisoAusentismo => Icons.logout_outlined,
      _ => Icons.article_outlined,
    };
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppThm.secClr),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _desaCpCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre del conductor CP',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaCp = value;
              setState(() {});
            },
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _desaJpCtrl,
            decoration: InputDecoration(
              labelText: _hasPolicia ? 'Aux.:' : 'Nombre del agente JP',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaJp = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _desaDireccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _desaDireccion = value;
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          _buildPoliciaSection(),
          if (_hasPolicia) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _desaAuxCtrl,
              decoration: const InputDecoration(
                labelText: 'Aux.: (opcional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _desaAux = value;
                setState(() {});
              },
            ),
          ],
          if (tipo == TipoCartilla.colaboracionEntidades) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _ezDetalleCtrl,
              decoration: const InputDecoration(
                labelText:
                    'Detalle (accidente ocurrido, actividades realizadas, etc.)',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
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

    if (_desaSection == 0) {
      return _buildSection1();
    }
    return _buildSection2();
  }

  Widget _buildSection1() {
    final movilItems = _moviles.map((m) => m.movil).toList();
    final movilValue = _desaMovil.isNotEmpty && movilItems.contains(_desaMovil)
        ? _desaMovil
        : movilItems.first;
    return Column(
      children: [
        _StepCard(
          step: 1,
          title: 'Datos del personal',
          child: Column(
            children: [
              TextFormField(
                controller: _desaJpCtrl,
                decoration: InputDecoration(
                  labelText: _hasPolicia ? 'Aux.:' : 'Nombre del agente JP',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _desaJp = value;
                  setState(() {});
                },
              ),
              if (!_hasPolicia) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _desaAuxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Aux.: (opcional)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _desaAux = value;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 2,
          title: 'Seleccione móvil',
          child: DropdownButtonFormField<String>(
            initialValue: movilValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Móvil asignado',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
            ),
            items: movilItems
                .map((m) => DropdownMenuItem(value: m, child: Text('MOVIL $m')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _desaMovil = value);
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
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
                onChanged: (value) {
                  _desaCp = value;
                  setState(() {});
                },
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
        ),
        const SizedBox(height: 20),
        _buildPoliciaSection(),
      ],
    );
  }

  Widget _buildPoliciaSection() {
    final sinPolicia = <String, dynamic>{'id': 0, 'nombre': 'Sin servidor policial'};
    final otto = <String, dynamic>{'id': -1, 'nombre': 'Otro'};
    final items = [sinPolicia, ..._servidoresPoliciales, otto];

    Map<String, dynamic>? selected;
    if (_desaPoliciaOtro) {
      selected = otto;
    } else if (_desaPoliciaId != null && _desaPoliciaId! > 0) {
      final idx = _servidoresPoliciales.indexWhere((s) => s['id'] == _desaPoliciaId);
      if (idx >= 0) {
        selected = _servidoresPoliciales[idx];
      } else {
        selected = sinPolicia;
      }
    } else {
      selected = sinPolicia;
    }

    return _StepCard(
      step: 4,
      title: 'Seleccione servidor policial',
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servidor policial',
              prefixIcon: Icon(Icons.local_police_outlined),
              border: OutlineInputBorder(),
            ),
            items: items.map((s) {
              final nombre = s['nombre'] as String? ?? '';
              return DropdownMenuItem(value: s, child: Text(nombre));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              final id = value['id'] as int?;
              setState(() {
                if (id == -1) {
                  _desaPoliciaOtro = true;
                  _desaPoliciaId = null;
                  _desaPoliciaNombre = '';
                } else if (id == 0) {
                  _desaPoliciaOtro = false;
                  _desaPoliciaId = null;
                  _desaPoliciaNombre = '';
                } else {
                  _desaPoliciaOtro = false;
                  _desaPoliciaId = id;
                  _desaPoliciaNombre = value['nombre'] as String? ?? '';
                }
              });
            },
          ),
          if (_desaPoliciaOtro)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextField(
                controller: _desaPoliciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nuevo servidor policial',
                  prefixIcon: Icon(Icons.person_add_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _desaPoliciaNombre = value;
                  setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    final items = _direcciones;
    final ottoDir = <String, dynamic>{'id': -1, 'direccion': 'Otro'};
    final dirOptions = [if (items.isNotEmpty) ...items, ottoDir];

    Map<String, dynamic>? dirValue;
    if (_desaDireccionOtro) {
      dirValue = ottoDir;
    } else if (_desaDireccion.isNotEmpty && items.isNotEmpty) {
      try {
        dirValue = items.firstWhere((d) => d['direccion'] == _desaDireccion);
      } catch (_) {
        dirValue = null;
      }
    }

    return Column(
      children: [
        _StepCard(
          step: 5,
          title: 'Dirección',
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: dirValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                items: dirOptions.map((d) {
                  final nombre = d['direccion'] as String? ?? '';
                  return DropdownMenuItem(value: d, child: Text(nombre));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'] as int?;
                  setState(() {
                    if (id == -1) {
                      _desaDireccionOtro = true;
                      _desaDireccion = '';
                      _desaDireccionCtrl.clear();
                    } else {
                      _desaDireccionOtro = false;
                      _desaDireccion = value['direccion'] as String? ?? '';
                    }
                  });
                },
              ),
              if (_desaDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _desaDireccionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _desaDireccion = value;
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
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
        ),
        const SizedBox(height: 20),
        _StepCard(
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
        ),
        if (_desaAgresivo) ...[
          const SizedBox(height: 20),
          _StepCard(
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
          ),
        ],
      ],
    );
  }

  Widget _buildDesalojoNavButtons() {
    final isLast = _desaSection == 1;
    final isFirst = _desaSection == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () => setState(() => _desaSection--),
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

  void _desaIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_desaCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_desaCp.trim()).catchError((_) {}));
    }
    if (_desaPoliciaOtro && _desaPoliciaNombre.trim().isNotEmpty) {
      saves.add(crtApi
          .crearServidorPolicial(_easDbId, _desaPoliciaNombre.trim())
          .catchError((_) {}));
    } else if (_desaPoliciaId != null) {
      saves.add(crtApi.savePolicia(_desaPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_desaPoliciaOtro && _desaPoliciaNombre.trim().isNotEmpty) {
      _desaPoliciaOtro = false;
      _desaPoliciaCtrl.clear();
      try {
        _servidoresPoliciales = await crtApi.getServidoresPoliciales(_easDbId);
        final nuevo = _servidoresPoliciales.cast<Map<String, dynamic>?>().lastOrNull;
        if (nuevo != null) {
          _desaPoliciaId = nuevo['id'] as int?;
        }
      } catch (_) {}
    }
    if (_desaDireccionOtro && _desaDireccion.trim().isNotEmpty) {
      _desaDireccionOtro = false;
      _desaDireccionCtrl.clear();
      try {
        await crtApi.crearDireccion(_easDbId, _desaDireccion.trim());
        _direcciones = await crtApi.getDirecciones(_easDbId);
        _desaDireccion = _desaDireccion.trim();
      } catch (_) {
        _direcciones = await crtApi.getDirecciones(_easDbId);
      }
    }
    if (mounted) setState(() => _desaSection++);
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
      final saves = <Future<void>>[];
      if (_desaCp.trim().isNotEmpty) {
        saves.add(crtApi.saveCp(_desaCp.trim()).catchError((_) {}));
      }
      if (_desaPoliciaOtro && _desaPoliciaNombre.trim().isNotEmpty) {
        saves.add(crtApi
            .crearServidorPolicial(_easDbId, _desaPoliciaNombre.trim())
            .catchError((_) {}));
      } else if (_desaPoliciaId != null) {
        saves.add(crtApi.savePolicia(_desaPoliciaId).catchError((_) {}));
      }
      if (_desaDireccionOtro && _desaDireccion.trim().isNotEmpty) {
        saves.add(crtApi
            .crearDireccion(_easDbId, _desaDireccion.trim())
            .catchError((_) {}));
      }
      await Future.wait(saves);
      if (_desaDireccionOtro) _desaDireccionOtro = false;

      final value = _buildText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      _direcciones = await crtApi.getDirecciones(_easDbId);
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
      final easId = _easDbId;
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(easId),
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

  Future<void> _cargarDatosRetiroTemporal() async {
    setState(() => _rtCargando = true);
    try {
      final easId = _easDbId;
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(easId),
        _cargarDirecciones(),
      ]);

      final cpGuardado = results[0] as String?;
      final policiaData = results[1] as Map<String, dynamic>?;
      final servidores = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _rtCpGuardado = cpGuardado ?? '';
        if (_rtCpGuardado.isNotEmpty) {
          _rtCpCtrl.text = _rtCpGuardado;
          _rtCp = _rtCpGuardado;
        }
        _rtServidoresPoliciales = servidores;
        _rtMovil = _moviles.first.movil;
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _rtPoliciaId = pid;
          _rtPoliciaNombre =
              policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
      // Silently fail on temp data load
    } finally {
      if (mounted) setState(() => _rtCargando = false);
    }
  }

  Future<List<Map<String, dynamic>>> _cargarDirecciones() async {
    try {
      final easIdx = CrtCatalog.easStations.indexOf(eas);
      final direcciones = await crtApi.getDirecciones(easIdx + 1);
      if (mounted) {
        setState(() {
          _direcciones = direcciones;
          if (_isRetiroTemporalFlow) {
            _rtDirecciones = direcciones;
          }
          if (_isColaboracionFlow) {
            _colDirecciones = direcciones;
          }
        });
      }
      return direcciones;
    } catch (_) {
      return [];
    }
  }

  Widget _buildRetiroTemporalWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backup_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Retiro temporal',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_rtCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRetiroTemporalStepContent(),
          const SizedBox(height: 24),
          _buildRetiroTemporalNavButtons(),
        ],
      ),
    );
  }

  Widget _buildRetiroTemporalStepContent() {
    if (_rtCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_rtSection == 0) {
      return _buildRTSection1();
    }
    return _buildRTSection2();
  }

  Widget _buildRTSection1() {
    final movilItems = _moviles.map((m) => m.movil).toList();
    final movilValue = _rtMovil.isNotEmpty && movilItems.contains(_rtMovil)
        ? _rtMovil
        : movilItems.first;
    final dirOptions = [
      ..._rtDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _rtDireccionOtro
        ? dirOptions.last
        : (_rtDireccion.isNotEmpty
            ? dirOptions.firstWhere(
                (d) => d['direccion'] == _rtDireccion,
                orElse: () => dirOptions.last,
              )
            : null);

    return Column(
      children: [
        if (rolMovil != RolMovil.jp)
          _StepCard(
            step: 1,
            title: 'Datos del personal',
            child: Column(
              children: [
                TextFormField(
                  controller: _rtJpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del agente JP',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _rtJp = value;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        _StepCard(
          step: 2,
          title: 'Seleccione móvil',
          child: DropdownButtonFormField<String>(
            initialValue: movilValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Móvil asignado',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
            ),
            items: movilItems
                .map((m) => DropdownMenuItem(value: m, child: Text('MOVIL $m')))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _rtMovil = value);
            },
          ),
        ),
        if (rolMovil != RolMovil.conductor) ...[
          const SizedBox(height: 20),
          _StepCard(
            step: 3,
            title: 'Datos del conductor',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _rtCpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del conductor CP',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _rtCp = value;
                    setState(() {});
                  },
                ),
                if (_rtCpGuardado.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Último registro: $_rtCpGuardado',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppThm.secClr,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _StepCard(
          step: 4,
          title: 'Servidor policial',
          child: Column(
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _rtPoliciaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Servidor policial',
                  prefixIcon: Icon(Icons.local_police_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sin servidor policial')),
                  ..._rtServidoresPoliciales.map((sp) {
                    final id = sp['id'] as int?;
                    final nombre = sp['nombre'] as String? ?? '';
                    return DropdownMenuItem(value: id, child: Text(nombre));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _rtPoliciaId = value;
                    if (value != null) {
                      _rtPoliciaOtro = false;
                      _rtPoliciaNombre = _rtServidoresPoliciales
                              .firstWhere(
                                (sp) => sp['id'] == value,
                                orElse: () => <String, dynamic>{},
                              )['nombre'] as String? ??
                          '';
                    } else {
                      _rtPoliciaNombre = '';
                    }
                    _rtPoliciaCtrl.clear();
                  });
                },
              ),
              if (_rtPoliciaOtro || (_rtPoliciaId == null && _rtPoliciaNombre.isNotEmpty && !_rtPoliciaOtro))
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _rtPoliciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servidor policial',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _rtPoliciaNombre = value;
                      setState(() {});
                    },
                  ),
                ),
              if (!_rtPoliciaOtro && _rtPoliciaId == null && _rtPoliciaNombre.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: InkWell(
                    onTap: () => setState(() {
                      _rtPoliciaOtro = true;
                      _rtPoliciaId = null;
                    }),
                    child: const Text(
                      'Ingresar otro servidor policial',
                      style: TextStyle(
                        color: AppThm.secClr,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 5,
          title: 'Dirección',
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: dirValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                items: dirOptions.map((d) {
                  final nombre = d['direccion'] as String? ?? '';
                  return DropdownMenuItem(value: d, child: Text(nombre));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'] as int?;
                  setState(() {
                    if (id == -1) {
                      _rtDireccionOtro = true;
                      _rtDireccion = '';
                    } else {
                      _rtDireccionOtro = false;
                      _rtDireccion = value['direccion'] as String? ?? '';
                    }
                  });
                },
              ),
              if (_rtDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _rtDireccion = value;
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 6,
          title: 'Auxiliares',
          child: Column(
            children: [
              TextField(
                controller: _rtAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _rtAux1 = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _rtAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _rtAux2 = value;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRTSection2() {
    return Column(
      children: [
        _StepCard(
          step: 7,
          title: 'Actividad comercial',
          child: TextFormField(
            controller: _rtActividadCtrl,
            decoration: const InputDecoration(
              labelText: '¿Qué actividad comercial realizaba?',
              prefixIcon: Icon(Icons.store_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _rtActividad = value;
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Elementos retirados',
          child: TextFormField(
            controller: _rtElementosCtrl,
            decoration: const InputDecoration(
              labelText: 'Elementos retirados',
              prefixIcon: Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _rtElementos = value;
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 9,
          title: 'Cantidad aproximada',
          child: TextFormField(
            controller: _rtCantidadCtrl,
            decoration: const InputDecoration(
              labelText: 'Cantidad aproximada',
              prefixIcon: Icon(Icons.numbers_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _rtCantidad = value;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRetiroTemporalNavButtons() {
    final isLast = _rtSection == 1;
    final isFirst = _rtSection == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () => setState(() => _rtSection--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _rtGuardando ? null : () => _generarRetiroTemporal(),
            icon: _rtGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_rtGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _rtIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _rtIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_rtCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_rtCp.trim()).catchError((_) {}));
    }
    if (_rtPoliciaOtro && _rtPoliciaNombre.trim().isNotEmpty) {
      saves.add(crtApi
          .crearServidorPolicial(_easDbId, _rtPoliciaNombre.trim())
          .catchError((_) {}));
    } else if (_rtPoliciaId != null) {
      saves.add(crtApi.savePolicia(_rtPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_rtPoliciaOtro && _rtPoliciaNombre.trim().isNotEmpty) {
      _rtPoliciaOtro = false;
      _rtPoliciaCtrl.clear();
      try {
        _rtServidoresPoliciales =
            await crtApi.getServidoresPoliciales(_easDbId);
        final nuevo =
            _rtServidoresPoliciales.cast<Map<String, dynamic>?>().lastOrNull;
        if (nuevo != null) {
          _rtPoliciaId = nuevo['id'] as int?;
        }
      } catch (_) {}
    }
    if (_rtDireccionOtro && _rtDireccion.trim().isNotEmpty) {
      _rtDireccionOtro = false;
      try {
        await crtApi.crearDireccion(_easDbId, _rtDireccion.trim());
        _rtDirecciones = await crtApi.getDirecciones(_easDbId);
        _rtDireccion = _rtDireccion.trim();
      } catch (_) {
        _rtDirecciones = await crtApi.getDirecciones(_easDbId);
      }
    }
    if (mounted) setState(() => _rtSection++);
  }

  Future<void> _generarRetiroTemporal() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }

    setState(() => _rtGuardando = true);

    try {
      final saves = <Future<void>>[];
      if (_rtCp.trim().isNotEmpty) {
        saves.add(crtApi.saveCp(_rtCp.trim()).catchError((_) {}));
      }
      if (_rtPoliciaOtro && _rtPoliciaNombre.trim().isNotEmpty) {
        saves.add(crtApi
            .crearServidorPolicial(_easDbId, _rtPoliciaNombre.trim())
            .catchError((_) {}));
      } else if (_rtPoliciaId != null) {
        saves.add(crtApi.savePolicia(_rtPoliciaId).catchError((_) {}));
      }
      if (_rtDireccionOtro && _rtDireccion.trim().isNotEmpty) {
        saves.add(crtApi
            .crearDireccion(_easDbId, _rtDireccion.trim())
            .catchError((_) {}));
      }
      await Future.wait(saves);
      if (_rtDireccionOtro) _rtDireccionOtro = false;

      final value = _buildRetiroTemporalText();
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
      if (mounted) setState(() => _rtGuardando = false);
    }
  }

  String _buildRetiroTemporalText() {
    final now = DateTime.now();
    final movilValue = _rtMovil.isNotEmpty ? _rtMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.retiroTemporal,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        rolMovil: rolMovil,
        values: {
          '_rt_jp': _rtJp.isNotEmpty ? _rtJp : (rolMovil == RolMovil.jp ? (widget.user?.nombreCompleto ?? '') : ''),
          '_rt_movil': movilValue,
          '_rt_cp': _rtCp.isNotEmpty ? _rtCp : (rolMovil == RolMovil.conductor ? (widget.user?.nombreCompleto ?? '') : ''),
          '_rt_policia': _rtPoliciaNombre,
          '_rt_direccion': _rtDireccion,
          '_rt_aux1': _rtAux1,
          '_rt_aux2': _rtAux2,
          '_rt_actividad': _rtActividad,
          '_rt_elementos': _rtElementos,
          '_rt_cantidad': _rtCantidad,
          '_rt_userNombre': widget.user?.nombreCompleto ?? '',
        },
      ),
    );
  }

  Future<void> _cargarDatosColaboracion() async {
    setState(() => _colCargando = true);
    try {
      final easId = _easDbId;
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(easId),
        _cargarDirecciones(),
      ]);
      final cpGuardado = results[0] as String?;
      final policiaData = results[1] as Map<String, dynamic>?;
      final servidores = results[2] as List<Map<String, dynamic>>;
      setState(() {
        _colCpGuardado = cpGuardado ?? '';
        if (_colCpGuardado.isNotEmpty) {
          _colCpCtrl.text = _colCpGuardado;
          _colCp = _colCpGuardado;
        }
        _colServidoresPoliciales = servidores;
        _colMovil = _moviles.first.movil;
        _colSubtype = 'entidad';
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _colPoliciaId = pid;
          _colPoliciaNombre =
              policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
      // Silently fail on temp data load
    } finally {
      if (mounted) setState(() => _colCargando = false);
    }
  }

  Widget _buildColaboracionWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Colaboración con otras entidades',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_colCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildColaboracionStepContent(),
          const SizedBox(height: 24),
          _buildColNavButtons(),
        ],
      ),
    );
  }

  Widget _buildColaboracionStepContent() {
    if (_colCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_colSection == 0) return _buildColSection1();
    return _buildColSection2();
  }

  Widget _buildColSection1() {
    final dirOptions = [
      ..._colDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _colDireccionOtro
        ? dirOptions.last
        : (_colDireccion.isNotEmpty
            ? dirOptions.firstWhere(
                (d) => d['direccion'] == _colDireccion,
                orElse: () => dirOptions.last,
              )
            : null);

    return Column(
      children: [
        if (rolMovil != RolMovil.jp)
          _StepCard(
            step: 1,
            title: 'Nombre del JP',
            child: TextFormField(
              controller: _colJpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del agente JP',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _colJp = value;
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        if (rolMovil != RolMovil.conductor)
          _StepCard(
            step: 2,
            title: 'Nombre del conductor CP',
            child: TextFormField(
              controller: _colCpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del conductor CP',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _colCp = value;
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.conductor) const SizedBox(height: 20),
        _StepCard(
          step: 3,
          title: 'Servidor policial',
          child: DropdownButtonFormField<int?>(
            initialValue: _colPoliciaId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servidor policial',
              prefixIcon: Icon(Icons.local_police_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sin servidor policial')),
              ..._colServidoresPoliciales.map((sp) {
                final id = sp['id'] as int?;
                final nombre = sp['nombre'] as String? ?? '';
                return DropdownMenuItem(value: id, child: Text(nombre));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _colPoliciaId = value;
                if (value != null) {
                  _colPoliciaOtro = false;
                  _colPoliciaNombre = _colServidoresPoliciales
                      .firstWhere(
                        (sp) => sp['id'] == value,
                        orElse: () => <String, dynamic>{},
                      )['nombre'] as String? ?? '';
                } else {
                  _colPoliciaNombre = '';
                }
                _colPoliciaCtrl.clear();
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 4,
          title: 'Dirección',
          child: Column(
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: dirValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                items: dirOptions.map((d) {
                  final nombre = d['direccion'] as String? ?? '';
                  return DropdownMenuItem(value: d, child: Text(nombre));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'] as int?;
                  setState(() {
                    if (id == -1) {
                      _colDireccionOtro = true;
                      _colDireccion = '';
                    } else {
                      _colDireccionOtro = false;
                      _colDireccion = value['direccion'] as String? ?? '';
                    }
                  });
                },
              ),
              if (_colDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _colDireccion = value;
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 5,
          title: 'Auxiliares',
          child: Column(
            children: [
              TextField(
                controller: _colAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colAux1 = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _colAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colAux2 = value;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 6,
          title: 'Tipo',
          child: DropdownButtonFormField<String>(
            initialValue: _colSubtype,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Seleccione el tipo',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'entidad', child: Text('Entidades de colaboración')),
              DropdownMenuItem(value: 'accidente', child: Text('Hecho o Accidente')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _colSubtype = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColSection2() {
    if (_colSubtype == 'accidente') {
      return _buildColAccidenteForm();
    }
    return _buildColEntidadForm();
  }

  Widget _buildColEntidadForm() {
    return Column(
      children: [
        _StepCard(
          step: 7,
          title: 'Entidad',
          child: DropdownButtonFormField<String>(
            initialValue: _colEntidad.isNotEmpty ? _colEntidad : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Entidad',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Policía', child: Text('Policía')),
              DropdownMenuItem(value: 'ATM', child: Text('ATM')),
              DropdownMenuItem(value: 'CTE', child: Text('CTE')),
              DropdownMenuItem(value: 'Bomberos', child: Text('Bomberos')),
              DropdownMenuItem(value: 'Paramédicos', child: Text('Paramédicos')),
              DropdownMenuItem(value: 'Fuerzas Armadas', child: Text('Fuerzas Armadas')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _colEntidad = value);
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Motivo',
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Motivo de la colaboración',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) {
              _colMotivo = value;
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColAccidenteForm() {
    return Column(
      children: [
        _StepCard(
          step: 7,
          title: 'Tipo de accidente',
          child: DropdownButtonFormField<String>(
            initialValue: _colTipoAccidente.isNotEmpty ? _colTipoAccidente : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de accidente',
              prefixIcon: Icon(Icons.car_crash_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Accidente entre dos vehículos', child: Text('Accidente entre dos vehículos')),
              DropdownMenuItem(value: 'Accidente múltiple', child: Text('Accidente múltiple')),
              DropdownMenuItem(value: 'Choque y daño al espacio y vía pública', child: Text('Choque y daño al espacio y vía pública')),
              DropdownMenuItem(value: 'Accidente entre vehículo y persona', child: Text('Accidente entre vehículo y persona')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _colTipoAccidente = value);
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Heridos',
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Número de heridos',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colNumHeridos = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre(s) de los heridos',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colNombresHeridos = value;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 9,
          title: 'Fallecidos',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _colHuboFallecidos ? 'si' : 'no',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Hubo fallecidos?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(value: 'si', child: Text('Sí')),
                ],
                onChanged: (value) {
                  setState(() => _colHuboFallecidos = value == 'si');
                },
              ),
              if (_colHuboFallecidos) ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Número de fallecidos',
                    prefixIcon: Icon(Icons.numbers_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colNumFallecidos = value;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre(s) de los fallecidos',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colNombresFallecidos = value;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 10,
          title: 'Instituciones',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _colCriminalistica,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Criminalística',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'No intervino', child: Text('No intervino')),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _colCriminalistica = value);
                },
              ),
              if (_colCriminalistica == 'Presente') ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del personal',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colCriminalisticaNombre = value;
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _colAtm,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ATM',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'No estuvo presente', child: Text('No estuvo presente')),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _colAtm = value);
                },
              ),
              if (_colAtm == 'Presente') ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del agente',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colAtmNombre = value;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Móvil',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colAtmMovil = value;
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _colAmbulancia,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ambulancia',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'No estuvo presente', child: Text('No estuvo presente')),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _colAmbulancia = value);
                },
              ),
              if (_colAmbulancia == 'Presente') ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del paramédico',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colAmbulanciaNombre = value;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 11,
          title: 'Vehículos',
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Placas',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colPlacas = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Conductores',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _colConductores = value;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 12,
          title: 'Daños observados',
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Daños observados',
              prefixIcon: Icon(Icons.warning_amber_outlined),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _colDanios = value;
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 13,
          title: 'Cierre vial',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _colCierreVial ? 'si' : 'no',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Hubo cierre vial?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(value: 'si', child: Text('Sí')),
                ],
                onChanged: (value) {
                  setState(() => _colCierreVial = value == 'si');
                },
              ),
              if (_colCierreVial) ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Describir cierre vial',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _colCierreVialDesc = value;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 14,
          title: 'Traslado hospitalario',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _colTraslado ? 'si' : 'no',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Hubo traslado hospitalario?',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(value: 'si', child: Text('Sí')),
                ],
                onChanged: (value) {
                  setState(() => _colTraslado = value == 'si');
                },
              ),
              if (_colTraslado) ...[
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Casa de salud',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _colCasaSalud = value;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColNavButtons() {
    final isLast = _colSection == 1;
    final isFirst = _colSection == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () => setState(() => _colSection--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _colGuardando ? null : () => _generarColaboracion(),
            icon: _colGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_colGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _colIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _colIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_colCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_colCp.trim()).catchError((_) {}));
    }
    if (_colPoliciaOtro && _colPoliciaNombre.trim().isNotEmpty) {
      saves.add(crtApi
          .crearServidorPolicial(_easDbId, _colPoliciaNombre.trim())
          .catchError((_) {}));
    } else if (_colPoliciaId != null) {
      saves.add(crtApi.savePolicia(_colPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_colPoliciaOtro && _colPoliciaNombre.trim().isNotEmpty) {
      _colPoliciaOtro = false;
      _colPoliciaCtrl.clear();
      try {
        _colServidoresPoliciales =
            await crtApi.getServidoresPoliciales(_easDbId);
        final nuevo =
            _colServidoresPoliciales.cast<Map<String, dynamic>?>().lastOrNull;
        if (nuevo != null) {
          _colPoliciaId = nuevo['id'] as int?;
        }
      } catch (_) {}
    }
    if (_colDireccionOtro && _colDireccion.trim().isNotEmpty) {
      _colDireccionOtro = false;
      try {
        await crtApi.crearDireccion(_easDbId, _colDireccion.trim());
        _colDirecciones = await crtApi.getDirecciones(_easDbId);
        _colDireccion = _colDireccion.trim();
      } catch (_) {
        _colDirecciones = await crtApi.getDirecciones(_easDbId);
      }
    }
    if (mounted) setState(() => _colSection++);
  }

  Future<void> _generarColaboracion() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }
    setState(() => _colGuardando = true);
    try {
      final saves = <Future<void>>[];
      if (_colCp.trim().isNotEmpty) {
        saves.add(crtApi.saveCp(_colCp.trim()).catchError((_) {}));
      }
      if (_colPoliciaOtro && _colPoliciaNombre.trim().isNotEmpty) {
        saves.add(crtApi
            .crearServidorPolicial(_easDbId, _colPoliciaNombre.trim())
            .catchError((_) {}));
      } else if (_colPoliciaId != null) {
        saves.add(crtApi.savePolicia(_colPoliciaId).catchError((_) {}));
      }
      if (_colDireccionOtro && _colDireccion.trim().isNotEmpty) {
        saves.add(crtApi
            .crearDireccion(_easDbId, _colDireccion.trim())
            .catchError((_) {}));
      }
      await Future.wait(saves);
      if (_colDireccionOtro) _colDireccionOtro = false;

      final value = _buildColaboracionText();
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
      if (mounted) setState(() => _colGuardando = false);
    }
  }

  String _buildColaboracionText() {
    final now = DateTime.now();
    final movilValue = _colMovil.isNotEmpty ? _colMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.colaboracionEntidades,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        rolMovil: rolMovil,
        values: {
          '_col_subtype': _colSubtype,
          '_col_jp': _colJp.isNotEmpty ? _colJp : (rolMovil == RolMovil.jp ? (widget.user?.nombreCompleto ?? '') : ''),
          '_col_movil': movilValue,
          '_col_cp': _colCp.isNotEmpty ? _colCp : (rolMovil == RolMovil.conductor ? (widget.user?.nombreCompleto ?? '') : ''),
          '_col_policia': _colPoliciaNombre,
          '_col_direccion': _colDireccion,
          '_col_aux1': _colAux1,
          '_col_aux2': _colAux2,
          '_col_userNombre': widget.user?.nombreCompleto ?? '',
          '_col_entidad': _colEntidad,
          '_col_motivo': _colMotivo,
          '_col_tipoAccidente': _colTipoAccidente,
          '_col_numHeridos': _colNumHeridos,
          '_col_nombresHeridos': _colNombresHeridos,
          '_col_huboFallecidos': _colHuboFallecidos ? 'si' : 'no',
          '_col_numFallecidos': _colNumFallecidos,
          '_col_nombresFallecidos': _colNombresFallecidos,
          '_col_criminalistica': _colCriminalistica,
          '_col_criminalisticaNombre': _colCriminalisticaNombre,
          '_col_atm': _colAtm,
          '_col_atmNombre': _colAtmNombre,
          '_col_atmMovil': _colAtmMovil,
          '_col_ambulancia': _colAmbulancia,
          '_col_ambulanciaNombre': _colAmbulanciaNombre,
          '_col_placas': _colPlacas,
          '_col_conductores': _colConductores,
          '_col_danios': _colDanios,
          '_col_cierreVial': _colCierreVial ? 'si' : 'no',
          '_col_cierreVialDesc': _colCierreVialDesc,
          '_col_traslado': _colTraslado ? 'si' : 'no',
          '_col_casaSalud': _colCasaSalud,
        },
      ),
    );
  }

  Widget _formPanel() {
    return _Panel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (modulo != TipoModuloCartilla.eas) ...[
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
              const SizedBox(height: 14),
            ],
            _Field(
              controller: _controller('direccion'),
              label: 'Dirección',
              icon: Icons.place_outlined,
              required: false,
              onChanged: () => setState(() {}),
            ),
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
    if (formKey.currentState != null && !formKey.currentState!.validate()) return;
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
      barrierDismissible: false,
      builder: (_) => BadgeUnlockDialog(insignia: insignia),
    );
  }

  String _buildText() {
    if (_isDesalojoFlow) {
      return _buildDesalojoText();
    }
    if (_isPuntoMartilloFlow) {
      return _buildPuntoMartilloText();
    }
    if (_isRondasDisuasivasFlow) {
      return _buildRondasDisuasivasText();
    }
    if (_isRetiroTemporalFlow) {
      return _buildRetiroTemporalText();
    }
    if (_isColaboracionFlow) {
      return _buildColaboracionText();
    }
    if (_isEasCustomCardFlow) {
      return _buildEasCustomText();
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

  String _buildPuntoMartilloText() {
    final now = DateTime.now();
    final movilValue = _desaMovil.isNotEmpty ? _desaMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.puntoMartillo,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        values: {
          '_pm_jp': _desaJp.isNotEmpty
              ? _desaJp
              : (widget.user?.nombreCompleto ?? ''),
          '_pm_aux': _desaAux,
          '_pm_movil': movilValue,
          '_pm_cp': _desaCp,
          '_pm_policia': _desaPoliciaNombre,
          '_pm_direccion': _desaDireccion,
        },
      ),
    );
  }

  String _buildRondasDisuasivasText() {
    final now = DateTime.now();
    final movilValue = _desaMovil.isNotEmpty ? _desaMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.rondasDisuasivas,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        values: {
          '_rd_jp': _desaJp.isNotEmpty
              ? _desaJp
              : (widget.user?.nombreCompleto ?? ''),
          '_rd_aux': _desaAux,
          '_rd_movil': movilValue,
          '_rd_cp': _desaCp,
          '_rd_policia': _desaPoliciaNombre,
          '_rd_direccion': _desaDireccion,
        },
      ),
    );
  }

  String _buildEasCustomText() {
    final now = DateTime.now();
    final movilValue = _desaMovil.isNotEmpty ? _desaMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: tipo,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        values: {
          '_ez_jp': _desaJp.isNotEmpty
              ? _desaJp
              : (widget.user?.nombreCompleto ?? ''),
          '_ez_aux': _desaAux,
          '_ez_movil': movilValue,
          '_ez_cp': _desaCp,
          '_ez_policia': _desaPoliciaNombre,
          '_ez_direccion': _desaDireccion,
          '_ez_detalle': _ezDetalleCtrl.text,
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
      'direccion',
    };
    for (final key in keys) {
      controllers.putIfAbsent(key, () => TextEditingController());
    }

    if (controllers['reporta']!.text.isEmpty &&
        widget.user?.nombreCompleto.isNotEmpty == true) {
      controllers['reporta']!.text = widget.user!.nombreCompleto;
    }

    if (_isRetiroTemporalFlow) {
      _cargarDatosRetiroTemporal();
    } else if (_isColaboracionFlow) {
      _cargarDatosColaboracion();
    } else if (_isDesalojoFlow ||
        _isPuntoMartilloFlow ||
        _isRondasDisuasivasFlow ||
        _isEasCustomCardFlow) {
      _cargarDatosDesalojo();
    }
  }

  void _autoFillByRole() {
    final name = widget.user?.nombreCompleto ?? '';
    _desaAuxCtrl.text = '';
    _desaCpCtrl.text = '';
    _desaJpCtrl.text = '';
    _rtCpCtrl.text = '';
    _rtJpCtrl.text = '';
    _rtAux1Ctrl.text = '';
    _colCpCtrl.text = '';
    _colJpCtrl.text = '';
    _colAux1Ctrl.text = '';
    switch (rolMovil) {
      case RolMovil.jp:
        _desaJpCtrl.text = name;
        _rtJpCtrl.text = name;
        _colJpCtrl.text = name;
        break;
      case RolMovil.conductor:
        _desaCpCtrl.text = name;
        _rtCpCtrl.text = name;
        _colCpCtrl.text = name;
        break;
      case RolMovil.auxiliar:
        _desaAuxCtrl.text = name;
        _rtAux1Ctrl.text = name;
        _colAux1Ctrl.text = name;
        break;
    }
    _desaJp = _desaJpCtrl.text;
    _desaCp = _desaCpCtrl.text;
    _desaAux = _desaAuxCtrl.text;
    _rtJp = _rtJpCtrl.text;
    _rtCp = _rtCpCtrl.text;
    _rtAux1 = _rtAux1Ctrl.text;
    _colJp = _colJpCtrl.text;
    _colCp = _colCpCtrl.text;
    _colAux1 = _colAux1Ctrl.text;
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

class _EasTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _EasTypeCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, size: 28, color: selected ? AppThm.priClr : AppThm.txtClr),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppThm.priClr : AppThm.txtClr,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
