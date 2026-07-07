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

  CrtModuleConfig get config => CrtCatalog.configFor(modulo);
  List<CrtFieldConfig> get activeFields => CrtCatalog.fieldsFor(modulo, tipo);

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
              if (isWide)
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

  Widget _formPanel() {
    return _Panel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelTitle(
              icon: Icons.tune_outlined,
              title: 'Configuracion',
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
                label: 'Movil asignado',
                icon: Icons.directions_car_outlined,
                items: _moviles.map((item) => item.movil).toList(),
                itemText: (value) => 'Movil $value',
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
