import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_user.dart';
import '../../../../core/file/file_pick.dart';
import '../../../../core/file/file_pick_result.dart';
import '../../../../core/thm/app_thm.dart';
import '../../../../core/wdg/responsive.dart';
import '../../../adm/adm_design_tokens.dart';
import '../../../dash/wdg/page_ttl_wdg.dart';
import '../mdl/ann_mdl.dart';
import '../svc/ann_svc.dart';
import '../wdg/ann_card_wdg.dart';

class AnnHomeScr extends StatefulWidget {
  final AppUser user;
  final int? focusAnnId;
  final bool showExit;

  const AnnHomeScr({
    super.key,
    required this.user,
    this.focusAnnId,
    this.showExit = false,
  });

  @override
  State<AnnHomeScr> createState() => _AnnHomeScrState();
}

class _AnnHomeScrState extends State<AnnHomeScr> {
  List<AnnMdl> anuncios = [];
  bool loading = true;
  String? error;
  String filtro = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = anuncios.where((ann) {
      final q = filtro.toLowerCase();
      final autorizado =
          !widget.user.esUsuario ||
          ann.personalIds.isEmpty ||
          ann.personalIds.contains(widget.user.id);
      final matchFocus =
          widget.focusAnnId == null || ann.id == widget.focusAnnId;
      final matchFiltro =
          q.isEmpty ||
          ann.ttl.toLowerCase().contains(q) ||
          ann.desc.toLowerCase().contains(q) ||
          ann.prioridad.toLowerCase().contains(q);

      return autorizado && matchFocus && matchFiltro;
    }).toList();

    return Scaffold(
      backgroundColor: AppThm.bgClr,
      body: Padding(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final title = PageTtlWdg(
                  ttl: widget.focusAnnId == null ? 'Anuncios' : 'Anuncio',
                  sub: widget.focusAnnId == null
                      ? 'Administración de noticias, comunicados y publicaciones institucionales.'
                      : 'Publicación abierta desde notificaciones.',
                );
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.showExit)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Salir',
                      ),
                    if (widget.user.puedeGestionarAnuncios)
                      FilledButton.icon(
                        onPressed: () => _openDlg(),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Nuevo anuncio'),
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [title, const SizedBox(height: 14), actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _AnnSummary(items: visibles),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdmTokens.grey100),
                boxShadow: AdmTokens.cardShadow,
              ),
              child: TextField(
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => filtro = v.trim());
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por título, contenido o prioridad...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AdmTokens.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildList(visibles)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AnnMdl> visibles) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(child: Text('No se pudieron cargar los anuncios: $error'));
    }

    if (visibles.isEmpty) {
      return const Center(child: Text('No hay anuncios para mostrar.'));
    }

    return ListView.separated(
      itemCount: visibles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final ann = visibles[i];

        return AnnCardWdg(
          ann: ann,
          canManage: widget.user.puedeGestionarAnuncios,
          agentName: widget.user.nombreCompleto,
          onEdit: () => _openDlg(ann: ann),
          onToggle: () => _toggle(ann),
          onDelete: () => _delete(ann),
        );
      },
    );
  }

  Future<void> _load() async {
    try {
      final data = await AnnSvc.getLst(
        personalId: widget.user.esUsuario ? widget.user.id : null,
      );
      if (!mounted) return;
      setState(() {
        anuncios = data;
        loading = false;
        error = null;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = err.toString();
      });
    }
  }

  Future<void> _openDlg({AnnMdl? ann}) async {
    final result = await showDialog<AnnMdl>(
      context: context,
      builder: (_) => _AnnEditDlg(ann: ann),
    );

    if (result == null) return;

    try {
      if (ann == null) {
        await AnnSvc.crear(result, creadoPor: widget.user.id);
      } else {
        await AnnSvc.actualizar(result);
      }
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  Future<void> _toggle(AnnMdl ann) async {
    try {
      await AnnSvc.cambiarPublicado(ann.id, !ann.publicado);
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  Future<void> _delete(AnnMdl ann) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: Text('Se eliminará "${ann.ttl}".'),
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
      await AnnSvc.eliminar(ann.id);
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }
}

class _AnnSummary extends StatelessWidget {
  final List<AnnMdl> items;
  const _AnnSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final published = items.where((e) => e.publicado).length;
    final important = items
        .where((e) => e.prioridad.toLowerCase().contains('important'))
        .length;
    final urgent = items
        .where((e) => e.prioridad.toLowerCase().contains('urgent'))
        .length;
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth >= 720
            ? (c.maxWidth - 42) / 4
            : (c.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _AnnStat(
              width,
              Icons.campaign_rounded,
              'Total',
              items.length,
              AdmTokens.secondary,
            ),
            _AnnStat(
              width,
              Icons.visibility_outlined,
              'Publicados',
              published,
              AdmTokens.success,
            ),
            _AnnStat(
              width,
              Icons.priority_high_rounded,
              'Importantes',
              important,
              AdmTokens.warning,
            ),
            _AnnStat(
              width,
              Icons.notification_important_outlined,
              'Urgentes',
              urgent,
              AdmTokens.error,
            ),
          ],
        );
      },
    );
  }
}

