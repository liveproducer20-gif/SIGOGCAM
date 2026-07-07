import 'package:flutter/material.dart';

import '../../../../../core/thm/app_thm.dart';
import '../mdl/ann_mdl.dart';

class AnnCardWdg extends StatelessWidget {
  final AnnMdl ann;
  final bool canManage;
  final String? agentName;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AnnCardWdg({
    super.key,
    required this.ann,
    required this.canManage,
    this.agentName,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      return _AgentPublicationCard(
        ann: ann,
        agentName: agentName,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 230,
            height: 150,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.04),
              child: ann.imgUrl == null
                  ? Image.asset(
                      ann.img,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      ann.imgUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(ann.prioridad),
                        backgroundColor: ann.prioridad == 'Importante'
                            ? AppThm.accClr.withValues(alpha: 0.20)
                            : AppThm.secClr.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        label: Text(ann.publicado ? 'Publicado' : 'Oculto'),
                        backgroundColor: ann.publicado
                            ? AppThm.okClr.withValues(alpha: 0.14)
                            : Colors.black12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ann.ttl,
                    style: const TextStyle(
                      color: AppThm.priClr,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ann.desc,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${ann.fecPub.day}/${ann.fecPub.month}/${ann.fecPub.year}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Spacer(),
                      if (canManage) ...[
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: onToggle,
                          icon: Icon(
                            ann.publicado
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentPublicationCard extends StatelessWidget {
  final AnnMdl ann;
  final String? agentName;

  const _AgentPublicationCard({
    required this.ann,
    this.agentName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppThm.priClr,
                      child: Text(
                        _initials(agentName),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agentName?.isNotEmpty == true
                                ? agentName!
                                : 'Agente convocado',
                            style: const TextStyle(
                              color: AppThm.priClr,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${ann.fecPub.day}/${ann.fecPub.month}/${ann.fecPub.year}',
                            style: const TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(ann.prioridad),
                      backgroundColor: ann.prioridad == 'Urgente'
                          ? Colors.red.withValues(alpha: 0.14)
                          : AppThm.accClr.withValues(alpha: 0.18),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  ann.ttl,
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ann.desc,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: () => _showImage(context),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.04),
                      child: ann.imgUrl != null
                          ? Image.network(
                              ann.imgUrl!,
                              width: double.infinity,
                              height: 320,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 180,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            )
                          : Image.asset(
                              ann.img,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? value) {
    final parts = (value ?? '')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}';
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'A';
  }

  Future<void> _showImage(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: ann.imgUrl != null
                    ? Image.network(
                        ann.imgUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      )
                    : Image.asset(ann.img, fit: BoxFit.contain),
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
