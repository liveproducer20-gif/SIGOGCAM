import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/app_user.dart';
import '../adm/adm_api.dart';
import 'sup_api.dart';
import 'sup_badges.dart';
import 'sup_mdl.dart';

class SupportTicketDetail extends StatefulWidget {
  final SupportApi api;
  final AppUser user;
  final int ticketId;
  final VoidCallback? onClose;
  final VoidCallback onChanged;
  final VoidCallback onExport;
  const SupportTicketDetail({
    super.key,
    required this.api,
    required this.user,
    required this.ticketId,
    required this.onChanged,
    required this.onExport,
    this.onClose,
  });
  @override
  State<SupportTicketDetail> createState() => _SupportTicketDetailState();
}

class _SupportTicketDetailState extends State<SupportTicketDetail> {
  final _comment = TextEditingController();
  late Future<SupportDetail> _future;
  bool _saving = false;
  bool _internal = false;
  bool get admin => widget.user.esAdmin;
  @override
  void initState() {
    super.initState();
    _future = widget.api.detail(widget.ticketId);
  }

  @override
  void didUpdateWidget(covariant SupportTicketDetail old) {
    super.didUpdateWidget(old);
    if (old.ticketId != widget.ticketId) _reload();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _reload() =>
      setState(() => _future = widget.api.detail(widget.ticketId));
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: FutureBuilder<SupportDetail>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 42),
                  const SizedBox(height: 10),
                  Text('${s.error}', textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return _content(s.data!);
      },
    ),
  );
  Widget _content(SupportDetail d) {
    final t = d.ticket;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Detalle de la alerta',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF082F6B),
                  ),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SupportPriorityBadge(t.priority),
                    SupportStatusBadge(t.status),
                    SelectableText(
                      '#${t.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF082F6B),
                  ),
                ),
                const SizedBox(height: 18),
                _info('Reportado por', t.userName),
                _info('Área', t.area.isEmpty ? 'No registrada' : t.area),
                _info('Rol', t.role),
                _info('Módulo', t.module),
                _info('Fecha', _date(t.createdAt)),
                _info('Asignado a', t.assignedName ?? 'Sin asignar'),
                const SizedBox(height: 14),
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(t.description),
                if ((t.image ?? '').isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Imagen adjunta',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showImage(t.image!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        ApiClient.absoluteUrl(t.image),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 100,
                          child: Center(
                            child: Text('No se pudo cargar la imagen'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SupportConversation(
                  comments: d.comments,
                  currentUserId: widget.user.id,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _comment,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 3000,
                  decoration: InputDecoration(
                    labelText: admin
                        ? 'Responder al usuario'
                        : 'Agregar comentario',
                    hintText: 'Escribe un mensaje...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _saving ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
                if (admin)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _internal,
                    onChanged: (v) => setState(() => _internal = v ?? false),
                    title: const Text(
                      'Nota interna (no visible para el usuario)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Historial (${d.history.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  children: [
                    for (final h in d.history)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.history_rounded, size: 18),
                        title: Text(h.action),
                        subtitle: Text(
                          '${h.userName} · ${_date(h.createdAt)}${h.newValue.isEmpty ? '' : ' · ${h.newValue}'}',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (admin)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : () => _assign(t),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    t.assignedName == null
                        ? 'Tomar seguimiento'
                        : 'Reasignarme',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _assignTechnician,
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Asignar técnico'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _stateMenu(t),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Cambiar estado'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving || t.status == 'Resuelto'
                      ? null
                      : () => _update(status: 'Resuelto'),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Resolver'),
                ),
                IconButton.outlined(
                  onPressed: widget.onExport,
                  tooltip: 'Exportar',
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
  Future<void> _assign(SupportTicket t) => _update(
    assign: true,
    assignedTo: widget.user.id,
    assignedName: widget.user.nombreCompleto,
    status: t.status == 'Nuevo' ? 'En proceso' : null,
  );

  Future<void> _assignTechnician() async {
    setState(() => _saving = true);
    try {
      final people = await AdmApi().getPersonalList();
      if (!mounted) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Asignar técnico responsable'),
          children: [
            SizedBox(
              width: 480,
              height: 420,
              child: people.isEmpty
                  ? const Center(child: Text('No hay personal disponible.'))
                  : ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (context, index) {
                        final person = people[index];
                        final name =
                            '${person['nombres'] ?? ''} ${person['apellidos'] ?? ''}'
                                .trim();
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            name.isEmpty ? 'Personal sin nombre' : name,
                          ),
                          subtitle: Text(
                            '${person['rol'] ?? 'Sin rol'} · ${person['area'] ?? 'Sin área'}',
                          ),
                          onTap: () => Navigator.pop(context, person),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      final id = int.tryParse(selected['id']?.toString() ?? '');
      final name = '${selected['nombres'] ?? ''} ${selected['apellidos'] ?? ''}'
          .trim();
      if (id == null) {
        throw Exception('El personal seleccionado no tiene ID válido');
      }
      await _update(
        assign: true,
        assignedTo: id,
        assignedName: name,
        status: 'En proceso',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar el personal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _stateMenu(SupportTicket t) async {
    final value = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(400, 500, 20, 20),
      items: [
        for (final s in const [
          'Nuevo',
          'En proceso',
          'Pendiente',
          'Resuelto',
          'Cancelado',
        ])
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                SupportStatusBadge(s),
                if (s == t.status) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          ),
      ],
    );
    if (value != null) await _update(status: value);
  }

  Future<void> _update({
    String? status,
    bool assign = false,
    int? assignedTo,
    String? assignedName,
  }) async {
    setState(() => _saving = true);
    try {
      await widget.api.update(
        widget.ticketId,
        status: status,
        assign: assign,
        assignedTo: assignedTo,
        assignedName: assignedName,
      );
      _reload();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.length < 2) return;
    setState(() => _saving = true);
    try {
      await widget.api.comment(widget.ticketId, text, internal: _internal);
      _comment.clear();
      _internal = false;
      _reload();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showImage(String path) => showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: InteractiveViewer(
        child: Image.network(ApiClient.absoluteUrl(path), fit: BoxFit.contain),
      ),
    ),
  );
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class SupportConversation extends StatelessWidget {
  final List<SupportComment> comments;
  final int currentUserId;
  const SupportConversation({
    super.key,
    required this.comments,
    required this.currentUserId,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Conversación',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      if (comments.isEmpty)
        const Text(
          'Aún no hay respuestas.',
          style: TextStyle(color: Color(0xFF64748B)),
        )
      else
        for (final c in comments)
          Align(
            alignment: c.userId == currentUserId
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: c.userId == currentUserId
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: c.internal ? Border.all(color: Colors.amber) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.userName}${c.internal ? ' · Nota interna' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(c.text),
                  const SizedBox(height: 4),
                  Text(
                    '${c.createdAt.day}/${c.createdAt.month} ${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ],
  );
}
