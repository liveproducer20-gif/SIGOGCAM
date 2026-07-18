import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../ins/ins_api.dart';
import 'mdl/crt_enums.dart';
import 'mdl/crt_models.dart';
import 'svc/crt_api.dart';
import 'svc/crt_catalog.dart';
import 'svc/crt_text_generator.dart';
import 'wdg/cartilla_type_selector.dart';
import 'wdg/crt_widgets.dart';
import 'mdl/crt_special_models.dart';
import 'wdg/formacion_form.dart';
import 'wdg/formacion_entrante_redesign.dart';

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
  TipoModuloCartilla modulo = TipoModuloCartilla.eas;
  TipoCartilla tipo = TipoCartilla.desalojoVendedores;
  CrtEasStation eas = CrtCatalog.easStations.first;
  String movil = '';
  bool _formExpanded = false;
  TipoFormacion? _tipoFormacion;
  String _previewText = '';
  bool _generando = false;

  final crtApi = CrtApi();

  String? get _selectedCartillaId {
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

  @override
  void initState() {
    super.initState();
    _cargarJefe();
  }

  Future<void> _cargarJefe() async {
    try {
      final jefe = await crtApi.getJefeControlMunicipal();
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1050;
    final isTablet = width >= 800 && width < 1050;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: isWide
            ? _buildWideLayout()
            : isTablet
            ? _buildTabletLayout()
            : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    final leftFlex = 45;
    final rightFlex = 55;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: leftFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 12, 28),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _formExpanded
                  ? _formPanelChildren()
                  : _selectorPanelChildren(true),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: rightFlex,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 28, 28, 28),
            child: _buildPlaceholderPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _formExpanded
            ? _formPanelChildren()
            : _selectorPanelChildren(false),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _formExpanded
            ? _formPanelChildren()
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
        canView: true,
        canCreateFormation: true,
      ),
    ];
  }

  List<Widget> _formPanelChildren() {
    if (_tipoFormacion != null) {
      return [
        _buildBackButton(),
        const SizedBox(height: 12),
        if (_tipoFormacion == TipoFormacion.entrante) ...[
          FormacionEntranteRedesign(
            user: widget.user,
            jefeNombre: CrtTextGenerator.jefeDisplay,
            onPreviewChanged: (text) => setState(() => _previewText = text),
            onGenerate: _generarCartilla,
            generando: _generando,
          ),
        ] else ...[
          _buildFormacionHeader(),
          const SizedBox(height: 16),
          FormacionForm(
            tipoFormacion: _tipoFormacion!,
            user: widget.user,
            jefeNombre: CrtTextGenerator.jefeDisplay,
            onPreviewChanged: (text) => setState(() => _previewText = text),
            onGenerate: _generarCartilla,
            generando: _generando,
          ),
        ],
      ];
    }
    return [
      _buildBackButton(),
      const SizedBox(height: 12),
      CrtCompactHeader(
        child: Row(
          children: [
            _buildModuloSelectorCompact(),
            const SizedBox(width: 12),
            if (modulo == TipoModuloCartilla.eas)
              Expanded(
                child: _Drop<CrtEasStation>(
                  value: eas,
                  label: 'Distrito',
                  icon: Icons.location_city_outlined,
                  items: CrtCatalog.easStations,
                  itemText: (value) => '${value.codigo} - ${value.nombre}',
                  onChanged: (value) => setState(() => eas = value),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildPlaceholder(),
    ];
  }

  Widget _buildBackButton() {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: () => setState(() {
          _formExpanded = false;
          _tipoFormacion = null;
          _previewText = '';
        }),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver a tipos de cartilla'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppThm.priClr,
          side: const BorderSide(color: AppThm.priClr),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFormacionHeader() {
    final titulo = _tipoFormacion == TipoFormacion.entrante
        ? 'FORMACION ENTRANTE'
        : 'FORMACION SALIENTE';
    final icono = _tipoFormacion == TipoFormacion.entrante
        ? Icons.login_outlined
        : Icons.logout_outlined;
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icono, color: AppThm.priClr, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppThm.priClr,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (_generando)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarCartilla() async {
    if (_generando || _previewText.isEmpty || _tipoFormacion == null) return;
    setState(() => _generando = true);
    try {
      final insApi = InsApi();
      final result = await insApi.registrarCartilla(
        tipo: 'FORMACION',
        subtipo: _tipoFormacion!.causa,
        causa: _tipoFormacion!.causa,
        contenido: _previewText,
        datos: {'tipo_formacion': _tipoFormacion!.causa},
      );
      if (!mounted) return;

      if (result.insigniaDesbloqueada != null) {
        final badge = result.insigniaDesbloqueada!;
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(badge.titulo),
                ],
              ),
              content: Text(badge.mensaje),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cartilla #$result.cartillaId generada '
              '(${result.totalCartillasGeneradas} total)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _formExpanded = false;
          _tipoFormacion = null;
          _previewText = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  Widget _buildModuloSelectorCompact() {
    return Expanded(
      child: _Drop<TipoModuloCartilla>(
        value: modulo,
        label: 'Modulo',
        icon: Icons.dashboard_customize_outlined,
        items: TipoModuloCartilla.values,
        itemText: (value) => value.label,
        onChanged: (value) {
          setState(() {
            modulo = value;
            final tipos = CrtCatalog.configFor(modulo).tipos;
            if (!tipos.contains(tipo)) tipo = tipos.first;
            if (modulo == TipoModuloCartilla.eas) {
              movil = CrtCatalog.dotacionEas[eas.codigo]?.first.movil ?? '';
            }
          });
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Formulario pendiente de implementacion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tipo: ${tipo.label}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPreview() {
    if (_tipoFormacion != null && _previewText.isNotEmpty) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.preview_outlined,
                    color: AppThm.priClr,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VISTA PREVIA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppThm.priClr,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (!_generando)
                    FilledButton.icon(
                      onPressed: _generarCartilla,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('GENERAR CARTILLA'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppThm.priClr,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _previewText,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.preview_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Vista previa pendiente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCartillaTypeSelected(String id) {
    setState(() {
      switch (id) {
        case 'formacion_entrante':
          _tipoFormacion = TipoFormacion.entrante;
        case 'formacion_saliente':
          _tipoFormacion = TipoFormacion.saliente;
        case 'desalojo_vendedores':
          tipo = TipoCartilla.desalojoVendedores;
        case 'punto_martillo':
          tipo = TipoCartilla.puntoMartillo;
        case 'rondas_disuasivas':
          tipo = TipoCartilla.rondasDisuasivas;
        case 'retiro_temporal':
          tipo = TipoCartilla.retiroTemporal;
        case 'requerimiento':
          tipo = TipoCartilla.requerimiento;
        case 'colaboracion_entidades':
          tipo = TipoCartilla.colaboracionEntidades;
        case 'colaboracion_ciudadana':
          tipo = TipoCartilla.colaboracionEventos;
        case 'permiso_ausentismo':
          tipo = TipoCartilla.permisoAusentismo;
        default:
          break;
      }
      _formExpanded = true;
    });
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Drop<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final List<T> items;
  final String Function(T) itemText;
  final ValueChanged<T>? onChanged;

  const _Drop({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.itemText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(itemText(e))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged?.call(v);
      },
    );
  }
}
