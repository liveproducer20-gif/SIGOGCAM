import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import '../ins/ins_api.dart';
import '../ins/ins_badge_dlg.dart';
import '../ins/ins_mdl.dart';
import 'mdl/crt_enums.dart';
import 'mdl/crt_models.dart';
import 'mdl/crt_special_models.dart';
import 'svc/crt_api.dart';
import 'svc/crt_catalog.dart';
import 'svc/crt_text_generator.dart';
import 'wdg/cartilla_type_selector.dart';
import 'wdg/crt_special_form.dart';

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
  String? _previewText;
  Timer? _previewDebounce;
  TipoFormacion? _formacionSeleccionada;
  bool _otrasCartillasSeleccionada = true;
  String _jefeNombre = '';
  bool _formExpanded = false;

  final crtApi = CrtApi();

  bool _desaCargando = false;
  int _desaSection = 0;
  String _desaJp = '';
  String _desaAux = '';
  bool get _hasPolicia => _desaPoliciaOtro || _desaPoliciaId != null;
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

  bool _reqCargando = false;
  int _reqSection = 0;
  String _reqJp = '';
  String _reqMovil = '';
  String _reqCp = '';
  String _reqCpGuardado = '';
  int? _reqPoliciaId;
  String _reqPoliciaNombre = '';
  bool _reqPoliciaOtro = false;
  final _reqPoliciaCtrl = TextEditingController();
  final _reqJpCtrl = TextEditingController();
  final _reqCpCtrl = TextEditingController();
  String _reqDireccion = '';
  bool _reqDireccionOtro = false;
  List<Map<String, dynamic>> _reqServidoresPoliciales = [];
  List<Map<String, dynamic>> _reqDirecciones = [];
  String _reqAux1 = '';
  final _reqAux1Ctrl = TextEditingController();
  String _reqAux2 = '';
  final _reqAux2Ctrl = TextEditingController();
  String _reqSolicitante = '';
  String _reqSolicitanteOtro = '';
  final _reqSolicitanteOtroCtrl = TextEditingController();
  String _reqTipo = 'Requerimiento';
  String _reqInfoAdicional = '';
  bool _reqGuardando = false;

  bool _ciuCargando = false;
  int _ciuSection = 0;
  String _ciuJp = '';
  String _ciuMovil = '';
  String _ciuCp = '';
  String _ciuCpGuardado = '';
  int? _ciuPoliciaId;
  String _ciuPoliciaNombre = '';
  bool _ciuPoliciaOtro = false;
  final _ciuPoliciaCtrl = TextEditingController();
  final _ciuJpCtrl = TextEditingController();
  final _ciuCpCtrl = TextEditingController();
  String _ciuDireccion = '';
  bool _ciuDireccionOtro = false;
  List<Map<String, dynamic>> _ciuServidoresPoliciales = [];
  List<Map<String, dynamic>> _ciuDirecciones = [];
  String _ciuAux1 = '';
  final _ciuAux1Ctrl = TextEditingController();
  String _ciuAux2 = '';
  final _ciuAux2Ctrl = TextEditingController();
  String _ciuTipoGeneral = 'denuncia';
  String _ciuTipoEspecifico = '';
  String _ciuNombreCiudadano = '';
  final _ciuNombreCiudadanoCtrl = TextEditingController();
  String _ciuCedula = '';
  final _ciuCedulaCtrl = TextEditingController();
  String _ciuCelular = '';
  final _ciuCelularCtrl = TextEditingController();
  String _ciuLugar = '';
  final _ciuLugarCtrl = TextEditingController();
  String _ciuBienesRobados = '';
  final _ciuBienesRobadosCtrl = TextEditingController();
  String _ciuValorRobado = '';
  final _ciuValorRobadoCtrl = TextEditingController();
  String _ciuBienesPerdidos = '';
  final _ciuBienesPerdidosCtrl = TextEditingController();
  String _ciuValorPerdido = '';
  final _ciuValorPerdidoCtrl = TextEditingController();
  String _ciuNombreLocal = '';
  final _ciuNombreLocalCtrl = TextEditingController();
  String _ciuReferenciaLocal = '';
  final _ciuReferenciaLocalCtrl = TextEditingController();
  String _ciuMotivoExtorsion = '';
  final _ciuMotivoExtorsionCtrl = TextEditingController();
  String _ciuNombreAmenazante = '';
  final _ciuNombreAmenazanteCtrl = TextEditingController();
  String _ciuCedulaAmenazante = '';
  final _ciuCedulaAmenazanteCtrl = TextEditingController();
  String _ciuTextoAmenaza = '';
  final _ciuTextoAmenazaCtrl = TextEditingController();
  String _ciuNombreDesaparecido = '';
  final _ciuNombreDesaparecidoCtrl = TextEditingController();
  String _ciuUltimaUbicacion = '';
  final _ciuUltimaUbicacionCtrl = TextEditingController();
  String _ciuCedulaDesaparecido = '';
  final _ciuCedulaDesaparecidoCtrl = TextEditingController();
  String _ciuVestimenta = '';
  final _ciuVestimentaCtrl = TextEditingController();
  String _ciuAntecedente = '';
  final _ciuAntecedenteCtrl = TextEditingController();
  String _ciuMotivoConflictivo = '';
  final _ciuMotivoConflictivoCtrl = TextEditingController();
  String _ciuRequerimientoCiudadano = '';
  final _ciuRequerimientoCiudadanoCtrl = TextEditingController();
  String _ciuNombreAgresor = '';
  final _ciuNombreAgresorCtrl = TextEditingController();
  String _ciuObjetoAgresion = '';
  final _ciuObjetoAgresionCtrl = TextEditingController();
  String _ciuDetalleHerida = '';
  final _ciuDetalleHeridaCtrl = TextEditingController();
  String _ciuMotivoCamaras = '';
  final _ciuMotivoCamarasCtrl = TextEditingController();
  String _ciuNombreEvento = '';
  final _ciuNombreEventoCtrl = TextEditingController();
  String _ciuHoraEvento = '';
  final _ciuHoraEventoCtrl = TextEditingController();
  String _ciuFechaEvento = '';
  final _ciuFechaEventoCtrl = TextEditingController();
  String _ciuMotivoEvento = '';
  final _ciuMotivoEventoCtrl = TextEditingController();
  String _ciuMotivoResguardo = '';
  final _ciuMotivoResguardoCtrl = TextEditingController();
  String _ciuMotivoAtm = '';
  final _ciuMotivoAtmCtrl = TextEditingController();
  bool _ciuGuardando = false;

  bool _ezCargando = false;
  int _ezSection = 0;
  String _ezJp = '';
  String _ezCp = '';
  String _ezCpGuardado = '';
  int? _ezPoliciaId;
  String _ezPoliciaNombre = '';
  bool _ezPoliciaOtro = false;
  final _ezPoliciaCtrl = TextEditingController();
  final _ezJpCtrl = TextEditingController();
  final _ezCpCtrl = TextEditingController();
  String _ezDireccion = '';
  bool _ezDireccionOtro = false;
  List<Map<String, dynamic>> _ezServidoresPoliciales = [];
  List<Map<String, dynamic>> _ezDirecciones = [];
  String _ezAux1 = '';
  final _ezAux1Ctrl = TextEditingController();
  String _ezAux2 = '';
  final _ezAux2Ctrl = TextEditingController();
  bool _ezGuardando = false;

  bool _ausCargando = false;
  int _ausSection = 0;
  String _ausJp = '';
  String _ausCp = '';
  String _ausCpGuardado = '';
  int? _ausPoliciaId;
  String _ausPoliciaNombre = '';
  bool _ausPoliciaOtro = false;
  final _ausPoliciaCtrl = TextEditingController();
  final _ausJpCtrl = TextEditingController();
  final _ausCpCtrl = TextEditingController();
  String _ausDireccion = '';
  bool _ausDireccionOtro = false;
  List<Map<String, dynamic>> _ausServidoresPoliciales = [];
  List<Map<String, dynamic>> _ausDirecciones = [];
  String _ausAux1 = '';
  final _ausAux1Ctrl = TextEditingController();
  String _ausAux2 = '';
  final _ausAux2Ctrl = TextEditingController();
  String _ausTipoPermiso = 'Permiso por horas';
  TimeOfDay _ausHoraSalida = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _ausHoraRetorno = const TimeOfDay(hour: 8, minute: 0);
  DateTime _ausFechaInicio = DateTime.now();
  DateTime _ausFechaFin = DateTime.now();
  String _ausMotivo = '';
  String _ausLugar = '';
  String _ausDetalle = '';
  String _ausInfoAdicional = '';
  final _ausLugarCtrl = TextEditingController();
  final _ausDetalleCtrl = TextEditingController();
  final _ausInfoAdicionalCtrl = TextEditingController();
  bool _ausGuardando = false;

  CrtModuleConfig get config => CrtCatalog.configFor(modulo);
  List<CrtFieldConfig> get activeFields => CrtCatalog.fieldsFor(modulo, tipo);

  bool get _isDesalojoFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.desalojoVendedores;

  bool get _isPuntoMartilloFlow =>
      modulo == TipoModuloCartilla.eas && tipo == TipoCartilla.puntoMartillo;

  bool get _isRondasDisuasivasFlow =>
      modulo == TipoModuloCartilla.eas && tipo == TipoCartilla.rondasDisuasivas;

  bool get _isRetiroTemporalFlow =>
      modulo == TipoModuloCartilla.eas && tipo == TipoCartilla.retiroTemporal;

  bool get _isColaboracionFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.colaboracionEntidades;

  bool get _isRequerimientoFlow =>
      modulo == TipoModuloCartilla.eas && tipo == TipoCartilla.requerimiento;

  bool get _isColaboracionCiudadanaFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.colaboracionEventos;

  bool get _isAusentismoFlow =>
      modulo == TipoModuloCartilla.eas &&
      tipo == TipoCartilla.permisoAusentismo;

  bool get _isGenericEasWizardFlow {
    if (modulo != TipoModuloCartilla.eas) return false;
    return [
      TipoCartilla.presenciaAgenteControl,
      TipoCartilla.operativoConjunto,
      TipoCartilla.roboManoArmada,
      TipoCartilla.perdidaBienInmueble,
      TipoCartilla.extorsion,
      TipoCartilla.amenazas,
      TipoCartilla.desaparicionPersona,
      TipoCartilla.agresion,
      TipoCartilla.visualizacionCamaras,
      TipoCartilla.resguardoPersonal,
      TipoCartilla.colaboracionAtm,
    ].contains(tipo);
  }

  @override
  void initState() {
    super.initState();
    _syncFields();
    movil = _moviles.first.movil;
    _autoFillByRole();
    _cargarJefe();
  }

  Future<void> _cargarJefe() async {
    try {
      final jefe = await crtApi.getJefeControlMunicipal();
      final ap = (jefe?['apellidos'] as String? ?? '').trim();
      final nm = (jefe?['nombres'] as String? ?? '').trim();
      CrtTextGenerator.jefeNombre = ap.isNotEmpty && nm.isNotEmpty
          ? '$ap $nm'
          : '';
      _jefeNombre = ap.isNotEmpty && nm.isNotEmpty
          ? '$ap $nm Jefe de Control Municipal'
          : 'Jefe de Control Municipal';
    } catch (_) {
      CrtTextGenerator.jefeNombre = '';
      _jefeNombre = 'Jefe de Control Municipal';
    }
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
    _reqPoliciaCtrl.dispose();
    _reqJpCtrl.dispose();
    _reqCpCtrl.dispose();
    _reqAux1Ctrl.dispose();
    _reqAux2Ctrl.dispose();
    _reqSolicitanteOtroCtrl.dispose();
    _ciuPoliciaCtrl.dispose();
    _ciuJpCtrl.dispose();
    _ciuCpCtrl.dispose();
    _ciuAux1Ctrl.dispose();
    _ciuAux2Ctrl.dispose();
    _ciuNombreCiudadanoCtrl.dispose();
    _ciuCedulaCtrl.dispose();
    _ciuCelularCtrl.dispose();
    _ciuLugarCtrl.dispose();
    _ciuBienesRobadosCtrl.dispose();
    _ciuValorRobadoCtrl.dispose();
    _ciuBienesPerdidosCtrl.dispose();
    _ciuValorPerdidoCtrl.dispose();
    _ciuNombreLocalCtrl.dispose();
    _ciuReferenciaLocalCtrl.dispose();
    _ciuMotivoExtorsionCtrl.dispose();
    _ciuNombreAmenazanteCtrl.dispose();
    _ciuCedulaAmenazanteCtrl.dispose();
    _ciuTextoAmenazaCtrl.dispose();
    _ciuNombreDesaparecidoCtrl.dispose();
    _ciuUltimaUbicacionCtrl.dispose();
    _ciuCedulaDesaparecidoCtrl.dispose();
    _ciuVestimentaCtrl.dispose();
    _ciuAntecedenteCtrl.dispose();
    _ciuMotivoConflictivoCtrl.dispose();
    _ciuRequerimientoCiudadanoCtrl.dispose();
    _ciuNombreAgresorCtrl.dispose();
    _ciuObjetoAgresionCtrl.dispose();
    _ciuDetalleHeridaCtrl.dispose();
    _ciuMotivoCamarasCtrl.dispose();
    _ciuNombreEventoCtrl.dispose();
    _ciuHoraEventoCtrl.dispose();
    _ciuFechaEventoCtrl.dispose();
    _ciuMotivoEventoCtrl.dispose();
    _ciuMotivoResguardoCtrl.dispose();
    _ciuMotivoAtmCtrl.dispose();
    _ezPoliciaCtrl.dispose();
    _ezJpCtrl.dispose();
    _ezCpCtrl.dispose();
    _ezAux1Ctrl.dispose();
    _ezAux2Ctrl.dispose();
    _ausPoliciaCtrl.dispose();
    _ausJpCtrl.dispose();
    _ausCpCtrl.dispose();
    _ausAux1Ctrl.dispose();
    _ausAux2Ctrl.dispose();
    _ausLugarCtrl.dispose();
    _ausDetalleCtrl.dispose();
    _ausInfoAdicionalCtrl.dispose();
    _previewDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final preview = _previewText;

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
        child: isWide
            ? _buildWideLayout(screenWidth, preview)
            : _buildNarrowLayout(preview),
      ),
    );
  }

  Widget _buildWideLayout(double screenWidth, String? preview) {
    final isTablet = screenWidth < 1050;
    final leftFlex = isTablet ? 9 : 10;
    final rightFlex = isTablet ? 11 : 10;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: leftFlex,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 28, isTablet ? 28 : 12, 28),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _formExpanded
                  ? _formPanelChildren()
                  : _selectorPanelChildren(true),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: rightFlex,
          child: _buildDesktopPreview(preview),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(String? preview) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _formExpanded
            ? [
                ..._formPanelChildren(),
                const SizedBox(height: 24),
                _buildMobilePreview(preview),
              ]
            : _selectorPanelChildren(false),
      ),
    );
  }

  List<Widget> _selectorPanelChildren(bool compact) {
    return [
      const PageTtlWdg(
        ttl: 'Generador de cartillas',
        sub:
            'Seleccione el modulo operativo y complete solo los campos requeridos.',
      ),
      const SizedBox(height: 26),
      CartillaTypeSelector(
        compact: compact,
        selectedId: _selectedCartillaId,
        onSelected: _onCartillaTypeSelected,
        canView: _canGenerate,
        canCreateFormation: _canCreateFormation,
      ),
    ];
  }

  List<Widget> _formPanelChildren() {
    return [
      _buildBackButton(),
      const SizedBox(height: 16),
      const Text(
        'Datos de la cartilla',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppThm.priClr,
        ),
      ),
      const SizedBox(height: 16),
      _buildModuloSelector(),
      const SizedBox(height: 16),
      _buildFormContent(),
      const SizedBox(height: 24),
      _buildActionBar(),
    ];
  }

  Widget _buildModuloSelector() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: Icons.tune_outlined, title: 'Módulo'),
          const SizedBox(height: 18),
          _Drop<TipoModuloCartilla>(
            value: modulo,
            label: 'Modulo de cartilla',
            icon: Icons.dashboard_customize_outlined,
            items: TipoModuloCartilla.values,
            itemText: (value) => value.label,
            onChanged: (value) {
              _invalidatePreview();
              setState(() {
                modulo = value;
                _formacionSeleccionada = null;
                _otrasCartillasSeleccionada = true;
                final tipos = CrtCatalog.configFor(modulo).tipos;
                if (!tipos.contains(tipo)) tipo = tipos.first;
                if (modulo == TipoModuloCartilla.eas) {
                  movil = _moviles.first.movil;
                }
                _syncFields();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _goBackToSelector,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver a tipos de cartilla'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppThm.priClr,
          side: const BorderSide(color: AppThm.priClr),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    if (!_showGlobalActionBar) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _previewText != null ? null : _doPreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Generar vista previa'),
        ),
        if (_previewText != null)
          FilledButton.icon(
            onPressed: guardando ? null : () => _generar(_previewText!),
            icon: guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.copy_outlined),
            label: Text(guardando ? 'Guardando' : 'Crear cartilla'),
          ),
        if (_previewText != null)
          OutlinedButton.icon(
            onPressed: () {
              _previewText = null;
              setState(() {});
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Seguir editando'),
          ),
      ],
    );
  }

  void _onCrtPreviewChanged(String text) {
    setState(() => _previewText = text);
  }

  Widget _buildFormContent() {
    if (_formacionSeleccionada != null) {
      return CrtSpecialForm(
        key: ValueKey(_formacionSeleccionada),
        kind: CrtSpecialFormKind.formacion,
        modulo: modulo,
        formationType: _formacionSeleccionada,
        user: widget.user,
        jefe: _jefeNombre,
        canCreate: _canCreateFormation,
        hidePreview: true,
        onPreviewChanged: _onCrtPreviewChanged,
      );
    }
    if (_otrasCartillasSeleccionada && modulo == TipoModuloCartilla.eas) {
      return CrtSpecialForm(
        key: const ValueKey('otras-cartillas'),
        kind: CrtSpecialFormKind.otras,
        modulo: modulo,
        easStation: eas,
        user: widget.user,
        jefe: _jefeNombre,
        canCreate: _canGenerate,
        hidePreview: true,
        onPreviewChanged: _onCrtPreviewChanged,
      );
    }
    if (_otrasCartillasSeleccionada && modulo == TipoModuloCartilla.radioperador) {
      return CrtSpecialForm(
        key: const ValueKey('otras-cartillas-rad'),
        kind: CrtSpecialFormKind.otras,
        modulo: modulo,
        easStation: eas,
        user: widget.user,
        jefe: _jefeNombre,
        canCreate: _canGenerate,
        hidePreview: true,
        onPreviewChanged: _onCrtPreviewChanged,
      );
    }
    if (modulo == TipoModuloCartilla.conductor) {
      return CrtSpecialForm(
        kind: CrtSpecialFormKind.conductor,
        modulo: modulo,
        user: widget.user,
        jefe: _jefeNombre,
        canCreate: _canCreateConductor,
        hidePreview: true,
        onPreviewChanged: _onCrtPreviewChanged,
      );
    }
    if (modulo == TipoModuloCartilla.eas) {
      return _buildEasFormOnly();
    }
    return _formPanel();
  }

  Widget _buildEasFormOnly() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEasConfigPanel(),
        const SizedBox(height: 20),
        if (_isDesalojoFlow)
          _buildDesalojoWizard()
        else if (_isPuntoMartilloFlow)
          _buildPuntoMartilloForm()
        else if (_isRondasDisuasivasFlow)
          _buildRondasDisuasivasForm()
        else if (_isRetiroTemporalFlow)
          _buildRetiroTemporalWizard()
        else if (_isColaboracionFlow)
          _buildColaboracionWizard()
        else if (_isRequerimientoFlow)
          _buildRequerimientoWizard()
        else if (_isColaboracionCiudadanaFlow)
          _buildColCiudadanaWizard()
        else if (_isAusentismoFlow)
          _buildAusentismoWizard()
        else if (_isGenericEasWizardFlow)
          _buildGenericEasWizard()
        else
          _formPanel(),
      ],
    );
  }

  Widget _buildDesktopPreview(String? preview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.preview_outlined,
            title: 'Vista previa',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildDocPanel(preview),
          ),
        ],
      ),
    );
  }

  bool get _showGlobalActionBar {
    if (_formacionSeleccionada != null) return false;
    if (_otrasCartillasSeleccionada && modulo == TipoModuloCartilla.eas) return false;
    if (_otrasCartillasSeleccionada && modulo == TipoModuloCartilla.radioperador) return false;
    if (modulo == TipoModuloCartilla.conductor) return false;
    if (modulo == TipoModuloCartilla.eas) {
      // EAS types that have their own generate button inside the wizard
      if (_isDesalojoFlow) return false;
      if (_isRetiroTemporalFlow) return false;
      if (_isColaboracionFlow) return false;
      if (_isRequerimientoFlow) return false;
      if (_isColaboracionCiudadanaFlow) return false;
      if (_isAusentismoFlow) return false;
      if (_isGenericEasWizardFlow) return false;
    }
    return true;
  }

  Widget _buildMobilePreview(String? preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.preview_outlined,
          title: 'Vista previa',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: _buildDocInner(preview),
        ),
      ],
    );
  }

  Widget _buildDocPanel(String? preview) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: _buildDocInner(preview),
    );
  }

  Widget _buildDocInner(String? preview) {
    if (preview != null) {
      return SingleChildScrollView(
        child: SelectableText(
          preview,
          style: const TextStyle(
            color: AppThm.txtClr,
            height: 1.45,
            fontFamily: 'monospace',
            fontSize: 13.5,
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'La vista previa aparecerá aquí',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccione un tipo de cartilla y complete los campos requeridos.',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool get _canGenerate =>
      widget.user?.hasPermission('cartillas.generar') == true;

  bool get _canCreateFormation {
    final role = widget.user?.rol.toUpperCase() ?? '';
    return _canGenerate &&
        (role.contains('ADMIN') ||
            role.contains('ENCARGADO') ||
            role.contains('RADIOPERADOR'));
  }

  bool get _canCreateConductor {
    final role = widget.user?.rol.toUpperCase() ?? '';
    if (role.contains('AUDITOR')) return false;
    return _canGenerate;
  }

  String? get _selectedCartillaId {
    if (_formacionSeleccionada == TipoFormacion.entrante) {
      return 'formacion_entrante';
    }
    if (_formacionSeleccionada == TipoFormacion.saliente) {
      return 'formacion_saliente';
    }
    if (_otrasCartillasSeleccionada) return 'otras_cartillas';
    switch (tipo) {
      case TipoCartilla.desalojoVendedores:
        return 'desalojo_vendedores';
      case TipoCartilla.puntoMartillo:
        return 'punto_martillo';
      case TipoCartilla.rondasDisuasivas:
        return 'rondas_disuasivas';
      case TipoCartilla.retiroTemporal:
        return 'retiro_temporal';
      case TipoCartilla.requerimiento:
        return 'requerimiento';
      case TipoCartilla.colaboracionEntidades:
        return 'colaboracion_entidades';
      case TipoCartilla.colaboracionEventos:
        return 'colaboracion_ciudadana';
      case TipoCartilla.permisoAusentismo:
        return 'permiso_ausentismo';
      default:
        return null;
    }
  }

  TipoCartilla _tipoFromId(String id) {
    switch (id) {
      case 'desalojo_vendedores':
        return TipoCartilla.desalojoVendedores;
      case 'punto_martillo':
        return TipoCartilla.puntoMartillo;
      case 'rondas_disuasivas':
        return TipoCartilla.rondasDisuasivas;
      case 'retiro_temporal':
        return TipoCartilla.retiroTemporal;
      case 'requerimiento':
        return TipoCartilla.requerimiento;
      case 'colaboracion_entidades':
        return TipoCartilla.colaboracionEntidades;
      case 'colaboracion_ciudadana':
        return TipoCartilla.colaboracionEventos;
      case 'permiso_ausentismo':
        return TipoCartilla.permisoAusentismo;
      default:
        return TipoCartilla.puntoMartillo;
    }
  }

  void _onCartillaTypeSelected(String id) {
    _invalidatePreview();
    setState(() {
      switch (id) {
        case 'formacion_entrante':
          _formacionSeleccionada = TipoFormacion.entrante;
          _otrasCartillasSeleccionada = false;
        case 'formacion_saliente':
          _formacionSeleccionada = TipoFormacion.saliente;
          _otrasCartillasSeleccionada = false;
        case 'otras_cartillas':
          _formacionSeleccionada = null;
          _otrasCartillasSeleccionada = true;
        default:
          _formacionSeleccionada = null;
          _otrasCartillasSeleccionada = false;
          tipo = _tipoFromId(id);
      }
      _formExpanded = true;
      _syncFields();
    });
  }

  void _goBackToSelector() {
    _invalidatePreview();
    setState(() => _formExpanded = false);
  }

  // ignore: unused_element
  Widget _buildEasLayout(bool isWide, String? preview) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEasConfigPanel(),
        const SizedBox(height: 20),
        if (_isDesalojoFlow)
          _buildDesalojoWizard()
        else if (_isPuntoMartilloFlow)
          _buildPuntoMartilloForm()
        else if (_isRondasDisuasivasFlow)
          _buildRondasDisuasivasForm()
        else if (_isRetiroTemporalFlow)
          _buildRetiroTemporalWizard()
        else if (_isColaboracionFlow)
          _buildColaboracionWizard()
        else if (_isRequerimientoFlow)
          _buildRequerimientoWizard()
        else if (_isColaboracionCiudadanaFlow)
          _buildColCiudadanaWizard()
        else if (_isAusentismoFlow)
          _buildAusentismoWizard()
        else if (_isGenericEasWizardFlow)
          _buildGenericEasWizard()
        else
          _formPanel(),
      ],
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(height: 20), _previewPanel(preview)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: left),
        const SizedBox(width: 24),
        Expanded(flex: 5, child: _previewPanel(preview)),
      ],
    );
  }

  Widget _buildEasConfigPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: Icons.tune_outlined, title: 'Configuración'),
          const SizedBox(height: 18),
          if (_formacionSeleccionada == null &&
              !_otrasCartillasSeleccionada) ...[
            _Drop<CrtEasStation>(
              value: eas,
              label: 'EAS',
              icon: Icons.location_city_outlined,
              items: CrtCatalog.easStations,
              itemText: (value) => '${value.codigo} - ${value.nombre}',
              onChanged: (value) {
                _invalidatePreview();
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
              onChanged: (value) {
                _invalidatePreview();
                setState(() => movil = value);
              },
            ),
            const SizedBox(height: 14),
            _Drop<RolMovil>(
              value: rolMovil,
              label: 'Que rol cumple usted en el movil',
              icon: Icons.assignment_ind_outlined,
              items: RolMovil.values,
              itemText: (value) => value.label,
              onChanged: (value) {
                _invalidatePreview();
                setState(() {
                  rolMovil = value;
                  _autoFillByRole();
                });
              },
            ),
          ],
        ],
      ),
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
              _invalidatePreview();
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
              _invalidatePreview();
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
              _invalidatePreview();
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
                _invalidatePreview();
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
              _invalidatePreview();
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
              _invalidatePreview();
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
              _invalidatePreview();
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
                _invalidatePreview();
                setState(() {});
              },
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
                  _invalidatePreview();
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
                    _invalidatePreview();
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
              if (value != null) {
                _invalidatePreview();
                setState(() => _desaMovil = value);
              }
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
                  _invalidatePreview();
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
    final sinPolicia = <String, dynamic>{
      'id': 0,
      'nombre': 'Sin servidor policial',
    };
    final otto = <String, dynamic>{'id': -1, 'nombre': 'Otro'};
    final items = [sinPolicia, ..._servidoresPoliciales, otto];

    Map<String, dynamic>? selected;
    if (_desaPoliciaOtro) {
      selected = otto;
    } else if (_desaPoliciaId != null && _desaPoliciaId! > 0) {
      final idx = _servidoresPoliciales.indexWhere(
        (s) => s['id'] == _desaPoliciaId,
      );
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
              _invalidatePreview();
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
                  _invalidatePreview();
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
                  _invalidatePreview();
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
                      _invalidatePreview();
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
                  onTap: () {
                    _invalidatePreview();
                    setState(() => _desaAgresivo = true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceTile(
                  selected: !_desaAgresivo,
                  label: 'No',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    _invalidatePreview();
                    setState(() => _desaAgresivo = false);
                  },
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
                    onTap: () {
                      _invalidatePreview();
                      setState(() => _desaColaboracion = true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoiceTile(
                    selected: !_desaColaboracion,
                    label: 'No',
                    icon: Icons.do_not_disturb_alt_outlined,
                    onTap: () {
                      _invalidatePreview();
                      setState(() => _desaColaboracion = false);
                    },
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
            onPressed: () {
              _invalidatePreview();
              setState(() => _desaSection--);
            },
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
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _desaPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_desaPoliciaId != null) {
      saves.add(crtApi.savePolicia(_desaPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_desaPoliciaOtro && _desaPoliciaNombre.trim().isNotEmpty) {
      _desaPoliciaOtro = false;
      _desaPoliciaCtrl.clear();
      try {
        _servidoresPoliciales = await crtApi.getServidoresPoliciales(_easDbId);
        final nuevo = _servidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
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
        saves.add(
          crtApi
              .crearServidorPolicial(_easDbId, _desaPoliciaNombre.trim())
              .catchError((_) {}),
        );
      } else if (_desaPoliciaId != null) {
        saves.add(crtApi.savePolicia(_desaPoliciaId).catchError((_) {}));
      }
      if (_desaDireccionOtro && _desaDireccion.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearDireccion(_easDbId, _desaDireccion.trim())
              .catchError((_) {}),
        );
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
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
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
          _desaPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
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
          _rtPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
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
          if (_isRequerimientoFlow) {
            _reqDirecciones = direcciones;
          }
          if (_isColaboracionCiudadanaFlow) {
            _ciuDirecciones = direcciones;
          }
          if (_isGenericEasWizardFlow) {
            _ezDirecciones = direcciones;
          }
          if (_isAusentismoFlow) {
            _ausDirecciones = direcciones;
          }
        });
      }
      return direcciones;
    } catch (_) {
      return [];
    }
  }

  Future<void> _cargarDatosGenerico() async {
    setState(() => _ezCargando = true);
    try {
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(_easDbId),
        _cargarDirecciones(),
      ]);
      final cpGuardado = results[0] as String?;
      final policiaData = results[1] as Map<String, dynamic>?;
      final servidores = results[2] as List<Map<String, dynamic>>;
      setState(() {
        _ezCpGuardado = cpGuardado ?? '';
        if (_ezCpGuardado.isNotEmpty) {
          _ezCpCtrl.text = _ezCpGuardado;
          _ezCp = _ezCpGuardado;
        }
        _ezServidoresPoliciales = servidores;
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _ezPoliciaId = pid;
          _ezPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _ezCargando = false);
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
                    _invalidatePreview();
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
              if (value != null) {
                _invalidatePreview();
                setState(() => _rtMovil = value);
              }
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
                    _invalidatePreview();
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin servidor policial'),
                  ),
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
                      _rtPoliciaNombre =
                          _rtServidoresPoliciales.firstWhere(
                                (sp) => sp['id'] == value,
                                orElse: () => <String, dynamic>{},
                              )['nombre']
                              as String? ??
                          '';
                    } else {
                      _rtPoliciaNombre = '';
                    }
                    _rtPoliciaCtrl.clear();
                  });
                },
              ),
              if (_rtPoliciaOtro ||
                  (_rtPoliciaId == null &&
                      _rtPoliciaNombre.isNotEmpty &&
                      !_rtPoliciaOtro))
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
                      _invalidatePreview();
                      setState(() {});
                    },
                  ),
                ),
              if (!_rtPoliciaOtro &&
                  _rtPoliciaId == null &&
                  _rtPoliciaNombre.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: InkWell(
                    onTap: () {
                      _invalidatePreview();
                      setState(() {
                        _rtPoliciaOtro = true;
                        _rtPoliciaId = null;
                      });
                    },
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
                  _invalidatePreview();
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
                      _invalidatePreview();
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
                  _invalidatePreview();
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
                  _invalidatePreview();
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
              _invalidatePreview();
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
              _invalidatePreview();
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
              _invalidatePreview();
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
            onPressed: () {
              _invalidatePreview();
              setState(() => _rtSection--);
            },
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
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _rtPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_rtPoliciaId != null) {
      saves.add(crtApi.savePolicia(_rtPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_rtPoliciaOtro && _rtPoliciaNombre.trim().isNotEmpty) {
      _rtPoliciaOtro = false;
      _rtPoliciaCtrl.clear();
      try {
        _rtServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _rtServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
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
        saves.add(
          crtApi
              .crearServidorPolicial(_easDbId, _rtPoliciaNombre.trim())
              .catchError((_) {}),
        );
      } else if (_rtPoliciaId != null) {
        saves.add(crtApi.savePolicia(_rtPoliciaId).catchError((_) {}));
      }
      if (_rtDireccionOtro && _rtDireccion.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearDireccion(_easDbId, _rtDireccion.trim())
              .catchError((_) {}),
        );
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
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => _rtGuardando = false);
    }
  }

  Widget _buildGenericEasWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tipo.label,
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_ezCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGenericEasStepContent(),
          const SizedBox(height: 24),
          _buildGenericEasNavButtons(),
        ],
      ),
    );
  }

  Widget _buildGenericEasStepContent() {
    if (_ezCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_ezSection == 0) return _buildGenericEasSection1();
    return _buildGenericEasSection2();
  }

  Widget _buildGenericEasSection1() {
    final dirOptions = [
      ..._ezDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _ezDireccionOtro
        ? dirOptions.last
        : (_ezDireccion.isNotEmpty
              ? dirOptions.firstWhere(
                  (d) => d['direccion'] == _ezDireccion,
                  orElse: () => dirOptions.last,
                )
              : null);

    return Column(
      children: [
        if (rolMovil != RolMovil.jp)
          _StepCard(
            step: 1,
            title: 'Nombre del agente JP',
            child: TextFormField(
              controller: _ezJpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del agente JP',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _ezJp = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        _StepCard(
          step: 2,
          title: 'Nombre del conductor CP',
          child: Column(
            children: [
              TextFormField(
                controller: _ezCpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del conductor CP',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ezCp = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              if (_ezCpGuardado.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Último registro: $_ezCpGuardado',
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
        _StepCard(
          step: 3,
          title: 'Servidor policial',
          child: Column(
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _ezPoliciaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Servidor policial',
                  prefixIcon: Icon(Icons.local_police_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin servidor policial'),
                  ),
                  ..._ezServidoresPoliciales.map((sp) {
                    final id = sp['id'] as int?;
                    final nombre = sp['nombre'] as String? ?? '';
                    return DropdownMenuItem(value: id, child: Text(nombre));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _ezPoliciaId = value;
                    if (value != null) {
                      _ezPoliciaOtro = false;
                      _ezPoliciaNombre =
                          _ezServidoresPoliciales.firstWhere(
                                (sp) => sp['id'] == value,
                                orElse: () => <String, dynamic>{},
                              )['nombre']
                              as String? ??
                          '';
                    } else {
                      _ezPoliciaNombre = '';
                    }
                    _ezPoliciaCtrl.clear();
                  });
                },
              ),
              if (_ezPoliciaOtro ||
                  (_ezPoliciaId == null &&
                      _ezPoliciaNombre.isNotEmpty &&
                      !_ezPoliciaOtro))
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _ezPoliciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servidor policial',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _ezPoliciaNombre = v;
                      _invalidatePreview();
                      setState(() {});
                    },
                  ),
                ),
              if (!_ezPoliciaOtro &&
                  _ezPoliciaId == null &&
                  _ezPoliciaNombre.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: InkWell(
                    onTap: () {
                      _invalidatePreview();
                      setState(() {
                        _ezPoliciaOtro = true;
                        _ezPoliciaId = null;
                      });
                    },
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
                  final id = d['id'];
                  return DropdownMenuItem(
                    value: d,
                    child: Text(id is int && id == -1 ? nombre : nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'];
                  _invalidatePreview();
                  if (id is int && id == -1) {
                    setState(() {
                      _ezDireccionOtro = true;
                      _ezDireccion = '';
                    });
                  } else {
                    setState(() {
                      _ezDireccionOtro = false;
                      _ezDireccion = value['direccion'] as String? ?? '';
                    });
                  }
                },
              ),
              if (_ezDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: TextEditingController.fromValue(
                      TextEditingValue(text: _ezDireccion),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _ezDireccion = v;
                      _invalidatePreview();
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
          title: 'Personal auxiliar',
          child: Column(
            children: [
              TextFormField(
                controller: _ezAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ezAux1 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ezAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ezAux2 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericEasSection2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in activeFields) ...[
          _Field(
            controller: _controller(field.key),
            label: field.label,
            icon: _iconFor(field.key),
            minLines: field.minLines,
            required: field.required,
            onChanged: () {
              _invalidatePreview();
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildGenericEasNavButtons() {
    final isLast = _ezSection == 1;
    final isFirst = _ezSection == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () {
              _invalidatePreview();
              setState(() => _ezSection--);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _ezGuardando ? null : () => _generarGenericEas(),
            icon: _ezGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_ezGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _ezIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _ezIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_ezCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_ezCp.trim()).catchError((_) {}));
    }
    if (_ezPoliciaOtro && _ezPoliciaNombre.trim().isNotEmpty) {
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _ezPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_ezPoliciaId != null) {
      saves.add(crtApi.savePolicia(_ezPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_ezPoliciaOtro && _ezPoliciaNombre.trim().isNotEmpty) {
      _ezPoliciaOtro = false;
      _ezPoliciaCtrl.clear();
      try {
        _ezServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _ezServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
        if (nuevo != null) {
          _ezPoliciaId = nuevo['id'] as int?;
          _ezPoliciaNombre = nuevo['nombre'] as String? ?? '';
        }
      } catch (_) {}
    }
    if (_ezDireccionOtro && _ezDireccion.trim().isNotEmpty) {
      try {
        await crtApi.crearDireccion(_easDbId, _ezDireccion.trim());
        _ezDirecciones = await crtApi.getDirecciones(_easDbId);
        _ezDireccionOtro = false;
      } catch (_) {}
    }
    setState(() => _ezSection = 1);
  }

  Future<void> _generarGenericEas() async {
    setState(() => _ezGuardando = true);
    try {
      final value = _buildGenericEasText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => _ezGuardando = false);
    }
  }

  String _buildGenericEasText() {
    final now = DateTime.now();
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: tipo,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        movil: movil,
        rolMovil: rolMovil,
        dotacion: _dotacionSeleccionada.integrantes,
        values: {
          '_ez_jp': _ezJp,
          '_ez_cp': _ezCp,
          '_ez_aux1': _ezAux1,
          '_ez_aux2': _ezAux2,
          '_ez_policia': _ezPoliciaNombre,
          '_ez_direccion': _ezDireccion,
          '_ez_userNombre': widget.user?.nombreCompleto ?? '',
          '_ez_movil': movil,
          for (final entry in controllers.entries) entry.key: entry.value.text,
        },
      ),
    );
  }

  // --- Ausentismo ---

  Future<void> _cargarDatosAusentismo() async {
    setState(() => _ausCargando = true);
    try {
      final results = await Future.wait([
        crtApi.getCp(),
        crtApi.getPolicia(),
        crtApi.getServidoresPoliciales(_easDbId),
        _cargarDirecciones(),
      ]);
      final cpGuardado = results[0] as String?;
      final policiaData = results[1] as Map<String, dynamic>?;
      final servidores = results[2] as List<Map<String, dynamic>>;
      setState(() {
        _ausCpGuardado = cpGuardado ?? '';
        if (_ausCpGuardado.isNotEmpty) {
          _ausCpCtrl.text = _ausCpGuardado;
          _ausCp = _ausCpGuardado;
        }
        _ausServidoresPoliciales = servidores;
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _ausPoliciaId = pid;
          _ausPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _ausCargando = false);
    }
  }

  Widget _buildAusentismoWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.logout_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Permiso de ausentismo',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_ausCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAusentismoStepContent(),
          const SizedBox(height: 24),
          _buildAusentismoNavButtons(),
        ],
      ),
    );
  }

  Widget _buildAusentismoStepContent() {
    if (_ausCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_ausSection == 0) return _buildAusentismoSection1();
    return _buildAusentismoSection2();
  }

  Widget _buildAusentismoSection1() {
    final dirOptions = [
      ..._ausDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _ausDireccionOtro
        ? dirOptions.last
        : (_ausDireccion.isNotEmpty
              ? dirOptions.firstWhere(
                  (d) => d['direccion'] == _ausDireccion,
                  orElse: () => dirOptions.last,
                )
              : null);

    return Column(
      children: [
        if (rolMovil != RolMovil.jp)
          _StepCard(
            step: 1,
            title: 'Nombre del agente JP',
            child: TextFormField(
              controller: _ausJpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del agente JP',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _ausJp = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        _StepCard(
          step: 2,
          title: 'Nombre del conductor CP',
          child: Column(
            children: [
              TextFormField(
                controller: _ausCpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del conductor CP',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ausCp = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              if (_ausCpGuardado.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Último registro: $_ausCpGuardado',
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
        _StepCard(
          step: 3,
          title: 'Servidor policial',
          child: Column(
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _ausPoliciaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Servidor policial',
                  prefixIcon: Icon(Icons.local_police_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin servidor policial'),
                  ),
                  ..._ausServidoresPoliciales.map((sp) {
                    final id = sp['id'] as int?;
                    final nombre = sp['nombre'] as String? ?? '';
                    return DropdownMenuItem(value: id, child: Text(nombre));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _ausPoliciaId = value;
                    if (value != null) {
                      _ausPoliciaOtro = false;
                      _ausPoliciaNombre =
                          _ausServidoresPoliciales.firstWhere(
                                (sp) => sp['id'] == value,
                                orElse: () => <String, dynamic>{},
                              )['nombre']
                              as String? ??
                          '';
                    } else {
                      _ausPoliciaNombre = '';
                    }
                    _ausPoliciaCtrl.clear();
                  });
                },
              ),
              if (_ausPoliciaOtro ||
                  (_ausPoliciaId == null &&
                      _ausPoliciaNombre.isNotEmpty &&
                      !_ausPoliciaOtro))
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _ausPoliciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servidor policial',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _ausPoliciaNombre = v;
                      _invalidatePreview();
                      setState(() {});
                    },
                  ),
                ),
              if (!_ausPoliciaOtro &&
                  _ausPoliciaId == null &&
                  _ausPoliciaNombre.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: InkWell(
                    onTap: () {
                      _invalidatePreview();
                      setState(() {
                        _ausPoliciaOtro = true;
                        _ausPoliciaId = null;
                      });
                    },
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
                  final id = d['id'];
                  return DropdownMenuItem(
                    value: d,
                    child: Text(id is int && id == -1 ? nombre : nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final id = value['id'];
                  _invalidatePreview();
                  if (id is int && id == -1) {
                    setState(() {
                      _ausDireccionOtro = true;
                      _ausDireccion = '';
                    });
                  } else {
                    setState(() {
                      _ausDireccionOtro = false;
                      _ausDireccion = value['direccion'] as String? ?? '';
                    });
                  }
                },
              ),
              if (_ausDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _ausDireccion = v;
                      _invalidatePreview();
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
          title: 'Personal auxiliar',
          child: Column(
            children: [
              TextFormField(
                controller: _ausAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ausAux1 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ausAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ausAux2 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAusentismoSection2() {
    final requiereLugar = [
      'Exámenes médicos',
      'Nacimiento',
      'Paternidad',
      'Maternidad',
      'Estudios',
    ].contains(_ausMotivo);
    final requiereDetalle = [
      'Calamidad doméstica',
      'Otro',
    ].contains(_ausMotivo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepCard(
          step: 6,
          title: 'Tipo de permiso',
          child: DropdownButtonFormField<String>(
            initialValue: _ausTipoPermiso,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.schedule_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Permiso por horas',
                child: Text('Permiso por horas'),
              ),
              DropdownMenuItem(
                value: 'Permiso por días',
                child: Text('Permiso por días'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                _invalidatePreview();
                setState(() => _ausTipoPermiso = v);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        if (_ausTipoPermiso == 'Permiso por horas') ...[
          _StepCard(
            step: 7,
            title: 'Hora de salida',
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _ausHoraSalida,
                );
                if (picked != null) {
                  _invalidatePreview();
                  setState(() => _ausHoraSalida = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_ausHoraSalida.format(context)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _StepCard(
            step: 8,
            title: 'Hora de retorno',
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _ausHoraRetorno,
                );
                if (picked != null) {
                  _invalidatePreview();
                  setState(() => _ausHoraRetorno = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_ausHoraRetorno.format(context)),
              ),
            ),
          ),
        ],
        if (_ausTipoPermiso == 'Permiso por días') ...[
          _StepCard(
            step: 7,
            title: 'Fecha de inicio',
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _ausFechaInicio,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  _invalidatePreview();
                  setState(() => _ausFechaInicio = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_fmtFecha(_ausFechaInicio)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _StepCard(
            step: 8,
            title: 'Fecha de finalización',
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _ausFechaFin,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  _invalidatePreview();
                  setState(() => _ausFechaFin = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_fmtFecha(_ausFechaFin)),
              ),
            ),
          ),
        ],
        if (_ausTipoPermiso == 'Permiso por horas' ||
            _ausTipoPermiso == 'Permiso por días') ...[
          const SizedBox(height: 20),
          _StepCard(
            step: 9,
            title: 'Motivo del permiso',
            child: DropdownButtonFormField<String>(
              initialValue: _ausMotivo.isNotEmpty ? _ausMotivo : null,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.report_problem_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Exámenes médicos',
                  child: Text('Exámenes médicos'),
                ),
                DropdownMenuItem(
                  value: 'Nacimiento',
                  child: Text('Nacimiento'),
                ),
                DropdownMenuItem(
                  value: 'Paternidad',
                  child: Text('Paternidad'),
                ),
                DropdownMenuItem(
                  value: 'Maternidad',
                  child: Text('Maternidad'),
                ),
                DropdownMenuItem(value: 'Estudios', child: Text('Estudios')),
                DropdownMenuItem(
                  value: 'Calamidad doméstica',
                  child: Text('Calamidad doméstica'),
                ),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (v) {
                if (v != null) {
                  _invalidatePreview();
                  setState(() {
                    _ausMotivo = v;
                    _ausLugar = '';
                    _ausDetalle = '';
                    _ausLugarCtrl.clear();
                    _ausDetalleCtrl.clear();
                  });
                }
              },
            ),
          ),
          if (requiereLugar) ...[
            const SizedBox(height: 20),
            _StepCard(
              step: 10,
              title: 'Lugar al que se dirige',
              child: TextFormField(
                controller: _ausLugarCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ausLugar = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ),
          ],
          if (requiereDetalle) ...[
            const SizedBox(height: 20),
            _StepCard(
              step: 10,
              title: 'Detalle del motivo',
              child: TextFormField(
                controller: _ausDetalleCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 5,
                onChanged: (v) {
                  _ausDetalle = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          _StepCard(
            step: 11,
            title: 'Información adicional (opcional)',
            child: TextFormField(
              controller: _ausInfoAdicionalCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.edit_note_outlined),
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
              onChanged: (v) {
                _ausInfoAdicional = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAusentismoNavButtons() {
    final isLast = _ausSection == 1;
    final isFirst = _ausSection == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () {
              _invalidatePreview();
              setState(() => _ausSection--);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _ausGuardando ? null : () => _generarAusentismo(),
            icon: _ausGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_ausGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _ausIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _ausIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_ausCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_ausCp.trim()).catchError((_) {}));
    }
    if (_ausPoliciaOtro && _ausPoliciaNombre.trim().isNotEmpty) {
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _ausPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_ausPoliciaId != null) {
      saves.add(crtApi.savePolicia(_ausPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_ausPoliciaOtro && _ausPoliciaNombre.trim().isNotEmpty) {
      _ausPoliciaOtro = false;
      _ausPoliciaCtrl.clear();
      try {
        _ausServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _ausServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
        if (nuevo != null) {
          _ausPoliciaId = nuevo['id'] as int?;
          _ausPoliciaNombre = nuevo['nombre'] as String? ?? '';
        }
      } catch (_) {}
    }
    if (_ausDireccionOtro && _ausDireccion.trim().isNotEmpty) {
      try {
        await crtApi.crearDireccion(_easDbId, _ausDireccion.trim());
        _ausDirecciones = await crtApi.getDirecciones(_easDbId);
        _ausDireccionOtro = false;
      } catch (_) {}
    }
    setState(() => _ausSection = 1);
  }

  Future<void> _generarAusentismo() async {
    setState(() => _ausGuardando = true);
    try {
      final value = _buildAusentismoText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => _ausGuardando = false);
    }
  }

  String _buildAusentismoText() {
    final now = DateTime.now();
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.permisoAusentismo,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        movil: movil,
        rolMovil: rolMovil,
        dotacion: _dotacionSeleccionada.integrantes,
        values: {
          '_aus_jp': _ausJp,
          '_aus_cp': _ausCp,
          '_aus_aux1': _ausAux1,
          '_aus_aux2': _ausAux2,
          '_aus_policia': _ausPoliciaNombre,
          '_aus_direccion': _ausDireccion,
          '_aus_userNombre': widget.user?.nombreCompleto ?? '',
          '_aus_movil': movil,
          '_aus_tipoPermiso': _ausTipoPermiso,
          '_aus_horaSalida':
              '${_ausHoraSalida.hour.toString().padLeft(2, '0')}:${_ausHoraSalida.minute.toString().padLeft(2, '0')}',
          '_aus_horaRetorno':
              '${_ausHoraRetorno.hour.toString().padLeft(2, '0')}:${_ausHoraRetorno.minute.toString().padLeft(2, '0')}',
          '_aus_fechaInicio': _fmtFecha(_ausFechaInicio),
          '_aus_fechaFin': _fmtFecha(_ausFechaFin),
          '_aus_motivo': _ausMotivo,
          '_aus_lugar': _ausLugar,
          '_aus_detalle': _ausDetalle,
          '_aus_infoAdicional': _ausInfoAdicional,
        },
      ),
    );
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
          '_rt_jp': _rtJp.isNotEmpty
              ? _rtJp
              : (rolMovil == RolMovil.jp
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_rt_movil': movilValue,
          '_rt_cp': _rtCp.isNotEmpty
              ? _rtCp
              : (rolMovil == RolMovil.conductor
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
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
          _colPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
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
                _invalidatePreview();
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
                _invalidatePreview();
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
              const DropdownMenuItem(
                value: null,
                child: Text('Sin servidor policial'),
              ),
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
                  _colPoliciaNombre =
                      _colServidoresPoliciales.firstWhere(
                            (sp) => sp['id'] == value,
                            orElse: () => <String, dynamic>{},
                          )['nombre']
                          as String? ??
                      '';
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
                  _invalidatePreview();
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
                      _invalidatePreview();
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
                  _invalidatePreview();
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
                  _invalidatePreview();
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
              DropdownMenuItem(
                value: 'entidad',
                child: Text('Entidades de colaboración'),
              ),
              DropdownMenuItem(
                value: 'accidente',
                child: Text('Hecho o Accidente'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _colSubtype = value);
              }
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
              DropdownMenuItem(
                value: 'Paramédicos',
                child: Text('Paramédicos'),
              ),
              DropdownMenuItem(
                value: 'Fuerzas Armadas',
                child: Text('Fuerzas Armadas'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _colEntidad = value);
              }
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
              _invalidatePreview();
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
            initialValue: _colTipoAccidente.isNotEmpty
                ? _colTipoAccidente
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de accidente',
              prefixIcon: Icon(Icons.car_crash_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Accidente entre dos vehículos',
                child: Text('Accidente entre dos vehículos'),
              ),
              DropdownMenuItem(
                value: 'Accidente múltiple',
                child: Text('Accidente múltiple'),
              ),
              DropdownMenuItem(
                value: 'Choque y daño al espacio y vía pública',
                child: Text('Choque y daño al espacio y vía pública'),
              ),
              DropdownMenuItem(
                value: 'Accidente entre vehículo y persona',
                child: Text('Accidente entre vehículo y persona'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _colTipoAccidente = value);
              }
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
                  _invalidatePreview();
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
                  _invalidatePreview();
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
                    _invalidatePreview();
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
                    _invalidatePreview();
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
                  DropdownMenuItem(
                    value: 'No intervino',
                    child: Text('No intervino'),
                  ),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _invalidatePreview();
                    setState(() => _colCriminalistica = value);
                  }
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
                    _invalidatePreview();
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
                  DropdownMenuItem(
                    value: 'No estuvo presente',
                    child: Text('No estuvo presente'),
                  ),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _invalidatePreview();
                    setState(() => _colAtm = value);
                  }
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
                    _invalidatePreview();
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
                    _invalidatePreview();
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
                  DropdownMenuItem(
                    value: 'No estuvo presente',
                    child: Text('No estuvo presente'),
                  ),
                  DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _invalidatePreview();
                    setState(() => _colAmbulancia = value);
                  }
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
                    _invalidatePreview();
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
                  _invalidatePreview();
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
                  _invalidatePreview();
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
              _invalidatePreview();
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
                    _invalidatePreview();
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
                    _invalidatePreview();
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
            onPressed: () {
              _invalidatePreview();
              setState(() => _colSection--);
            },
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
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _colPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_colPoliciaId != null) {
      saves.add(crtApi.savePolicia(_colPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_colPoliciaOtro && _colPoliciaNombre.trim().isNotEmpty) {
      _colPoliciaOtro = false;
      _colPoliciaCtrl.clear();
      try {
        _colServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _colServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
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
        saves.add(
          crtApi
              .crearServidorPolicial(_easDbId, _colPoliciaNombre.trim())
              .catchError((_) {}),
        );
      } else if (_colPoliciaId != null) {
        saves.add(crtApi.savePolicia(_colPoliciaId).catchError((_) {}));
      }
      if (_colDireccionOtro && _colDireccion.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearDireccion(_easDbId, _colDireccion.trim())
              .catchError((_) {}),
        );
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
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
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
          '_col_jp': _colJp.isNotEmpty
              ? _colJp
              : (rolMovil == RolMovil.jp
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_col_movil': movilValue,
          '_col_cp': _colCp.isNotEmpty
              ? _colCp
              : (rolMovil == RolMovil.conductor
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
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

  Future<void> _cargarDatosRequerimiento() async {
    setState(() => _reqCargando = true);
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
        _reqCpGuardado = cpGuardado ?? '';
        if (_reqCpGuardado.isNotEmpty) {
          _reqCpCtrl.text = _reqCpGuardado;
          _reqCp = _reqCpGuardado;
        }
        _reqServidoresPoliciales = servidores;
        _reqMovil = _moviles.first.movil;
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _reqPoliciaId = pid;
          _reqPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
      // Silently fail on temp data load
    } finally {
      if (mounted) setState(() => _reqCargando = false);
    }
  }

  Widget _buildRequerimientoWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Requerimiento',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_reqCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRequerimientoStepContent(),
          const SizedBox(height: 24),
          _buildReqNavButtons(),
        ],
      ),
    );
  }

  Widget _buildRequerimientoStepContent() {
    if (_reqCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_reqSection == 0) return _buildReqSection1();
    return _buildReqSection2();
  }

  Widget _buildReqSection1() {
    final dirOptions = [
      ..._reqDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _reqDireccionOtro
        ? dirOptions.last
        : (_reqDireccion.isNotEmpty
              ? dirOptions.firstWhere(
                  (d) => d['direccion'] == _reqDireccion,
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
              controller: _reqJpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del agente JP',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _reqJp = value;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        if (rolMovil != RolMovil.conductor)
          _StepCard(
            step: 2,
            title: 'Nombre del CP',
            child: TextFormField(
              controller: _reqCpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del conductor CP',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _reqCp = value;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.conductor) const SizedBox(height: 20),
        _StepCard(
          step: 3,
          title: 'Servidor policial',
          child: DropdownButtonFormField<int?>(
            initialValue: _reqPoliciaId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servidor policial',
              prefixIcon: Icon(Icons.local_police_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Sin servidor policial'),
              ),
              ..._reqServidoresPoliciales.map((sp) {
                final id = sp['id'] as int?;
                final nombre = sp['nombre'] as String? ?? '';
                return DropdownMenuItem(value: id, child: Text(nombre));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _reqPoliciaId = value;
                if (value != null) {
                  _reqPoliciaOtro = false;
                  _reqPoliciaNombre =
                      _reqServidoresPoliciales.firstWhere(
                            (sp) => sp['id'] == value,
                            orElse: () => <String, dynamic>{},
                          )['nombre']
                          as String? ??
                      '';
                } else {
                  _reqPoliciaNombre = '';
                }
                _reqPoliciaCtrl.clear();
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
                  _invalidatePreview();
                  setState(() {
                    if (id == -1) {
                      _reqDireccionOtro = true;
                      _reqDireccion = '';
                    } else {
                      _reqDireccionOtro = false;
                      _reqDireccion = value['direccion'] as String? ?? '';
                    }
                  });
                },
              ),
              if (_reqDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _reqDireccion = value;
                      _invalidatePreview();
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
                controller: _reqAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _reqAux1 = value;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reqAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _reqAux2 = value;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReqSection2() {
    return Column(
      children: [
        _StepCard(
          step: 6,
          title: 'Solicitante',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _reqSolicitante.isNotEmpty
                    ? _reqSolicitante
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Quién solicita el requerimiento?',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'EAS', child: Text('EAS')),
                  DropdownMenuItem(value: 'CR', child: Text('CR')),
                  DropdownMenuItem(value: 'OJ1', child: Text('OJ1')),
                  DropdownMenuItem(
                    value: 'Jefe de Control Municipal',
                    child: Text('Jefe de Control Municipal'),
                  ),
                  DropdownMenuItem(
                    value: 'Lima Oscar',
                    child: Text('Lima Oscar'),
                  ),
                  DropdownMenuItem(
                    value: 'Sircon Andrade',
                    child: Text('Sircon Andrade'),
                  ),
                  DropdownMenuItem(
                    value: 'Sr. Figallo',
                    child: Text('Sr. Figallo'),
                  ),
                  DropdownMenuItem(
                    value: 'Sr. Alex Anchundia',
                    child: Text('Sr. Alex Anchundia'),
                  ),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _invalidatePreview();
                    setState(() => _reqSolicitante = value);
                  }
                },
              ),
              if (_reqSolicitante == 'Otro')
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    controller: _reqSolicitanteOtroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del solicitante',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _reqSolicitanteOtro = value;
                      _invalidatePreview();
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 7,
          title: 'Tipo de requerimiento',
          child: DropdownButtonFormField<String>(
            initialValue: _reqTipo,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '¿Qué requerimiento realizará?',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Requerimiento',
                child: Text('Requerimiento'),
              ),
              DropdownMenuItem(
                value: 'Punto martillo',
                child: Text('Punto martillo'),
              ),
              DropdownMenuItem(
                value: 'Ronda disuasiva',
                child: Text('Ronda disuasiva'),
              ),
              DropdownMenuItem(
                value: 'Presencia de Agente de Control',
                child: Text('Presencia de Agente de Control'),
              ),
              DropdownMenuItem(
                value: 'Operativo en conjunto',
                child: Text('Operativo en conjunto'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _reqTipo = value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Información adicional',
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Información adicional (opcional)',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            onChanged: (value) {
              _reqInfoAdicional = value;
              _invalidatePreview();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReqNavButtons() {
    final isLast = _reqSection == 1;
    final isFirst = _reqSection == 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () {
              _invalidatePreview();
              setState(() => _reqSection--);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _reqGuardando ? null : () => _generarRequerimiento(),
            icon: _reqGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_reqGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _reqIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _reqIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_reqCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_reqCp.trim()).catchError((_) {}));
    }
    if (_reqPoliciaOtro && _reqPoliciaNombre.trim().isNotEmpty) {
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _reqPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_reqPoliciaId != null) {
      saves.add(crtApi.savePolicia(_reqPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);

    if (_reqPoliciaOtro && _reqPoliciaNombre.trim().isNotEmpty) {
      _reqPoliciaOtro = false;
      _reqPoliciaCtrl.clear();
      try {
        _reqServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _reqServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
        if (nuevo != null) {
          _reqPoliciaId = nuevo['id'] as int?;
        }
      } catch (_) {}
    }
    if (_reqDireccionOtro && _reqDireccion.trim().isNotEmpty) {
      _reqDireccionOtro = false;
      try {
        await crtApi.crearDireccion(_easDbId, _reqDireccion.trim());
        _reqDirecciones = await crtApi.getDirecciones(_easDbId);
        _reqDireccion = _reqDireccion.trim();
      } catch (_) {
        _reqDirecciones = await crtApi.getDirecciones(_easDbId);
      }
    }
    if (mounted) setState(() => _reqSection++);
  }

  Future<void> _generarRequerimiento() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }
    setState(() => _reqGuardando = true);
    try {
      final saves = <Future<void>>[];
      if (_reqCp.trim().isNotEmpty) {
        saves.add(crtApi.saveCp(_reqCp.trim()).catchError((_) {}));
      }
      if (_reqPoliciaOtro && _reqPoliciaNombre.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearServidorPolicial(_easDbId, _reqPoliciaNombre.trim())
              .catchError((_) {}),
        );
      } else if (_reqPoliciaId != null) {
        saves.add(crtApi.savePolicia(_reqPoliciaId).catchError((_) {}));
      }
      if (_reqDireccionOtro && _reqDireccion.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearDireccion(_easDbId, _reqDireccion.trim())
              .catchError((_) {}),
        );
      }
      await Future.wait(saves);
      if (_reqDireccionOtro) _reqDireccionOtro = false;

      final value = _buildRequerimientoText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => _reqGuardando = false);
    }
  }

  String _buildRequerimientoText() {
    final now = DateTime.now();
    final movilValue = _reqMovil.isNotEmpty ? _reqMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.requerimiento,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        rolMovil: rolMovil,
        values: {
          '_req_jp': _reqJp.isNotEmpty
              ? _reqJp
              : (rolMovil == RolMovil.jp
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_req_movil': movilValue,
          '_req_cp': _reqCp.isNotEmpty
              ? _reqCp
              : (rolMovil == RolMovil.conductor
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_req_policia': _reqPoliciaNombre,
          '_req_direccion': _reqDireccion,
          '_req_aux1': _reqAux1,
          '_req_aux2': _reqAux2,
          '_req_userNombre': widget.user?.nombreCompleto ?? '',
          '_req_solicitante': _reqSolicitante == 'Otro'
              ? _reqSolicitanteOtro
              : _reqSolicitante,
          '_req_tipo': _reqTipo,
          '_req_infoAdicional': _reqInfoAdicional,
        },
      ),
    );
  }

  Future<void> _cargarDatosColCiudadana() async {
    setState(() => _ciuCargando = true);
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
        _ciuCpGuardado = cpGuardado ?? '';
        if (_ciuCpGuardado.isNotEmpty) {
          _ciuCpCtrl.text = _ciuCpGuardado;
          _ciuCp = _ciuCpGuardado;
        }
        _ciuServidoresPoliciales = servidores;
        _ciuMovil = _moviles.first.movil;
        _ciuTipoGeneral = 'denuncia';
        _ciuTipoEspecifico = '';
        final pid = policiaData?['servidorPolicialId'] as int?;
        if (pid != null && pid > 0) {
          _ciuPoliciaId = pid;
          _ciuPoliciaNombre = policiaData?['servidorNombre'] as String? ?? '';
        }
      });
    } catch (_) {
      // Silently fail on temp data load
    } finally {
      if (mounted) setState(() => _ciuCargando = false);
    }
  }

  Widget _buildColCiudadanaWizard() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Colaboración ciudadana',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_ciuCargando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildColCiudadanaStepContent(),
          const SizedBox(height: 24),
          _buildCiuNavButtons(),
        ],
      ),
    );
  }

  Widget _buildColCiudadanaStepContent() {
    if (_ciuCargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_ciuSection == 0) return _buildCiuSection1();
    return _buildCiuSection2();
  }

  Widget _buildCiuSection1() {
    final dirOptions = [
      ..._ciuDirecciones.map((d) => d),
      const {'id': -1, 'direccion': 'Otra dirección'},
    ];
    final dirValue = _ciuDireccionOtro
        ? dirOptions.last
        : (_ciuDireccion.isNotEmpty
              ? dirOptions.firstWhere(
                  (d) => d['direccion'] == _ciuDireccion,
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
              controller: _ciuJpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del agente JP',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _ciuJp = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.jp) const SizedBox(height: 20),
        if (rolMovil != RolMovil.conductor)
          _StepCard(
            step: 2,
            title: 'Nombre del CP',
            child: TextFormField(
              controller: _ciuCpCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del conductor CP',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _ciuCp = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (rolMovil != RolMovil.conductor) const SizedBox(height: 20),
        _StepCard(
          step: 3,
          title: 'Servidor policial',
          child: DropdownButtonFormField<int?>(
            initialValue: _ciuPoliciaId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servidor policial',
              prefixIcon: Icon(Icons.local_police_outlined),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Sin servidor policial'),
              ),
              ..._ciuServidoresPoliciales.map((sp) {
                final id = sp['id'] as int?;
                final nombre = sp['nombre'] as String? ?? '';
                return DropdownMenuItem(value: id, child: Text(nombre));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _ciuPoliciaId = value;
                if (value != null) {
                  _ciuPoliciaOtro = false;
                  _ciuPoliciaNombre =
                      _ciuServidoresPoliciales.firstWhere(
                            (sp) => sp['id'] == value,
                            orElse: () => <String, dynamic>{},
                          )['nombre']
                          as String? ??
                      '';
                } else {
                  _ciuPoliciaNombre = '';
                }
                _ciuPoliciaCtrl.clear();
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
                  _invalidatePreview();
                  setState(() {
                    if (id == -1) {
                      _ciuDireccionOtro = true;
                      _ciuDireccion = '';
                    } else {
                      _ciuDireccionOtro = false;
                      _ciuDireccion = value['direccion'] as String? ?? '';
                    }
                  });
                },
              ),
              if (_ciuDireccionOtro)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nueva dirección',
                      prefixIcon: Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _ciuDireccion = v;
                      _invalidatePreview();
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
                controller: _ciuAux1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 1 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ciuAux1 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ciuAux2Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Auxiliar 2 (opcional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _ciuAux2 = v;
                  _invalidatePreview();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 6,
          title: 'Tipo de colaboración',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _ciuTipoGeneral,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Seleccione el tipo',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'denuncia',
                    child: Text('Denuncias Ciudadanas'),
                  ),
                  DropdownMenuItem(
                    value: 'requerimiento',
                    child: Text('Requerimientos Ciudadanos'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _invalidatePreview();
                    setState(() {
                      _ciuTipoGeneral = value;
                      _ciuTipoEspecifico = '';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCiuSection2() {
    if (_ciuTipoGeneral == 'denuncia') return _buildCiuDenunciaForm();
    return _buildCiuRequerimientoForm();
  }

  Widget _buildCiuCitizenFields() {
    return Column(
      children: [
        TextField(
          controller: _ciuNombreCiudadanoCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del ciudadano',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            _ciuNombreCiudadano = v;
            _invalidatePreview();
            setState(() {});
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ciuCedulaCtrl,
          decoration: const InputDecoration(
            labelText: 'Número de cédula',
            prefixIcon: Icon(Icons.credit_card_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            _ciuCedula = v;
            _invalidatePreview();
            setState(() {});
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ciuCelularCtrl,
          decoration: const InputDecoration(
            labelText: 'Número de celular',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            _ciuCelular = v;
            _invalidatePreview();
            setState(() {});
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ciuLugarCtrl,
          decoration: const InputDecoration(
            labelText: 'Lugar de la novedad',
            prefixIcon: Icon(Icons.place_outlined),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            _ciuLugar = v;
            _invalidatePreview();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildCiuDenunciaForm() {
    return Column(
      children: [
        _StepCard(
          step: 7,
          title: 'Tipo de denuncia',
          child: DropdownButtonFormField<String>(
            initialValue: _ciuTipoEspecifico.isNotEmpty
                ? _ciuTipoEspecifico
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de denuncia ciudadana',
              prefixIcon: Icon(Icons.warning_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Robo a mano armada',
                child: Text('Robo a mano armada'),
              ),
              DropdownMenuItem(
                value: 'Pérdida de bien inmueble',
                child: Text('Pérdida de bien inmueble'),
              ),
              DropdownMenuItem(
                value: 'Extorsión a local',
                child: Text('Extorsión a local'),
              ),
              DropdownMenuItem(value: 'Amenazas', child: Text('Amenazas')),
              DropdownMenuItem(
                value: 'Desaparición de persona',
                child: Text('Desaparición de persona'),
              ),
              DropdownMenuItem(
                value: 'Sector o nicho conflictivo',
                child: Text('Sector o nicho conflictivo'),
              ),
              DropdownMenuItem(value: 'Agresión', child: Text('Agresión')),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _ciuTipoEspecifico = value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Datos del ciudadano',
          child: _buildCiuCitizenFields(),
        ),
        const SizedBox(height: 20),
        if (_ciuTipoEspecifico == 'Robo a mano armada')
          _StepCard(
            step: 9,
            title: 'Robo a mano armada',
            child: Column(
              children: [
                TextField(
                  controller: _ciuBienesRobadosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bienes robados',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuBienesRobados = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuValorRobadoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Valor total aproximado',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuValorRobado = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Pérdida de bien inmueble')
          _StepCard(
            step: 9,
            title: 'Pérdida de bien inmueble',
            child: Column(
              children: [
                TextField(
                  controller: _ciuBienesPerdidosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bienes perdidos',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuBienesPerdidos = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuValorPerdidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Valor total aproximado',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuValorPerdido = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Extorsión a local')
          _StepCard(
            step: 9,
            title: 'Extorsión a local',
            child: Column(
              children: [
                TextField(
                  controller: _ciuNombreLocalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del local comercial',
                    prefixIcon: Icon(Icons.store_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuNombreLocal = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuReferenciaLocalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referencia del local',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuReferenciaLocal = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuMotivoExtorsionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la extorsión',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuMotivoExtorsion = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Amenazas')
          _StepCard(
            step: 9,
            title: 'Amenazas',
            child: Column(
              children: [
                TextField(
                  controller: _ciuNombreAmenazanteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la persona que amenaza',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuNombreAmenazante = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuCedulaAmenazanteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de la persona que amenaza',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuCedulaAmenazante = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuTextoAmenazaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frase o texto de la amenaza',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuTextoAmenaza = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Desaparición de persona')
          _StepCard(
            step: 9,
            title: 'Desaparición de persona',
            child: Column(
              children: [
                TextField(
                  controller: _ciuNombreDesaparecidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la persona desaparecida',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuNombreDesaparecido = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuCedulaDesaparecidoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de la persona desaparecida',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuCedulaDesaparecido = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuUltimaUbicacionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación donde fue vista por última vez',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuUltimaUbicacion = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuVestimentaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vestimenta o accesorios que llevaba',
                    prefixIcon: Icon(Icons.checkroom_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuVestimenta = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuAntecedenteCtrl,
                  decoration: const InputDecoration(
                    labelText: '¿Antecedente de amenaza anterior?',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuAntecedente = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Sector o nicho conflictivo')
          _StepCard(
            step: 9,
            title: 'Sector o nicho conflictivo',
            child: Column(
              children: [
                TextField(
                  controller: _ciuMotivoConflictivoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo por el cual el sector es conflictivo',
                    prefixIcon: Icon(Icons.report_problem_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuMotivoConflictivo = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuRequerimientoCiudadanoCtrl,
                  decoration: const InputDecoration(
                    labelText: '¿Qué requiere el ciudadano denunciante?',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuRequerimientoCiudadano = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Agresión')
          _StepCard(
            step: 9,
            title: 'Agresión',
            child: Column(
              children: [
                TextField(
                  controller: _ciuNombreAgresorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del agresor',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuNombreAgresor = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuObjetoAgresionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Objeto con el que agredió',
                    prefixIcon: Icon(Icons.gavel_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuObjetoAgresion = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuDetalleHeridaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Detalle de cómo se produjo la herida',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuDetalleHerida = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCiuRequerimientoForm() {
    return Column(
      children: [
        _StepCard(
          step: 7,
          title: 'Tipo de requerimiento',
          child: DropdownButtonFormField<String>(
            initialValue: _ciuTipoEspecifico.isNotEmpty
                ? _ciuTipoEspecifico
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de requerimiento ciudadano',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Visualizar cámaras',
                child: Text('Visualizar cámaras'),
              ),
              DropdownMenuItem(
                value: 'Colaboración en evento',
                child: Text('Colaboración en evento'),
              ),
              DropdownMenuItem(
                value: 'Resguardo de personal',
                child: Text('Resguardo de personal'),
              ),
              DropdownMenuItem(
                value: 'Colaboración de ATM',
                child: Text('Colaboración de ATM'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _invalidatePreview();
                setState(() => _ciuTipoEspecifico = value);
              }
            },
          ),
        ),
        const SizedBox(height: 20),
        _StepCard(
          step: 8,
          title: 'Datos del ciudadano',
          child: _buildCiuCitizenFields(),
        ),
        const SizedBox(height: 20),
        if (_ciuTipoEspecifico == 'Visualizar cámaras')
          _StepCard(
            step: 9,
            title: 'Visualizar cámaras',
            child: TextField(
              controller: _ciuMotivoCamarasCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo de la visualización de cámaras',
                prefixIcon: Icon(Icons.videocam_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) {
                _ciuMotivoCamaras = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (_ciuTipoEspecifico == 'Colaboración en evento')
          _StepCard(
            step: 9,
            title: 'Colaboración en evento',
            child: Column(
              children: [
                TextField(
                  controller: _ciuNombreEventoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del evento',
                    prefixIcon: Icon(Icons.event_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuNombreEvento = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuFechaEventoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fecha del evento',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuFechaEvento = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuHoraEventoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hora del evento',
                    prefixIcon: Icon(Icons.access_time_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    _ciuHoraEvento = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ciuMotivoEventoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la colaboración',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (v) {
                    _ciuMotivoEvento = v;
                    _invalidatePreview();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (_ciuTipoEspecifico == 'Resguardo de personal')
          _StepCard(
            step: 9,
            title: 'Resguardo de personal',
            child: TextField(
              controller: _ciuMotivoResguardoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo del resguardo',
                prefixIcon: Icon(Icons.shield_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) {
                _ciuMotivoResguardo = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
        if (_ciuTipoEspecifico == 'Colaboración de ATM')
          _StepCard(
            step: 9,
            title: 'Colaboración de ATM',
            child: TextField(
              controller: _ciuMotivoAtmCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo de la presencia de ATM',
                prefixIcon: Icon(Icons.account_balance_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (v) {
                _ciuMotivoAtm = v;
                _invalidatePreview();
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCiuNavButtons() {
    final isLast = _ciuSection == 1;
    final isFirst = _ciuSection == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          OutlinedButton.icon(
            onPressed: () {
              _invalidatePreview();
              setState(() => _ciuSection--);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Anterior'),
          )
        else
          const SizedBox(),
        if (isLast)
          FilledButton.icon(
            onPressed: _ciuGuardando ? null : () => _generarColCiudadana(),
            icon: _ciuGuardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_ciuGuardando ? 'Generando' : 'Generar cartilla'),
          )
        else
          FilledButton.icon(
            onPressed: () => _ciuIrSiguiente(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Siguiente'),
          ),
      ],
    );
  }

  void _ciuIrSiguiente() async {
    final saves = <Future<void>>[];
    if (_ciuCp.trim().isNotEmpty) {
      saves.add(crtApi.saveCp(_ciuCp.trim()).catchError((_) {}));
    }
    if (_ciuPoliciaOtro && _ciuPoliciaNombre.trim().isNotEmpty) {
      saves.add(
        crtApi
            .crearServidorPolicial(_easDbId, _ciuPoliciaNombre.trim())
            .catchError((_) {}),
      );
    } else if (_ciuPoliciaId != null) {
      saves.add(crtApi.savePolicia(_ciuPoliciaId).catchError((_) {}));
    }
    await Future.wait(saves);
    if (_ciuPoliciaOtro && _ciuPoliciaNombre.trim().isNotEmpty) {
      _ciuPoliciaOtro = false;
      _ciuPoliciaCtrl.clear();
      try {
        _ciuServidoresPoliciales = await crtApi.getServidoresPoliciales(
          _easDbId,
        );
        final nuevo = _ciuServidoresPoliciales
            .cast<Map<String, dynamic>?>()
            .lastOrNull;
        if (nuevo != null) _ciuPoliciaId = nuevo['id'] as int?;
      } catch (_) {}
    }
    if (_ciuDireccionOtro && _ciuDireccion.trim().isNotEmpty) {
      _ciuDireccionOtro = false;
      try {
        await crtApi.crearDireccion(_easDbId, _ciuDireccion.trim());
        _ciuDirecciones = await crtApi.getDirecciones(_easDbId);
        _ciuDireccion = _ciuDireccion.trim();
      } catch (_) {
        _ciuDirecciones = await crtApi.getDirecciones(_easDbId);
      }
    }
    if (mounted) setState(() => _ciuSection++);
  }

  Future<void> _generarColCiudadana() async {
    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sesion para generar cartillas')),
      );
      return;
    }
    setState(() => _ciuGuardando = true);
    try {
      final saves = <Future<void>>[];
      if (_ciuCp.trim().isNotEmpty) {
        saves.add(crtApi.saveCp(_ciuCp.trim()).catchError((_) {}));
      }
      if (_ciuPoliciaOtro && _ciuPoliciaNombre.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearServidorPolicial(_easDbId, _ciuPoliciaNombre.trim())
              .catchError((_) {}),
        );
      } else if (_ciuPoliciaId != null) {
        saves.add(crtApi.savePolicia(_ciuPoliciaId).catchError((_) {}));
      }
      if (_ciuDireccionOtro && _ciuDireccion.trim().isNotEmpty) {
        saves.add(
          crtApi
              .crearDireccion(_easDbId, _ciuDireccion.trim())
              .catchError((_) {}),
        );
      }
      await Future.wait(saves);
      if (_ciuDireccionOtro) _ciuDireccionOtro = false;

      final value = _buildColCiudadanaText();
      final result = await InsApi().registrarCartilla(
        contenido: value,
        causa: '${modulo.label} - ${tipo.label}',
      );
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => _ciuGuardando = false);
    }
  }

  String _buildColCiudadanaText() {
    final now = DateTime.now();
    final movilValue = _ciuMovil.isNotEmpty ? _ciuMovil : _moviles.first.movil;
    return CrtTextGenerator.build(
      CrtFormData(
        modulo: TipoModuloCartilla.eas,
        tipo: TipoCartilla.colaboracionEventos,
        jornada: CrtCatalog.jornadaActual(now),
        horario: CrtCatalog.horarioActual(now),
        fecha: _fmtFecha(now),
        hora: _fmtHora(now),
        eas: eas,
        rolMovil: rolMovil,
        values: {
          '_ciu_jp': _ciuJp.isNotEmpty
              ? _ciuJp
              : (rolMovil == RolMovil.jp
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_ciu_movil': movilValue,
          '_ciu_cp': _ciuCp.isNotEmpty
              ? _ciuCp
              : (rolMovil == RolMovil.conductor
                    ? (widget.user?.nombreCompleto ?? '')
                    : ''),
          '_ciu_policia': _ciuPoliciaNombre,
          '_ciu_direccion': _ciuDireccion,
          '_ciu_aux1': _ciuAux1,
          '_ciu_aux2': _ciuAux2,
          '_ciu_userNombre': widget.user?.nombreCompleto ?? '',
          '_ciu_tipoGeneral': _ciuTipoGeneral,
          '_ciu_tipoEspecifico': _ciuTipoEspecifico,
          '_ciu_nombreCiudadano': _ciuNombreCiudadano,
          '_ciu_cedula': _ciuCedula,
          '_ciu_celular': _ciuCelular,
          '_ciu_lugar': _ciuLugar,
          '_ciu_bienesRobados': _ciuBienesRobados,
          '_ciu_valorRobado': _ciuValorRobado,
          '_ciu_bienesPerdidos': _ciuBienesPerdidos,
          '_ciu_valorPerdido': _ciuValorPerdido,
          '_ciu_nombreLocal': _ciuNombreLocal,
          '_ciu_referenciaLocal': _ciuReferenciaLocal,
          '_ciu_motivoExtorsion': _ciuMotivoExtorsion,
          '_ciu_nombreAmenazante': _ciuNombreAmenazante,
          '_ciu_cedulaAmenazante': _ciuCedulaAmenazante,
          '_ciu_textoAmenaza': _ciuTextoAmenaza,
          '_ciu_nombreDesaparecido': _ciuNombreDesaparecido,
          '_ciu_ultimaUbicacion': _ciuUltimaUbicacion,
          '_ciu_cedulaDesaparecido': _ciuCedulaDesaparecido,
          '_ciu_vestimenta': _ciuVestimenta,
          '_ciu_antecedente': _ciuAntecedente,
          '_ciu_motivoConflictivo': _ciuMotivoConflictivo,
          '_ciu_requerimientoCiudadano': _ciuRequerimientoCiudadano,
          '_ciu_nombreAgresor': _ciuNombreAgresor,
          '_ciu_objetoAgresion': _ciuObjetoAgresion,
          '_ciu_detalleHerida': _ciuDetalleHerida,
          '_ciu_motivoCamaras': _ciuMotivoCamaras,
          '_ciu_nombreEvento': _ciuNombreEvento,
          '_ciu_horaEvento': _ciuHoraEvento,
          '_ciu_fechaEvento': _ciuFechaEvento,
          '_ciu_motivoEvento': _ciuMotivoEvento,
          '_ciu_motivoResguardo': _ciuMotivoResguardo,
          '_ciu_motivoAtm': _ciuMotivoAtm,
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
            if (modulo != TipoModuloCartilla.eas) const SizedBox(height: 14),
            _Field(
              controller: _controller('direccion'),
              label: 'Dirección',
              icon: Icons.place_outlined,
              required: false,
              onChanged: () {
                _invalidatePreview();
                setState(() {});
              },
            ),
            const SizedBox(height: 14),
            for (final field in activeFields) ...[
              _Field(
                controller: _controller(field.key),
                label: field.label,
                icon: _iconFor(field.key),
                minLines: field.minLines,
                required: field.required,
                onChanged: () {
                  _invalidatePreview();
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
            ],
            _Field(
              controller: _controller('reporta'),
              label: 'Persona que reporta',
              icon: Icons.badge_outlined,
              required: modulo != TipoModuloCartilla.eas,
              onChanged: () {
                _invalidatePreview();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPanel(String? value) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(
            icon: Icons.preview_outlined,
            title: 'Vista previa',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (value != null) ...[
                  FilledButton.icon(
                    onPressed: guardando ? null : () => _generar(value),
                    icon: guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.copy_outlined),
                    label: Text(guardando ? 'Guardando' : 'Crear cartilla'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _previewText = null;
                      _invalidatePreview();
                      setState(() {});
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Seguir editando'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: guardando ? null : () => _doPreview(),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Generar vista previa'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (value != null)
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
            )
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 560),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Complete el formulario y presione "Generar vista previa"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppThm.secClr, fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _invalidatePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _previewText = _buildText());
      }
    });
  }

  void _doPreview() {
    _previewDebounce?.cancel();
    _previewText = _buildText();
    setState(() {});
  }

  Future<void> _generar(String value) async {
    if (formKey.currentState != null && !formKey.currentState!.validate()) {
      return;
    }
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
            'Cartilla generada: total ${result.totalCartillasGeneradas}',
          ),
          action: SnackBarAction(
            label: 'Compartir',
            onPressed: () => Share.share(value),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      final insignia = result.insigniaDesbloqueada;
      if (insignia != null) {
        await _showBadgeDialog(
          insignia,
          totalCartillas: result.totalCartillasGeneradas,
          nombreUsuario: widget.user?.nombreCompleto ?? '',
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la cartilla: $error')),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> _showBadgeDialog(
    InsigniaDesbloqueadaMdl insignia, {
    int? totalCartillas,
    String? nombreUsuario,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeUnlockDialog(
        insignia: insignia,
        totalCartillas: totalCartillas,
        nombreUsuario: nombreUsuario,
      ),
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
    if (_isRequerimientoFlow) {
      return _buildRequerimientoText();
    }
    if (_isColaboracionCiudadanaFlow) {
      return _buildColCiudadanaText();
    }
    if (_isAusentismoFlow) {
      return _buildAusentismoText();
    }
    if (_isGenericEasWizardFlow) {
      return _buildGenericEasText();
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
    final movilValue = _desaMovil.isNotEmpty
        ? _desaMovil
        : _moviles.first.movil;
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
    final movilValue = _desaMovil.isNotEmpty
        ? _desaMovil
        : _moviles.first.movil;
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
    final movilValue = _desaMovil.isNotEmpty
        ? _desaMovil
        : _moviles.first.movil;
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
    } else if (_isRequerimientoFlow) {
      _cargarDatosRequerimiento();
    } else if (_isColaboracionCiudadanaFlow) {
      _cargarDatosColCiudadana();
    } else if (_isAusentismoFlow) {
      _cargarDatosAusentismo();
    } else if (_isGenericEasWizardFlow) {
      _cargarDatosGenerico();
    } else if (_isDesalojoFlow ||
        _isPuntoMartilloFlow ||
        _isRondasDisuasivasFlow) {
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
    _reqCpCtrl.text = '';
    _reqJpCtrl.text = '';
    _reqAux1Ctrl.text = '';
    _ciuCpCtrl.text = '';
    _ciuJpCtrl.text = '';
    _ciuAux1Ctrl.text = '';
    _ezCpCtrl.text = '';
    _ezJpCtrl.text = '';
    _ezAux1Ctrl.text = '';
    _ausCpCtrl.text = '';
    _ausJpCtrl.text = '';
    _ausAux1Ctrl.text = '';
    switch (rolMovil) {
      case RolMovil.jp:
        _desaJpCtrl.text = name;
        _rtJpCtrl.text = name;
        _colJpCtrl.text = name;
        _reqJpCtrl.text = name;
        _ciuJpCtrl.text = name;
        _ezJpCtrl.text = name;
        _ausJpCtrl.text = name;
        break;
      case RolMovil.conductor:
        _desaCpCtrl.text = name;
        _rtCpCtrl.text = name;
        _colCpCtrl.text = name;
        _reqCpCtrl.text = name;
        _ciuCpCtrl.text = name;
        _ezCpCtrl.text = name;
        _ausCpCtrl.text = name;
        break;
      case RolMovil.auxiliar:
        _desaAuxCtrl.text = name;
        _rtAux1Ctrl.text = name;
        _colAux1Ctrl.text = name;
        _reqAux1Ctrl.text = name;
        _ciuAux1Ctrl.text = name;
        _ezAux1Ctrl.text = name;
        _ausAux1Ctrl.text = name;
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
    _reqJp = _reqJpCtrl.text;
    _reqCp = _reqCpCtrl.text;
    _reqAux1 = _reqAux1Ctrl.text;
    _ciuJp = _ciuJpCtrl.text;
    _ciuCp = _ciuCpCtrl.text;
    _ciuAux1 = _ciuAux1Ctrl.text;
    _ezJp = _ezJpCtrl.text;
    _ezCp = _ezCpCtrl.text;
    _ezAux1 = _ezAux1Ctrl.text;
    _ausJp = _ausJpCtrl.text;
    _ausCp = _ausCpCtrl.text;
    _ausAux1 = _ausAux1Ctrl.text;
  }

  TextEditingController _controller(String key) {
    return controllers.putIfAbsent(key, () => TextEditingController());
  }

  IconData _iconFor(String key) {
    if (key.contains('movil') || key == 'vehiculo') {
      return Icons.directions_car_outlined;
    }
    if (key.contains('personal') || key.contains('agente')) {
      return Icons.groups_outlined;
    }
    if (key.contains('punto') ||
        key.contains('sector') ||
        key.contains('lugar')) {
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
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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

  const _PanelTitle({required this.icon, required this.title});

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

  const _InfoLine({required this.icon, required this.text});

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
