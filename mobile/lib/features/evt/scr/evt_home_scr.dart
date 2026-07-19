import 'package:flutter/material.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/pdf/pdf_preview.dart';
import '../../../core/thm/app_thm.dart';
import '../../../core/url/open_url.dart';
import '../../../core/wdg/responsive.dart';
import '../../adm/adm_design_tokens.dart';
import '../../dash/wdg/page_ttl_wdg.dart';
import '../../dash/wdg/top_bar_wdg.dart';
import '../ann/scr/ann_home_scr.dart';
import '../data/mdl/evt_tipo_mdl.dart';
import '../mdl/evt_mdl.dart';
import '../new/scr/evt_new_scr.dart';
import '../svc/evt_svc.dart';
import '../wdg/evt_fil_wdg.dart';
import '../wdg/evt_overview_wdg.dart';
import '../wdg/evt_estado_style.dart';
import '../../../shared/slc/prs_slc_dlg.dart';
import '../../../shared/slc/prs_slc_mdl.dart';

class EvtHomeScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;
  final int initialTab;
  final int? focusAnnId;
  final bool showBack;

  const EvtHomeScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
    this.initialTab = 0,
    this.focusAnnId,
    this.showBack = false,
  });

  @override
  State<EvtHomeScr> createState() => _EvtHomeScrState();
}

