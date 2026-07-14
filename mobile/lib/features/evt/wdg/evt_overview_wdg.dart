import 'package:flutter/material.dart';

import '../../../core/pdf/pdf_preview.dart';
import '../../../core/url/open_url.dart';
import '../../adm/adm_design_tokens.dart';
import '../mdl/evt_mdl.dart';
import 'evt_estado_style.dart';

class EvtOverviewWdg extends StatelessWidget {
  final List<EvtMdl> items;
  final bool canManage;
  final void Function(EvtMdl evt, String estado)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;

  const EvtOverviewWdg({
    super.key,
    required this.items,
    required this.canManage,
    this.onEstado,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyEvents();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final showAside = constraints.maxWidth >= 1100;
        final content = _EventGroups(
          items: items,
          canManage: canManage,
          onEstado: onEstado,
          onEditar: onEditar,
          onEliminar: onEliminar,
        );
        if (!showAside) return content;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: 18),
            SizedBox(width: 285, child: _EventAside(items: items)),
          ],
        );
      },
    );
  }
}

class EvtStatsWdg extends StatelessWidget {
  final List<EvtMdl> items;
  final int anuncios;

  const EvtStatsWdg({super.key, required this.items, this.anuncios = 0});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = items.where((e) => _sameDay(_date(e), now)).length;
    final upcoming = items.where((e) {
      final date = _date(e);
      return date != null && date.isAfter(DateTime(now.year, now.month, now.day));
    }).length;
    final pending = items.fold<int>(
      0,
      (sum, e) => sum + (e.convocados - e.confirmados).clamp(0, 999999),
    );
    final data = [
      (Icons.calendar_today_rounded, 'Eventos hoy', today, const Color(0xFF1C63C7)),
      (Icons.schedule_rounded, 'Próximos eventos', upcoming, const Color(0xFF22A447)),
      (Icons.campaign_rounded, 'Anuncios activos', anuncios, const Color(0xFF7C4DCC)),
      (Icons.groups_rounded, 'Pendientes confirmar', pending, const Color(0xFFF4A000)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 520 ? 2 : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final stat in data) SizedBox(width: width, child: _StatCard(data: stat))],
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final (IconData, String, int, Color) data;
  const _StatCard({required this.data});
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final (icon, label, value, color) = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdmTokens.grey100),
          boxShadow: hovered ? AdmTokens.hoverShadow : AdmTokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AdmTokens.statLabel),
              const SizedBox(height: 3),
              Text('$value', style: AdmTokens.statValue.copyWith(fontSize: 25)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _EventGroups extends StatelessWidget {
  final List<EvtMdl> items;
  final bool canManage;
  final void Function(EvtMdl, String)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;
  const _EventGroups({required this.items, required this.canManage, this.onEstado, this.onEditar, this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<EvtMdl>>{};
    for (final evt in items) {
      groups.putIfAbsent(_group(evt), () => []).add(evt);
    }
    return Column(children: [
      for (final name in ['HOY', 'MAÑANA', 'ESTA SEMANA', 'PRÓXIMAMENTE', 'ANTERIORES'])
        if (groups[name]?.isNotEmpty == true) ...[
          _GroupHeader(name: name, count: groups[name]!.length),
          const SizedBox(height: 10),
          for (final evt in groups[name]!) ...[
            _ModernEventCard(evt: evt, canManage: canManage, onEstado: onEstado, onEditar: onEditar, onEliminar: onEliminar),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 5),
        ],
    ]);
  }
}

class _GroupHeader extends StatelessWidget {
  final String name;
  final int count;
  const _GroupHeader({required this.name, required this.count});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 9, height: 9, decoration: const BoxDecoration(color: AdmTokens.secondary, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(name, style: AdmTokens.label.copyWith(color: AdmTokens.primary, fontWeight: FontWeight.w800)),
    const Spacer(),
    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: AdmTokens.primarySoft, borderRadius: BorderRadius.circular(20)), child: Text('$count evento${count == 1 ? '' : 's'}', style: AdmTokens.bodySmall.copyWith(color: AdmTokens.primary))),
  ]);
}

class _ModernEventCard extends StatefulWidget {
  final EvtMdl evt;
  final bool canManage;
  final void Function(EvtMdl, String)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;
  const _ModernEventCard({required this.evt, required this.canManage, this.onEstado, this.onEditar, this.onEliminar});
  @override
  State<_ModernEventCard> createState() => _ModernEventCardState();
}

