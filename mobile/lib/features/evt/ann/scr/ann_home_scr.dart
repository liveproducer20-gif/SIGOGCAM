import 'package:flutter/material.dart';

import '../../../../core/auth/app_user.dart';
import '../../../../core/file/file_pick.dart';
import '../../../../core/thm/app_thm.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = anuncios.where((ann) {
      final q = filtro.toLowerCase();
      final autorizado =
          !widget.user.esUsuario || ann.personalIds.contains(widget.user.id);
      final matchFocus = widget.focusAnnId == null || ann.id == widget.focusAnnId;
      final matchFiltro = q.isEmpty ||
          ann.ttl.toLowerCase().contains(q) ||
          ann.desc.toLowerCase().contains(q) ||
          ann.prioridad.toLowerCase().contains(q);

      return autorizado && matchFocus && matchFiltro;
    }).toList();

    return Scaffold(
      backgroundColor: AppThm.bgClr,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: PageTtlWdg(
                    ttl: widget.focusAnnId == null ? 'Anuncios' : 'Anuncio',
                    sub: widget.focusAnnId == null
                        ? 'Administración de noticias, comunicados y publicaciones institucionales.'
                        : 'Publicación abierta desde notificaciones.',
                  ),
                ),
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
            ),
            const SizedBox(height: 28),
            TextField(
              onChanged: (v) => setState(() => filtro = v.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar anuncio...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }

  Future<void> _toggle(AnnMdl ann) async {
    try {
      await AnnSvc.cambiarPublicado(ann.id, !ann.publicado);
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }
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
        width: 520,
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
                onPressed: _pickImage,
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
                        child: Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
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
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file == null) return;

    setState(() {
      imgNombre = file.name;
      imgUrl = file.dataUrl ?? file.previewUrl;
    });
  }

  void _save() {
    if (ttlCtl.text.trim().isEmpty || descCtl.text.trim().isEmpty) return;

    Navigator.pop(
      context,
      AnnMdl(
        id: widget.ann?.id ?? 0,
        ttl: ttlCtl.text.trim(),
        desc: descCtl.text.trim(),
        img: widget.ann?.img ?? 'assets/img/auth_bg.jpg',
        imgNombre: imgNombre,
        imgUrl: imgUrl,
        fecPub: widget.ann?.fecPub ?? DateTime.now(),
        fecExp: widget.ann?.fecExp,
        personalIds: widget.ann?.personalIds ?? [],
        prioridad: prioridad,
        publicado: widget.ann?.publicado ?? true,
        notificar: widget.ann?.notificar ?? true,
      ),
    );
  }
}
