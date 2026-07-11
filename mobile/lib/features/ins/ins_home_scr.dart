import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../adm/adm_design_tokens.dart';
import '../dash/wdg/top_bar_wdg.dart';
import 'ins_achievement_theme.dart';
import 'ins_api.dart';
import 'ins_mdl.dart';
import 'ins_share_wdg.dart';
import 'ins_widgets.dart';

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
  late Future<_InsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdmTokens.background,
      appBar: TopBarWdg(
        ttl: 'Mis insignias',
        user: widget.user,
        onUserChanged: widget.onUserChanged,
        onLogout: widget.onLogout,
        onNotifications: widget.onNotifications,
      ),
      body: SafeArea(
        child: FutureBuilder<_InsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AdmTokens.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AdmTokens.grey300),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudieron cargar las insignias',
                        style: TextStyle(fontSize: 16, color: AdmTokens.grey600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(fontSize: 13, color: AdmTokens.grey400),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _future = _load()),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final unlocked = data.allBadges.where((b) => b.desbloqueada).toList();
            final locked = data.allBadges.where((b) => !b.desbloqueada).toList();
            final inProgress = data.allBadges
                .where((b) => !b.desbloqueada && b.metaCartillas <= data.progreso.totalCartillasGeneradas)
                .toList();

            final highestUnlocked = unlocked.isEmpty
                ? (data.allBadges.isNotEmpty ? data.allBadges.first : null)
                : unlocked.last;
            final nivelActual = highestUnlocked != null
                ? AchievementTheme.forCartillas(highestUnlocked.metaCartillas).nombre
                : 'Novato';

            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              color: AdmTokens.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                children: [
                  const SizedBox(height: 20),
                  _Header(),
                  const SizedBox(height: 20),
                  AchievementsTimeline(
                    allBadges: data.allBadges,
                    progreso: data.progreso,
                  ),
                  const SizedBox(height: 16),
                  ProgressSummaryCards(
                    desbloqueadas: unlocked.length,
                    pendientes: locked.length - inProgress.length,
                    cartillasRestantes: data.progreso.cartillasFaltantes,
                    nivelActual: nivelActual,
                  ),
                  const SizedBox(height: 16),
                  AchievementProgressCard(
                    progreso: data.progreso,
                    nombreUsuario: widget.user.nombreCompleto,
                    nombreNivel: nivelActual,
                    onShare: () => _shareProgreso(context, data),
                  ),
                  const SizedBox(height: 20),
                  _DashboardSection(
                    allBadges: data.allBadges,
                    progreso: data.progreso,
                    nombreUsuario: widget.user.nombreCompleto,
                  ),
                  const SizedBox(height: 20),
                  AchievementTabs(
                    allBadges: data.allBadges,
                    totalCartillas: data.progreso.totalCartillasGeneradas,
                    nombreUsuario: widget.user.nombreCompleto,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _shareProgreso(BuildContext context, _InsData data) {
    final badge = data.allBadges.isNotEmpty
        ? data.allBadges.lastWhere(
            (b) => !b.desbloqueada,
            orElse: () => data.allBadges.last,
          )
        : null;
    if (badge == null) return;
    showDialog(
      context: context,
      builder: (_) => InsShareWdg(
        insignia: badge,
        nombreUsuario: widget.user.nombreCompleto,
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

    return _InsData(allBadges: merged, progreso: progreso);
  }
}

// ──────────────────────────────────────────────
// HEADER
// ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AdmTokens.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis insignias', style: AdmTokens.h1),
                SizedBox(height: 2),
                Text(
                  'Progresa generando cartillas y desbloquea nuevas insignias.',
                  style: TextStyle(fontSize: 14, color: AdmTokens.grey500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// DASHBOARD SECTION
// ──────────────────────────────────────────────

class _DashboardSection extends StatelessWidget {
  final List<InsMdl> allBadges;
  final InsProgresoMdl progreso;
  final String nombreUsuario;

  const _DashboardSection({
    required this.allBadges,
    required this.progreso,
    required this.nombreUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = UserRankBuilder.fromCurrentUser(
      nombre: nombreUsuario,
      allBadges: allBadges,
      totalCartillas: progreso.totalCartillasGeneradas,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TopUsersLeaderboard(users: [currentUser]),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: TopUsersCards(users: [currentUser]),
              ),
            ],
          );
        }
        return Column(
          children: [
            TopUsersLeaderboard(users: [currentUser]),
            const SizedBox(height: 14),
            TopUsersCards(users: [currentUser]),
          ],
        );
      },
    );
  }
}

class _InsData {
  final List<InsMdl> allBadges;
  final InsProgresoMdl progreso;

  const _InsData({
    required this.allBadges,
    required this.progreso,
  });
}