class _AnnStat extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _AnnStat(this.width, this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AdmTokens.grey100),
      boxShadow: AdmTokens.cardShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AdmTokens.bodySmall),
              Text('$value', style: AdmTokens.h2),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AnnEditDlg extends StatefulWidget {
  final AnnMdl? ann;

  const _AnnEditDlg({this.ann});

  @override
  State<_AnnEditDlg> createState() => _AnnEditDlgState();
}

class _AnnEditDlgState extends State<_AnnEditDlg> {
  final ttlCtl = TextEditingController();
  final descCtl = TextEditingController();
  String prioridad = 'Normal';
  String? imgNombre;
  String? imgUrl;
  FilePickResult? pendingImage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    ttlCtl.text = widget.ann?.ttl ?? '';
    descCtl.text = widget.ann?.desc ?? '';
    prioridad = widget.ann?.prioridad ?? 'Normal';
    imgNombre = widget.ann?.imgNombre;
    imgUrl = widget.ann?.imgUrl;
  }

  @override
  void dispose() {
    ttlCtl.dispose();
    descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ann == null ? 'Nuevo anuncio' : 'Editar anuncio'),
      content: SizedBox(
        width: AppResponsive.dialogMaxWidth(context),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: ttlCtl,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: prioridad,
                decoration: InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: saving ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(imgNombre ?? 'Subir imagen'),
              ),
              if (imgUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Image.network(
                      imgUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 150,
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                ),
              ],
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
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(saving ? 'Subiendo...' : 'Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file == null) return;

    setState(() {
      pendingImage = file;
      imgNombre = file.name;
      imgUrl = file.dataUrl ?? file.previewUrl;
    });
  }

  Future<void> _save() async {
    if (ttlCtl.text.trim().isEmpty || descCtl.text.trim().isEmpty) return;

    setState(() => saving = true);
    try {
      final storedImage = pendingImage == null
          ? imgUrl
          : await AnnSvc.uploadImage(pendingImage!);
      if (!mounted) return;

      Navigator.pop(
        context,
        AnnMdl(
          id: widget.ann?.id ?? 0,
          ttl: ttlCtl.text.trim(),
          desc: descCtl.text.trim(),
          img: widget.ann?.img ?? 'assets/img/auth_bg.jpg',
          imgNombre: imgNombre,
          imgUrl: storedImage,
          fecPub: widget.ann?.fecPub ?? DateTime.now(),
          fecExp: widget.ann?.fecExp,
          personalIds: widget.ann?.personalIds ?? [],
          prioridad: prioridad,
          publicado: widget.ann?.publicado ?? true,
          notificar: widget.ann?.notificar ?? true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
