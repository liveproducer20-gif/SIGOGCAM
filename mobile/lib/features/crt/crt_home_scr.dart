import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import 'mdl/crt_enums.dart';
import 'mdl/crt_models.dart';
import 'svc/crt_api.dart';
import 'svc/crt_catalog.dart';
import 'svc/crt_text_generator.dart';
import 'wdg/cartilla_type_selector.dart';
import 'wdg/crt_widgets.dart';

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
      final ap = (jefe?['apellidos'] as String? ?? '').trim();
      final nm = (jefe?['nombres'] as String? ?? '').trim();
      CrtTextGenerator.jefeNombre =
          ap.isNotEmpty && nm.isNotEmpty ? '$ap $nm' : '';
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
      ),
    ];
  }

  List<Widget> _formPanelChildren() {
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
        onPressed: () => setState(() => _formExpanded = false),
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
