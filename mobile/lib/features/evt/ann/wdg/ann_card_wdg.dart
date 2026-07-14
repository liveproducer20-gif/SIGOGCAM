import 'package:flutter/material.dart';

import '../../../adm/adm_design_tokens.dart';
import '../mdl/ann_mdl.dart';

class AnnCardWdg extends StatefulWidget {
  final AnnMdl ann;
  final bool canManage;
  final String? agentName;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AnnCardWdg({super.key, required this.ann, required this.canManage, this.agentName, required this.onEdit, required this.onToggle, required this.onDelete});
  @override
  State<AnnCardWdg> createState() => _AnnCardWdgState();
}

class _AnnCardWdgState extends State<AnnCardWdg> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final ann = widget.ann;
    final accent = _accent(ann.prioridad);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border(left: BorderSide(color: accent, width: 4), top: const BorderSide(color: AdmTokens.grey100), right: const BorderSide(color: AdmTokens.grey100), bottom: const BorderSide(color: AdmTokens.grey100)), boxShadow: hovered ? AdmTokens.hoverShadow : AdmTokens.cardShadow),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, c) {
          final compact = c.maxWidth < 620;
          final image = _AnnImage(ann: ann);
          final body = _AnnBody(ann: ann, canManage: widget.canManage, onEdit: widget.onEdit, onToggle: widget.onToggle, onDelete: widget.onDelete);
          return compact ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(height: 190, child: image), body]) : IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [SizedBox(width: 210, child: image), Expanded(child: body)]));
        }),
      ),
    );
  }
}

class _AnnImage extends StatelessWidget {
  final AnnMdl ann; const _AnnImage({required this.ann});
  @override Widget build(BuildContext context) => InkWell(onTap: () => _show(context), child: ann.imgUrl != null ? Image.network(ann.imgUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback()) : Image.asset(ann.img, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback()));
  Widget _fallback() => Container(color: AdmTokens.primarySoft, child: const Icon(Icons.campaign_outlined, size: 54, color: AdmTokens.secondary));
  Future<void> _show(BuildContext context) => showDialog<void>(context: context, builder: (_) => Dialog.fullscreen(child: Stack(children: [Center(child: InteractiveViewer(child: ann.imgUrl != null ? Image.network(ann.imgUrl!, fit: BoxFit.contain) : Image.asset(ann.img, fit: BoxFit.contain))), Positioned(top: 18, right: 18, child: IconButton.filled(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))) ])));
}

class _AnnBody extends StatelessWidget {
  final AnnMdl ann; final bool canManage; final VoidCallback onEdit; final VoidCallback onToggle; final VoidCallback onDelete;
  const _AnnBody({required this.ann, required this.canManage, required this.onEdit, required this.onToggle, required this.onDelete});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _accent(ann.prioridad).withValues(alpha: .11), borderRadius: BorderRadius.circular(20)), child: Text(ann.prioridad, style: TextStyle(color: _accent(ann.prioridad), fontSize: 10.5, fontWeight: FontWeight.w700))),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ann.publicado ? AdmTokens.success.withValues(alpha: .1) : AdmTokens.grey100, borderRadius: BorderRadius.circular(20)), child: Text(ann.publicado ? 'Publicado' : 'Oculto', style: TextStyle(color: ann.publicado ? AdmTokens.success : AdmTokens.grey500, fontSize: 10.5, fontWeight: FontWeight.w700))),
      const Spacer(),
      Text('${_two(ann.fecPub.day)}/${_two(ann.fecPub.month)}/${ann.fecPub.year} · ${_two(ann.fecPub.hour)}:${_two(ann.fecPub.minute)}', style: AdmTokens.bodySmall),
      if (canManage) PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') onEdit(); if (v == 'toggle') onToggle(); if (v == 'delete') onDelete(); }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'toggle', child: Text(ann.publicado ? 'Ocultar' : 'Publicar')), const PopupMenuDivider(), const PopupMenuItem(value: 'delete', child: Text('Eliminar'))]),
    ]),
    const SizedBox(height: 9),
    Text(ann.ttl, maxLines: 2, overflow: TextOverflow.ellipsis, style: AdmTokens.h2.copyWith(color: AdmTokens.primary, fontSize: 18)),
    const SizedBox(height: 6),
    Text(ann.desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: AdmTokens.body.copyWith(height: 1.4)),
    const Spacer(), const SizedBox(height: 10),
    TextButton.icon(onPressed: () => _details(context), icon: const Icon(Icons.arrow_forward_rounded, size: 17), label: Text(canManage ? 'Ver anuncio' : 'Leer más'), style: TextButton.styleFrom(padding: EdgeInsets.zero)),
  ]));
  Future<void> _details(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(ann.ttl), content: SizedBox(width: 560, child: SingleChildScrollView(child: Text(ann.desc, style: AdmTokens.body.copyWith(height: 1.5)))), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))]));
}

Color _accent(String value) { final v = value.toLowerCase(); if (v.contains('urgent')) return AdmTokens.error; if (v.contains('important')) return AdmTokens.warning; return AdmTokens.secondary; }
String _two(int value) => value.toString().padLeft(2, '0');