class _EvtHomeScrState extends State<EvtHomeScr>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late bool _eventsOpened;
  late bool _announcementsOpened;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, 1);
    _eventsOpened = initial == 0;
    _announcementsOpened = initial == 1;
    _tabController = TabController(
      length: 2,
      initialIndex: initial,
      vsync: this,
    )..addListener(_openSelectedTab);
  }

  void _openSelectedTab() {
    final index = _tabController.index;
    if ((index == 0 && !_eventsOpened) ||
        (index == 1 && !_announcementsOpened)) {
      setState(() {
        if (index == 0) _eventsOpened = true;
        if (index == 1) _announcementsOpened = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_openSelectedTab)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: TopBarWdg(
        ttl: 'Eventos y anuncios',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
        leading: widget.showBack
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Salir',
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: AppResponsive.pagePadding(context).left,
              top: 12,
              right: AppResponsive.pagePadding(context).right,
            ),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: AdmTokens.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AdmTokens.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                labelColor: AdmTokens.primary,
                unselectedLabelColor: AdmTokens.grey500,
                indicatorColor: AdmTokens.secondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.event_outlined), text: 'Eventos'),
                  Tab(icon: Icon(Icons.campaign_outlined), text: 'Anuncios'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _eventsOpened
                    ? _EvtLst(user: widget.user)
                    : const SizedBox.shrink(),
                _announcementsOpened
                    ? AnnHomeScr(
                        user: widget.user,
                        focusAnnId: widget.focusAnnId,
                        showExit: widget.showBack && widget.focusAnnId != null,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvtLst extends StatefulWidget {
  final AppUser user;

  const _EvtLst({required this.user});

  @override
  State<_EvtLst> createState() => _EvtLstState();
}

class _EvtLstState extends State<_EvtLst> {
  late Future<List<EvtMdl>> eventosFuture;
  String buscar = '';
  String estado = 'Todos';
  String tipo = 'Todos';
  String lugar = '';
  String prioridad = 'Todas';
  DateTime? fecha;

  @override
  void initState() {
    super.initState();
    eventosFuture = _loadEventos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EvtMdl>>(
      future: eventosFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final items = _filtrar(snapshot.data ?? []);

        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AppResponsive.pagePadding(context),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final createButton = FilledButton.icon(
                  onPressed: _crearEvento,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuevo evento'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(150, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                final title = PageTtlWdg(
                  ttl: widget.user.puedeGestionarEventos
                      ? 'Gestión de eventos'
                      : 'Eventos programados',
                  sub: widget.user.puedeGestionarEventos
                      ? 'Planifica, publica y supervisa la participación institucional.'
                      : 'Consulta tus convocatorias y toda la información disponible.',
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      if (widget.user.puedeGestionarEventos) ...[
                        const SizedBox(height: 16),
                        createButton,
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    if (widget.user.puedeGestionarEventos) createButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            EvtStatsWdg(items: snapshot.data ?? const []),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdmTokens.surface,
                borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
                border: Border.all(color: AdmTokens.grey100),
                boxShadow: AdmTokens.cardShadow,
              ),
              child: EvtFilWdg(
                admin: widget.user.puedeGestionarEventos,
                onBuscar: (v) =>
                    setState(() => buscar = v.trim().toLowerCase()),
                onEstado: (v) => setState(() => estado = v),
                onTipo: (v) => setState(() => tipo = v),
                onLugar: (v) => setState(() => lugar = v.trim().toLowerCase()),
                onPrioridad: (v) => setState(() => prioridad = v),
                onFecha: (v) => setState(() => fecha = v),
              ),
            ),
            const SizedBox(height: 18),
            if (loading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              SizedBox(
                height: 260,
                child: Center(
                  child: Text(
                    'No se pudieron cargar los eventos: ${snapshot.error}',
                  ),
                ),
              )
            else
              EvtOverviewWdg(
                items: items,
                canManage: widget.user.puedeGestionarEventos,
                onEstado: _cambiarEstado,
                onEditar: _editarEvento,
                onEliminar: _eliminarEvento,
              ),
          ],
        );
      },
    );
  }

  Future<void> _crearEvento() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EvtNewScr(creadoPor: widget.user.id)),
    );

    if (!mounted) return;
    if (creado == true) {
      setState(() {
        eventosFuture = Future<List<EvtMdl>>.delayed(
          const Duration(milliseconds: 250),
          _loadEventos,
        );
      });
    }
  }

  Future<List<EvtMdl>> _loadEventos() {
    return EvtSvc.getLst(
      personalId: widget.user.soloEventosConvocados ? widget.user.id : null,
      marcarVisto: widget.user.soloEventosConvocados,
    );
  }

  List<EvtMdl> _filtrar(List<EvtMdl> items) {
    return items.where((evt) {
      final matchBuscar =
          buscar.isEmpty ||
          evt.nom.toLowerCase().contains(buscar) ||
          evt.tipo.toLowerCase().contains(buscar) ||
          evt.estado.toLowerCase().contains(buscar);
      final matchEstado = estado == 'Todos' || evt.estado == estado;
      final matchTipo = tipo == 'Todos' || _norm(evt.tipo) == _norm(tipo);
      final matchLugar =
          lugar.isEmpty || evt.lugar.toLowerCase().contains(lugar);
      final matchPrioridad =
          prioridad == 'Todas' || _norm(evt.prioridad) == _norm(prioridad);
      final eventDate = DateTime.tryParse(evt.fechaInicioRaw);
      final matchFecha =
          fecha == null ||
          (eventDate != null &&
              eventDate.year == fecha!.year &&
              eventDate.month == fecha!.month &&
              eventDate.day == fecha!.day);

      return matchBuscar &&
          matchEstado &&
          matchTipo &&
          matchLugar &&
          matchPrioridad &&
          matchFecha;
    }).toList();
  }

  String _norm(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('\u{FFFD}', 'o');
  }

  Future<void> _cambiarEstado(EvtMdl evt, String nuevoEstado) async {
    try {
      await EvtSvc.cambiarEstado(evt.id, nuevoEstado);

      if (!mounted) return;
      setState(() {
        evt.estado = nuevoEstado;
        eventosFuture = _loadEventos();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _editarEvento(EvtMdl evt) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EvtEditDlg(evt: evt),
    );

    if (data == null) return;

    try {
      await EvtSvc.actualizarEvento(evt.id, data);
      if (!mounted) return;
      setState(() => eventosFuture = _loadEventos());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento actualizado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _eliminarEvento(EvtMdl evt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('Se eliminará "${evt.nom}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await EvtSvc.eliminarEvento(evt.id);
      if (!mounted) return;
      setState(() => eventosFuture = _loadEventos());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado exitosamente')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _EvtEditDlg extends StatefulWidget {
  final EvtMdl evt;

  const _EvtEditDlg({required this.evt});

  @override
  State<_EvtEditDlg> createState() => _EvtEditDlgState();
}

class _EvtEditDlgState extends State<_EvtEditDlg> {
  final tituloCtl = TextEditingController();
  final mapsCtl = TextEditingController();
  final fechaCtl = TextEditingController();
  final horaIniCtl = TextEditingController();
  final horaFinCtl = TextEditingController();
  final descCtl = TextEditingController();
  int? tipoId;
  String prioridad = 'Normal';
  List<PrsSlcMdl>? personalSeleccionado;

  @override
  void initState() {
    super.initState();
    tituloCtl.text = widget.evt.nom;
    mapsCtl.text = widget.evt.lugar;
    descCtl.text = widget.evt.descripcion;
    tipoId = widget.evt.tipoId == 0 ? null : widget.evt.tipoId;
    fechaCtl.text = _formatDate(_parseDate(widget.evt.fechaInicioRaw));
    horaIniCtl.text = _formatTime(_parseDate(widget.evt.fechaInicioRaw));
    horaFinCtl.text = _formatTime(_parseDate(widget.evt.fechaFinRaw));
    prioridad = _normalizePrioridad(widget.evt.prioridad);
  }

  @override
  void dispose() {
    tituloCtl.dispose();
    mapsCtl.dispose();
    fechaCtl.dispose();
    horaIniCtl.dispose();
    horaFinCtl.dispose();
    descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar evento'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: tituloCtl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del evento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<EvtTipoMdl>>(
                future: EvtSvc.getTipos(),
                builder: (context, snapshot) {
                  final tipos = snapshot.data ?? [];
                  final selected = tipos.where((e) => e.id == tipoId).isNotEmpty
                      ? tipos.firstWhere((e) => e.id == tipoId)
                      : null;

                  return DropdownButtonFormField<EvtTipoMdl>(
                    initialValue: selected,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento',
                      border: OutlineInputBorder(),
                    ),
                    items: tipos
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => tipoId = v?.id),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fechaCtl,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        suffixIcon: Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: horaIniCtl,
                      readOnly: true,
                      onTap: () => _pickTime(isInicio: true),
                      decoration: const InputDecoration(
                        labelText: 'Hora inicio',
                        suffixIcon: Icon(Icons.schedule_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: horaFinCtl,
                      readOnly: true,
                      onTap: () => _pickTime(isInicio: false),
                      decoration: const InputDecoration(
                        labelText: 'Hora fin',
                        suffixIcon: Icon(Icons.schedule_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mapsCtl,
                decoration: const InputDecoration(
                  labelText: 'Dirección GPS Google Maps',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: prioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(
                    value: 'Importante',
                    child: Text('Importante'),
                  ),
                  DropdownMenuItem(value: 'Urgente', child: Text('Urgente')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => prioridad = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectPersonal,
                icon: const Icon(Icons.groups_outlined),
                label: Text(
                  personalSeleccionado == null
                      ? 'Mantener personal asignado (${widget.evt.convocados})'
                      : 'Personal seleccionado: ${personalSeleccionado!.length}',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (tituloCtl.text.trim().isEmpty || tipoId == null) return;

    final data = <String, dynamic>{
      'titulo': tituloCtl.text.trim(),
      'tipoEventoId': tipoId,
      'fechaInicio': _buildDateTime(fechaCtl.text, horaIniCtl.text),
      'fechaFin': _buildDateTime(fechaCtl.text, horaFinCtl.text),
      'lugar': mapsCtl.text.trim(),
      'descripcion': descCtl.text.trim(),
      'prioridad': prioridad,
    };

    if (personalSeleccionado != null) {
      data['personalIds'] = personalSeleccionado!.map((e) => e.id).toList();
    }

    Navigator.pop(context, data);
  }

  Future<void> _selectPersonal() async {
    final result = await showDialog<List<PrsSlcMdl>>(
      context: context,
      builder: (_) => const PrsSlcDlg(),
    );

    if (result == null) return;
    setState(() => personalSeleccionado = result);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _parseInputDate(fechaCtl.text) ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (selected == null) return;
    setState(() => fechaCtl.text = _formatDate(selected));
  }

  Future<void> _pickTime({required bool isInicio}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _parseInputTime(
        isInicio ? horaIniCtl.text : horaFinCtl.text,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selected == null) return;
    final hour = selected.hour.toString().padLeft(2, '0');
    final minute = selected.minute.toString().padLeft(2, '0');
    final value = '$hour:$minute';
    setState(() {
      if (isInicio) {
        horaIniCtl.text = value;
      } else {
        horaFinCtl.text = value;
      }
    });
  }

  DateTime? _parseDate(String value) => DateTime.tryParse(value);

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseInputDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  TimeOfDay _parseInputTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _buildDateTime(String fecha, String hora) {
    final date = _parseInputDate(fecha);
    if (date == null) throw Exception('Fecha inválida');
    final cleanHora = hora.trim().isEmpty ? '00:00' : hora.trim();
    final isoDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$isoDate ${cleanHora.length == 5 ? '$cleanHora:00' : cleanHora}';
  }

  String _normalizePrioridad(String value) {
    final clean = value.toLowerCase();
    if (clean.contains('urgente')) return 'Urgente';
    if (clean.contains('importante')) return 'Importante';
    return 'Normal';
  }
}

// Legacy rich-preview kept for deep-link compatibility with older builds.
// ignore: unused_element
class _EvtAgentPreviewList extends StatelessWidget {
  final List<EvtMdl> items;

  const _EvtAgentPreviewList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text('No tienes eventos asignados por el momento.'),
        ),
      );
    }

    return Column(
      children: [
        for (final evt in items) ...[
          _EvtAgentPreviewCard(evt: evt),
          if (evt != items.last) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _EvtAgentPreviewCard extends StatelessWidget {
  final EvtMdl evt;

  const _EvtAgentPreviewCard({required this.evt});

  @override
  Widget build(BuildContext context) {
    final hasImage = evt.imgUrl != null && evt.imgUrl!.isNotEmpty;
    final hasPdf = evt.pdfNombre != null || evt.pdfUrl != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasImage)
            Container(
              height: 120,
              width: double.infinity,
              color: AppThm.priClr.withValues(alpha: 0.08),
              child: const Icon(
                Icons.event_available_outlined,
                size: 46,
                color: AppThm.priClr,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(evt.prioridad),
                      backgroundColor: _priorityColor(evt.prioridad),
                    ),
                    Chip(
                      label: Text(EvtEstadoStyle.label(evt.estado)),
                      backgroundColor: EvtEstadoStyle.background(evt.estado),
                      labelStyle: TextStyle(
                        color: EvtEstadoStyle.color(evt.estado),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(evt.tipo),
                      backgroundColor: AppThm.secClr.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  evt.nom,
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (evt.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    evt.descripcion,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _InfoIcon(
                      icon: Icons.calendar_month_outlined,
                      text: evt.fecha,
                    ),
                    _InfoIcon(
                      icon: Icons.schedule_outlined,
                      text: evt.hora.isEmpty ? 'Sin hora' : evt.hora,
                    ),
                    if (evt.lugar.isNotEmpty) _MapsLink(text: evt.lugar),
                  ],
                ),
                if (hasImage) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showImage(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.04),
                        child: Image.network(
                          evt.imgUrl!,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 160,
                            child: Center(
                              child: Text('No se pudo cargar la imagen.'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasPdf) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _showPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(evt.pdfNombre ?? 'Ver PDF adjunto'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String prioridad) {
    final value = prioridad.toLowerCase();
    if (value.contains('urgente')) return Colors.red.withValues(alpha: 0.14);
    if (value.contains('importante')) {
      return AppThm.accClr.withValues(alpha: 0.20);
    }
    return AppThm.secClr.withValues(alpha: 0.12);
  }

  Future<void> _showPdf(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF adjunto'),
        content: SizedBox(
          width: 760,
          height: 560,
          child: Column(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 58),
              const SizedBox(height: 12),
              Text(evt.pdfNombre ?? 'Documento PDF'),
              const SizedBox(height: 12),
              Expanded(
                child: evt.pdfUrl == null
                    ? const Center(child: Text('PDF no disponible.'))
                    : buildPdfPreview(evt.pdfUrl!),
              ),
            ],
          ),
        ),
        actions: [
          if (evt.pdfUrl != null)
            TextButton.icon(
              onPressed: () => openExternalUrl(evt.pdfUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir'),
            ),
          if (evt.pdfUrl != null)
            TextButton.icon(
              onPressed: () => openExternalUrl(evt.pdfUrl!),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImage(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  evt.imgUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No se pudo cargar la imagen.'),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoIcon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _MapsLink extends StatelessWidget {
  final String text;

  const _MapsLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => openExternalUrl(_mapsUrl(text)),
      icon: const Icon(Icons.map_outlined, size: 18),
      label: const Text('Abrir ubicacion'),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  String _mapsUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return googleMapsSearchUrl(trimmed);
  }
}