class _ModernEventCardState extends State<_ModernEventCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final e = widget.evt;
    final pending = (e.convocados - e.confirmados).clamp(0, 999999);
    final progress = e.convocados == 0 ? 0.0 : (e.confirmados / e.convocados).clamp(0.0, 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: hovered ? AdmTokens.secondary.withValues(alpha: .35) : AdmTokens.grey100), boxShadow: hovered ? AdmTokens.hoverShadow : AdmTokens.cardShadow),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, c) {
          final compact = c.maxWidth < 720;
          final image = _EventImage(evt: e);
          final body = _EventBody(evt: e, pending: pending, progress: progress, canManage: widget.canManage, onEstado: widget.onEstado, onEditar: widget.onEditar, onEliminar: widget.onEliminar);
          return compact ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(height: 190, child: image), body]) : IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(width: c.maxWidth * .34, child: image), Expanded(child: body)]));
        }),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final EvtMdl evt;
  const _EventImage({required this.evt});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    if (evt.imgUrl?.isNotEmpty == true)
      Image.network(evt.imgUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholder())
    else _placeholder(),
    Positioned(top: 11, left: 11, child: _Pill(label: EvtEstadoStyle.label(evt.estado), color: EvtEstadoStyle.color(evt.estado))),
  ]);
  Widget _placeholder() => Container(color: const Color(0xFFE8F0FB), child: const Icon(Icons.event_available_rounded, size: 58, color: AdmTokens.secondary));
}

class _EventBody extends StatelessWidget {
  final EvtMdl evt;
  final int pending;
  final double progress;
  final bool canManage;
  final void Function(EvtMdl, String)? onEstado;
  final ValueChanged<EvtMdl>? onEditar;
  final ValueChanged<EvtMdl>? onEliminar;
  const _EventBody({required this.evt, required this.pending, required this.progress, required this.canManage, this.onEstado, this.onEditar, this.onEliminar});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Wrap(spacing: 7, runSpacing: 6, children: [_Pill(label: evt.tipo, color: AdmTokens.secondary), _Pill(label: evt.prioridad, color: _priority(evt.prioridad))])),
        if (canManage) PopupMenuButton<String>(tooltip: 'Acciones', onSelected: (v) { if (v == 'edit') onEditar?.call(evt); if (v == 'delete') onEliminar?.call(evt); if (v.startsWith('state:')) onEstado?.call(evt, v.substring(6)); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'state:PLANIFICADO', child: Text('Marcar planificado')), PopupMenuItem(value: 'state:EN_CURSO', child: Text('Marcar en curso')), PopupMenuItem(value: 'state:FINALIZADO', child: Text('Finalizar')), PopupMenuDivider(), PopupMenuItem(value: 'delete', child: Text('Eliminar'))]),
      ]),
      const SizedBox(height: 8),
      Text(evt.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: AdmTokens.h2.copyWith(color: AdmTokens.primary, fontSize: 18)),
      if (evt.descripcion.isNotEmpty) ...[const SizedBox(height: 5), Text(evt.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: AdmTokens.bodySmall.copyWith(height: 1.35))],
      const SizedBox(height: 10),
      Wrap(spacing: 14, runSpacing: 7, children: [_Meta(Icons.calendar_month_outlined, evt.fecha), _Meta(Icons.schedule_outlined, evt.hora.isEmpty ? 'Sin hora' : evt.hora), if (evt.lugar.isNotEmpty) _Meta(Icons.location_on_outlined, evt.lugar)]),
      const SizedBox(height: 12),
      Row(children: [_MiniStat('Convocados', evt.convocados, AdmTokens.secondary), _MiniStat('Confirmados', evt.confirmados, AdmTokens.success), _MiniStat('Pendientes', pending, AdmTokens.warning)]),
      const SizedBox(height: 9),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AdmTokens.grey100, color: AdmTokens.success)),
      const SizedBox(height: 9),
      Wrap(spacing: 8, runSpacing: 6, children: [
        if (evt.pdfUrl != null || evt.pdfNombre != null) OutlinedButton.icon(onPressed: () => _showPdf(context, evt), icon: const Icon(Icons.description_outlined, size: 17), label: Text(evt.pdfNombre ?? 'Archivo')),
        if (evt.lugar.isNotEmpty) TextButton.icon(onPressed: () => openExternalUrl(_mapsUrl(evt.lugar)), icon: const Icon(Icons.location_on_outlined, size: 17), label: const Text('Abrir ubicación')),
        if (!canManage) TextButton.icon(onPressed: () => _showDetails(context, evt), icon: const Icon(Icons.visibility_outlined, size: 17), label: const Text('Ver detalles')),
      ]),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String label; final int value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Row(children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 5), Flexible(child: Text('$value $label', overflow: TextOverflow.ellipsis, style: AdmTokens.bodySmall.copyWith(color: AdmTokens.grey700, fontWeight: FontWeight.w600)))]));
}

class _Meta extends StatelessWidget { final IconData icon; final String text; const _Meta(this.icon, this.text); @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AdmTokens.grey500), const SizedBox(width: 5), ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdmTokens.bodySmall))]); }
class _Pill extends StatelessWidget { final String label; final Color color; const _Pill({required this.label, required this.color}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700))); }

