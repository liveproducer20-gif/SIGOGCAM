import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/thm/app_thm.dart';
import '../dash/wdg/page_ttl_wdg.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'ins_api.dart';
import 'ins_icn_wdg.dart';
import 'ins_mdl.dart';
import 'ins_share_wdg.dart';

class InsHomeScr extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onUserChanged;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifications;

  const InsHomeScr({
    super.key,
    required this.user,
    this.onUserChanged,
    this.onLogout,
    this.onNotifications,
  });

  @override
  State<InsHomeScr> createState() => _InsHomeScrState();
}

class _InsHomeScrState extends State<InsHomeScr> {
  late Future<_InsData> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: TopBarWdg(
        ttl: 'Mis insignias',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
      ),
      body: SafeArea(
        child: FutureBuilder<_InsData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('No se pudieron cargar las insignias: ${snapshot.error}'),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => future = _load());
                await future;
              },
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  const PageTtlWdg(
                    ttl: 'Mis insignias',
                    sub: 'Progreso por cartillas generadas.',
                  ),
                  const SizedBox(height: 22),
                  _ProgressPanel(progreso: data.progreso),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 1100 ? 3 : width >= 720 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.insignias.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 210,
                        ),
                        itemBuilder: (_, index) => _InsCard(
                          insignia: data.insignias[index],
                          user: widget.user,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_InsData> _load() async {
    final api = InsApi();
    final all = await api.obtenerTodas();
    final unlocked = await api.obtenerUsuarioInsignias(widget.user.id);
    final progreso = await api.obtenerProgreso(widget.user.id);
    final unlockedById = {
      for (final item in unlocked) item.id: item,
    };
    final merged = all.map((item) {
      final got = unlockedById[item.id];
      if (got == null) return item;
      return item.copyWith(
        desbloqueada: true,
        totalAlDesbloquear: got.totalAlDesbloquear,
        fechaDesbloqueo: got.fechaDesbloqueo,
      );
    }).toList();

    return _InsData(insignias: merged, progreso: progreso);
  }
}

class _ProgressPanel extends StatelessWidget {
  final InsProgresoMdl progreso;

  const _ProgressPanel({required this.progreso});

  @override
  Widget build(BuildContext context) {
    final complete = progreso.proximaInsignia == null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: AppThm.secClr),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  complete
                      ? 'Todas las insignias principales desbloqueadas'
                      : 'Proxima: ${progreso.proximaInsignia}',
                  style: const TextStyle(
                    color: AppThm.priClr,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progreso.porcentajeProgreso.clamp(0, 100) / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Text(
            complete
                ? '${progreso.totalCartillasGeneradas} cartillas generadas.'
                : '${progreso.totalCartillasGeneradas}/${progreso.metaProxima} cartillas. Faltan ${progreso.cartillasFaltantes}.',
            style: const TextStyle(color: AppThm.txtClr),
          ),
          if (progreso.ultimaInsignia != null) ...[
            const SizedBox(height: 6),
            Text(
              'Ultima insignia: ${progreso.ultimaInsignia}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsCard extends StatelessWidget {
  final InsMdl insignia;
  final AppUser user;

  const _InsCard({required this.insignia, required this.user});

  @override
  Widget build(BuildContext context) {
    final unlocked = insignia.desbloqueada;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked
              ? AppThm.accClr.withValues(alpha: 0.65)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgeIcon(
                metaCartillas: insignia.metaCartillas,
                size: 48,
                unlocked: unlocked,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insignia.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unlocked ? AppThm.priClr : Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Meta: ${insignia.metaCartillas} cartillas',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              unlocked
                  ? 'Desbloqueada con ${insignia.totalAlDesbloquear ?? insignia.metaCartillas} cartillas.'
                  : 'Bloqueada hasta alcanzar la meta.',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          if (unlocked) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _compartir(context),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Compartir en mis redes', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThm.priClr,
                  side: BorderSide(color: AppThm.priClr.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _compartir(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => InsShareWdg(
        insignia: insignia,
        nombreUsuario: user.nombreCompleto,
      ),
    );
  }
}

class _InsData {
  final List<InsMdl> insignias;
  final InsProgresoMdl progreso;

  const _InsData({
    required this.insignias,
    required this.progreso,
  });
}