class _EventAside extends StatelessWidget {
  final List<EvtMdl> items; const _EventAside({required this.items});
  @override Widget build(BuildContext context) { final now = DateTime.now(); final upcoming = items.where((e) { final d = _date(e); return d != null && !d.isBefore(DateTime(now.year, now.month, now.day)); }).take(4).toList(); final types = <String, int>{}; for (final e in items) { types[e.tipo] = (types[e.tipo] ?? 0) + 1; } return Column(children: [
    _AsideBox(title: 'Calendario', icon: Icons.calendar_month_outlined, child: _MiniCalendar(now: now, items: items)), const SizedBox(height: 14),
    _AsideBox(title: 'Tipos de eventos', icon: Icons.category_outlined, child: Column(children: [for (final e in types.entries.take(5)) Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [Expanded(child: Text(e.key, style: AdmTokens.bodySmall)), Text('${e.value}', style: AdmTokens.label)]))])), const SizedBox(height: 14),
    _AsideBox(title: 'Próximos eventos', icon: Icons.upcoming_outlined, child: Column(children: [for (final e in upcoming) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 4, height: 34, decoration: BoxDecoration(color: AdmTokens.secondary, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdmTokens.label), Text(e.fecha, style: AdmTokens.bodySmall)]))]))])),
  ]); }
}
class _AsideBox extends StatelessWidget { final String title; final IconData icon; final Widget child; const _AsideBox({required this.title, required this.icon, required this.child}); @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AdmTokens.grey100), boxShadow: AdmTokens.cardShadow), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 19, color: AdmTokens.primary), const SizedBox(width: 8), Text(title, style: AdmTokens.label.copyWith(color: AdmTokens.primary))]), const SizedBox(height: 14), child])); }
class _MiniCalendar extends StatelessWidget { final DateTime now; final List<EvtMdl> items; const _MiniCalendar({required this.now, required this.items}); @override Widget build(BuildContext context) { final first = DateTime(now.year, now.month, 1); final days = DateUtils.getDaysInMonth(now.year, now.month); final offset = first.weekday - 1; return Column(children: [Text('${_month(now.month)} ${now.year}', style: AdmTokens.label), const SizedBox(height: 10), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3), itemCount: offset + days, itemBuilder: (_, i) { if (i < offset) return const SizedBox(); final day = i - offset + 1; final has = items.any((e) { final d = _date(e); return d?.year == now.year && d?.month == now.month && d?.day == day; }); final today = day == now.day; return Container(alignment: Alignment.center, decoration: BoxDecoration(color: today ? AdmTokens.primary : has ? AdmTokens.primarySoft : Colors.transparent, shape: BoxShape.circle), child: Text('$day', style: TextStyle(fontSize: 10, color: today ? Colors.white : has ? AdmTokens.primary : AdmTokens.grey600, fontWeight: has || today ? FontWeight.w700 : FontWeight.w400))); })]); } }
class _EmptyEvents extends StatelessWidget { const _EmptyEvents(); @override Widget build(BuildContext context) => Container(height: 260, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdmTokens.grey100)), child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_busy_outlined, size: 48, color: AdmTokens.grey400), SizedBox(height: 10), Text('No hay eventos que coincidan con los filtros.', style: AdmTokens.body)])); }

DateTime? _date(EvtMdl e) => DateTime.tryParse(e.fechaInicioRaw);
bool _sameDay(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;
String _group(EvtMdl e) { final d = _date(e); if (d == null) return 'PRÓXIMAMENTE'; final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final date = DateTime(d.year, d.month, d.day); final diff = date.difference(today).inDays; if (diff < 0) return 'ANTERIORES'; if (diff == 0) return 'HOY'; if (diff == 1) return 'MAÑANA'; if (diff <= 7) return 'ESTA SEMANA'; return 'PRÓXIMAMENTE'; }
Color _priority(String value) { final v = value.toLowerCase(); if (v.contains('urgent')) return AdmTokens.error; if (v.contains('important') || v.contains('alta')) return AdmTokens.warning; return AdmTokens.grey500; }
String _mapsUrl(String value) { final v = value.trim(); return v.startsWith('http://') || v.startsWith('https://') ? v : googleMapsSearchUrl(v); }
String _month(int m) => const ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][m - 1];

Future<void> _showPdf(BuildContext context, EvtMdl evt) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(evt.pdfNombre ?? 'Archivo adjunto'), content: SizedBox(width: 760, height: 520, child: evt.pdfUrl == null ? const Center(child: Text('Archivo no disponible.')) : buildPdfPreview(evt.pdfUrl!)), actions: [if (evt.pdfUrl != null) TextButton.icon(onPressed: () => openExternalUrl(evt.pdfUrl!), icon: const Icon(Icons.download_outlined), label: const Text('Descargar')), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));
Future<void> _showDetails(BuildContext context, EvtMdl evt) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(evt.nom), content: SizedBox(width: 540, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(evt.descripcion.isEmpty ? 'Sin descripción.' : evt.descripcion), const SizedBox(height: 16), _Meta(Icons.calendar_month_outlined, evt.fecha), const SizedBox(height: 8), _Meta(Icons.schedule_outlined, evt.hora), if (evt.lugar.isNotEmpty) ...[const SizedBox(height: 8), _Meta(Icons.location_on_outlined, evt.lugar)]]))), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));
